# iOS Swift Camera
Photo and Video capture and display using Swift 2.0 (for iOS)

## Overview
This is the Swift version of code that I have used in multiple projects, for camera or video recording and playback

## Display

### Home Screen

![iPhone showing home screen](README-images/home-screen.png?raw=true)

The main screen has a collectionView which shows all images or video thumbnails that have been recorded.  They are saved locally to the Documents folder.

### Camera

![iPhone showing camera screen (from Simulator) with flash enabled](README-images/camera-flash.png?raw=true)
![iPhone showing camera screen (from Simulator) with flash disabled](README-images/camera-no-flash.png?raw=true)

When taking a photo, the flash can be toggled on/off (the button is not displayed on the iPad).

Pinching will zoom the image to 2x.

### Video

![iPhone showing video recording screen (from Simulator) with full 15 seconds](README-images/record.png?raw=true)
![iPhone showing video recording screen (from Simulator) with 8 seconds remaining](README-images/record-timer.png?raw=true)

When recording video, there is a 15 second (configurable in code) limit.