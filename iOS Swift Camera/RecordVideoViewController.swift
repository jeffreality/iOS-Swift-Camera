//
//  RecordVideoViewController.swift
//  iOS Swift Camera
//
//  Created by Jeffrey Berthiaume on 9/18/15.
//  Copyright © 2015 Jeffrey Berthiaume. All rights reserved.
//

import UIKit
import AVFoundation

class RecordVideoViewController: UIViewController {
    
    var movieFileOutput:AVCaptureMovieFileOutput? = nil
    var isRecording = false
    var elapsedTime = 0.0
    var elapsedTimer:NSTimer? = nil
    
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var btnStartRecording: UIButton!
    @IBOutlet weak var elapsedTimeLabel: UILabel!

    var session: AVCaptureSession? = nil
    var previewLayer: AVCaptureVideoPreviewLayer? = nil
    
    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    
    let maxSecondsForVideo = 15.0
    let captureFramesPerSecond = 30.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if device != nil {
            self.setupRecording()
        }
    }
    
    func setupRecording () {
        if session != nil {
            session!.stopRunning()
            session = nil
        }
        
        btnStartRecording.setImage(UIImage(named: "ButtonRecord"), forState: UIControlState.Normal)
        
        isRecording = false
        self.setupCaptureSession()
        elapsedTime = -0.5
        self.updateElapsedTime()
        
    }
    
    func setupCaptureSession () {
        
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetMedium
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            session?.addInput(input)
            
        } catch {
            print ("video initialization error")
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { (granted: Bool) -> Void in
            if granted {
                let audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
                do {
                    let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
                    self.session?.addInput(audioInput)
                } catch {
                    print ("audio initialization error")
                }
            }
        }
        
        let queue = dispatch_queue_create("videoCaptureQueue", nil)
        
        let output = AVCaptureVideoDataOutput ()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as NSObject:kCVPixelFormatType_32BGRA as! AnyObject]
        output.setSampleBufferDelegate(self, queue: queue)
        session?.addOutput(output)
        
        previewLayer = AVCaptureVideoPreviewLayer (session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRectMake(0, 0, videoPreviewView.frame.size.width, videoPreviewView.frame.size.height)
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        let currentOrientation = UIDevice.currentDevice().orientation
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
        
        if currentOrientation == UIDeviceOrientation.LandscapeLeft {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        } else {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
        }
        
        videoPreviewView.layer.addSublayer(previewLayer!)
        
        movieFileOutput = AVCaptureMovieFileOutput()
        
        let maxDuration = CMTimeMakeWithSeconds(maxSecondsForVideo, Int32(captureFramesPerSecond))
        movieFileOutput?.maxRecordedDuration = maxDuration
        
        movieFileOutput?.minFreeDiskSpaceLimit = 1024 * 1024
        
        if (session?.canAddOutput(movieFileOutput) != nil) {
            session?.addOutput(movieFileOutput)
        }
        
        var videoConnection:AVCaptureConnection? = nil
        for connection in (movieFileOutput?.connections)! {
            for port in connection.inputPorts! {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }
        
        videoConnection?.videoOrientation = AVCaptureVideoOrientation (ui: currentOrientation)
        
        if (session?.canSetSessionPreset(AVCaptureSessionPreset640x480) != nil) {
            session?.sessionPreset = AVCaptureSessionPreset640x480
        }
        
        session?.startRunning()
        
    }
    
    func updateElapsedTime () {
        elapsedTime += 0.5
        let elapsedFromMax = maxSecondsForVideo - elapsedTime
        elapsedTimeLabel.text = "00:" + String(format: "%02d", Int(round(elapsedFromMax)))
        
        if elapsedTime >= maxSecondsForVideo {
            isRecording = true
            self.recordVideo(self.btnStartRecording)
        }
        
    }
    
    
    @IBAction func recordVideo (btn : UIButton) {
        
        if !isRecording {
            isRecording = true
            
            elapsedTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("updateElapsedTime"), userInfo: nil, repeats: true)
            
            btn.setImage(UIImage (named: "ButtonStop"), forState: UIControlState.Normal)
            
            let path = documentsURL.path! + NSUUID ().UUIDString + ".mp4"
            let outputURL = NSURL(fileURLWithPath: path)
            
            movieFileOutput?.startRecordingToOutputFileURL(outputURL, recordingDelegate: self)
            
        } else {
            isRecording = false
            
            elapsedTimer?.invalidate()
            movieFileOutput?.stopRecording()
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
        
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if fromInterfaceOrientation == UIInterfaceOrientation.LandscapeLeft {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        } else {
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
        }
        
    }

}

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIDeviceOrientation {
        get {
            switch self {
            case .LandscapeLeft:        return .LandscapeLeft
            case .LandscapeRight:       return .LandscapeRight
            case .Portrait:             return .Portrait
            case .PortraitUpsideDown:   return .PortraitUpsideDown
            }
        }
    }
    
    init(ui:UIDeviceOrientation) {
        switch ui {
        case .LandscapeRight:       self = .LandscapeRight
        case .LandscapeLeft:        self = .LandscapeLeft
        case .Portrait:             self = .Portrait
        case .PortraitUpsideDown:   self = .PortraitUpsideDown
        default:                    self = .Portrait
        }
    }
}

extension RecordVideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print ("Recorded Successfully")
    }

}
