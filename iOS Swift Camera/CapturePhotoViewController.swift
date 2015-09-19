//
//  CapturePhotoViewController.swift
//  msrmedia
//
//  Created by Jeffrey Berthiaume on 9/11/15.
//  Copyright © 2015 Amherst, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CapturePhotoViewController: UIViewController {

    var captureDevice : AVCaptureDevice?
    let captureSession = AVCaptureSession()
    var stillImageOutput: AVCaptureStillImageOutput?
    var streamLayer : AVCaptureVideoPreviewLayer?
    
    var scale:CGFloat = 0.0
    
    var delegate:CapturePhotoDelegate! = nil
    
    @IBOutlet weak var streamView: UIView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var previewImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        //captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        print("Capture device found")
                    }
                }
            }
        }

        if (captureDevice != nil) {
            
            beginSession()
            
            if !(captureDevice!.hasTorch) {
                flashButton.hidden = true
            } else {
                flashButton.selected = false
            }
            
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        streamLayer?.frame = (streamView?.bounds)!
    }
    
    func beginSession() {
        
        let err : NSError? = nil
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch {
            // nil
        }
        
        if err != nil {
            print("error: \(err?.localizedDescription)")
        }
        
        streamLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        streamView?.layer.addSublayer(streamLayer!)
        streamLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        
        captureSession.addOutput(stillImageOutput)
        
        captureSession.startRunning()
    }
    
    func toggleFlash(on : Bool) {
        if captureDevice!.hasTorch {
            do {
                try captureDevice!.lockForConfiguration()
                if on == false {
                    captureDevice!.torchMode = AVCaptureTorchMode.Off
                } else {
                    try captureDevice!.setTorchModeOnWithLevel(1.0)
                }
                captureDevice!.unlockForConfiguration()
            } catch {
                print ("error with camera flash")
            }
        }
    }
    
    @IBAction func toggleFlashButton (btn : UIButton) {
        btn.selected = !btn.selected
    }

    @IBAction func pinchGestureRecognized(gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            scale = gestureRecognizer.scale
        }
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began ||
            gestureRecognizer.state == UIGestureRecognizerState.Changed {
                
                let currentScale = streamLayer?.valueForKeyPath("transform.scale")?.floatValue.CGFloatValue
                var newScale = 1 - (scale - gestureRecognizer.scale);
                newScale = min(newScale, 2.0 / currentScale!)
                newScale = max(newScale, 1.0 / currentScale!)
                
                let transform = CGAffineTransformScale ((streamLayer?.affineTransform())!, newScale, newScale)
                streamLayer?.setAffineTransform(transform)
                
                scale = gestureRecognizer.scale
                
        }
        
    }
    
    func cropToZoom (img : UIImage) -> UIImage {
        let currentScale = streamLayer?.valueForKeyPath("transform.scale")?.floatValue.CGFloatValue
        if currentScale == 1.0 {
            return img
        }
        
        let newW = img.size.width / currentScale!
        let newH = img.size.height / currentScale!
        let newX1 = (img.size.width / 2) - (newW / 2)
        let newY1 = (img.size.height / 2) - (newH / 2)
        
        let rect = CGRectMake( -newX1, -newY1, img.size.width, img.size.height)
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newW, newH), true, 1.0)
        img.drawInRect(rect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    func takePhoto () {
        
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true,CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.previewImage.image = self.cropToZoom(image)
                    
                    self.delegate!.didTakePhoto(self.cropToZoom(image))
                    
                    self.scale = 0.0
                    self.streamLayer?.setAffineTransform(CGAffineTransformIdentity)
                    
                    self.toggleFlash(false)
                    
                }
            })
        }
        
    }

    @IBAction func capturePhoto (sender: UIButton) {
        
        if (captureDevice != nil) {
            self.toggleFlash(flashButton.selected)
            
            let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.takePhoto()
                self.dismissViewControllerAnimated(true, completion: { })
            })
        } else {
            self.delegate!.didTakePhoto(UIImage(named: "LargeIcon")!)
            
            self.dismissViewControllerAnimated(true, completion: { })
        }
        
    }
    
}

protocol CapturePhotoDelegate {
    func didTakePhoto (img : UIImage)
}

extension Float {
    var CGFloatValue: CGFloat {
        get {
            return CGFloat(self)
        }
    }
}
