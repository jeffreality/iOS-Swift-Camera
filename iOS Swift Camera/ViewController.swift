//
//  ViewController.swift
//  msrmedia
//
//  Created by Jeffrey Berthiaume on 9/11/15.
//  Copyright © 2015 Amherst, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    var thumbnails:[String?]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        thumbnails = self.pathsForAllImages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func takePhoto () {
        self.performSegueWithIdentifier("segueCapturePhoto", sender: nil)
    }
    
    
    @IBAction func recordVideo (sender: UIButton) {
        self.performSegueWithIdentifier("segueRecordVideo", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueCapturePhoto" {
            let vc = segue.destinationViewController as! CapturePhotoViewController
            vc.delegate = self
        }
    }
    
    func pathsForAllImages () -> [String?]? {
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        var array:[String?]? = nil
        
        let properties = [NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey]
        
        do {
            let directoryUrls = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: properties, options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            array = directoryUrls.map(){ $0.lastPathComponent }.filter(){ ($0! as NSString).pathExtension == "png" }
            if array?.count == 0 {
                array = nil
            }
        }
        catch let error as NSError {
            print(error.description)
        }
        return array
        
    }

}

extension ViewController: CapturePhotoDelegate {
    
    func didTakePhoto(img: UIImage) {
        self.dismissViewControllerAnimated(true, completion: { })
        
        let destinationPath = documentsURL.URLByAppendingPathComponent(NSUUID().UUIDString + ".png").path!
        UIImageJPEGRepresentation(img, 1.0)!.writeToFile(destinationPath, atomically: true)
        
    }
    
}

extension ViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let images = self.pathsForAllImages() {
            return images.count
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CellThumbnail", forIndexPath: indexPath) as! ThumbnailCell
        // Configure the cell
        if let files = thumbnails {
            cell.thumbnail.image = UIImage(contentsOfFile: documentsURL.URLByAppendingPathComponent(files[indexPath.row]!).path!)
        }
        
        return cell
    }
    
}