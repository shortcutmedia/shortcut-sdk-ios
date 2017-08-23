//
//  SCMCaptureSessionController.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMCaptureSessionController.h"

@interface SCMCaptureSessionController ()

@property (nonatomic, strong, readwrite) AVCaptureDevice *captureDevice;
@property (nonatomic, strong, readwrite) AVCaptureSession *captureSession;
@property (nonatomic, strong, readwrite) AVCaptureInput *captureInput;
@property (nonatomic, strong, readwrite) AVCaptureVideoDataOutput *videoCaptureOutput;
@property (nonatomic, strong, readwrite) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong, readwrite) AVCaptureConnection *stillImageVideoConnection;
@property (nonatomic, strong, readwrite) AVCaptureConnection *liveVideoConnection;
@property (nonatomic, strong, readwrite) AVCaptureVideoPreviewLayer *previewLayer;
@property (atomic, assign, readwrite) BOOL running;

@end

@implementation SCMCaptureSessionController

- (void)dealloc
{
    [self stopSession];
}

- (SCMCaptureSessionMode)captureSessionMode
{
    if (self.videoCaptureOutput && !self.stillImageOutput) {
        return kSCMCaptureSessionLiveScanningMode;
    } else if (self.stillImageOutput && !self.videoCaptureOutput) {
        return kSCMCaptureSessionSingleShotMode;
    } else {
        NSAssert1(self.stillImageOutput == nil && self.videoCaptureOutput == nil,
                  @"%@ cannot have a still image and live video output at the same time", self);
        return kSCMCaptureSessionUnsetMode;
    }
}

- (CMTime)minimumLiveScanningFrameDuration
{
    // Note: This needs to stay at 15fps. Otherwise, the display looks really slow. iOS will automatically throttle our
    //       frame rate if we take longer than 1/15s to process an image.
    return CMTimeMake(1, 15);
}

+ (BOOL)authorizedForVideoCapture
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        return (status != AVAuthorizationStatusDenied && status != AVAuthorizationStatusRestricted);
    } else {
        return YES;
    }
}

- (NSString *)findCaptureSessionPreset
{
    // use current/system-default session preset as default...
    NSString *sessionPreset; //= self.captureSession.sessionPreset;
    
    if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
        sessionPreset = AVCaptureSessionPreset1920x1080;
    } else {
        sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    return sessionPreset;
}


#pragma mark - Camera Configuration

- (BOOL)hasCameraWithCapturePosition:(AVCaptureDevicePosition)capturePosition
{
    BOOL returnValue = false;
    
    NSArray *devices = [AVCaptureDevice devices];
    for(AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo] == YES) {
            if (device.position == capturePosition) {
                returnValue = true;
            }
        }
    }
    return returnValue;
}

- (BOOL)isCurrentCapturePositionBack
{
    if (self.captureDevice.position == AVCaptureDevicePositionBack) {
        return true;
    }
    return false;
}

- (void)configureCamera:(AVCaptureDevicePosition)capturePosition
{
    if (capturePosition == AVCaptureDevicePositionUnspecified) {
        self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    } else {
        NSArray *devices = [AVCaptureDevice devices];
        for(AVCaptureDevice *device in devices) {
            if ([device hasMediaType:AVMediaTypeVideo] == YES) {
                if (device.position == capturePosition) {
                    self.captureDevice = device;
                    [self configureDevice];
                    return;
                }
            }
        }
    }
}

- (void)changeZoomToScale:(CGFloat)scale {
    NSError *error = nil;
    if ([self.captureDevice lockForConfiguration:&error]) {
        CGFloat desiredZoomFactor = scale;
        // Check if desiredZoomFactor fits required range from 1.0 to activeFormat.videoMaxZoomFactor
        self.captureDevice.videoZoomFactor = MAX(1.0, MIN(desiredZoomFactor, 10.0));
        [self.captureDevice unlockForConfiguration];
    } else {
        NSLog(@"error: %@", error);
    }
}

- (CGFloat)zoomFactor
{
    return self.captureDevice.videoZoomFactor;
}

- (void)configureDevice
{
    NSError *error;
    @try {
        [self.captureDevice lockForConfiguration:&error];
        if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] == YES) {
            self.captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        [self.captureDevice unlockForConfiguration];
    } @catch (NSException *exception) {
        DebugLog(@"Auto Focus in point caught exception");
        // Nothing to be done
    } @finally {
        // Nothing to be done
    }
}

- (void)toggleBackFrontCamera {
    if(self.captureDevice != nil && [self captureSessionMode] == kSCMCaptureSessionSingleShotMode && [self hasCameraWithCapturePosition:AVCaptureDevicePositionFront])
    {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.captureInput];
        [self.captureSession removeOutput:self.stillImageOutput];
        
        //add the new input
        if ([self isCurrentCapturePositionBack] == YES) {
            [self configureCamera:AVCaptureDevicePositionFront];
        } else {
            [self configureCamera:AVCaptureDevicePositionBack];
        }

        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.stillImageOutput setOutputSettings:outputSettings];

        NSError *error;
        self.captureSession.sessionPreset = [self findCaptureSessionPreset];
        self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
 
        
        if ([self.captureSession canAddInput:self.captureInput] && [self.captureSession canAddOutput:self.stillImageOutput]){
            [self.captureSession addInput:self.captureInput];
            [self.captureSession addOutput:self.stillImageOutput];
        } else {
            return;
        }
        
        [self configureConnection];

        //end the configuration
        [self.captureSession commitConfiguration];
    }
}


#pragma mark - Camera Session

- (void)setupCaptureSessionForMode:(SCMCaptureSessionMode)initialMode
{
    if (self.captureSession != nil) {
        return;
    }
    
    [self configureCamera:AVCaptureDevicePositionUnspecified];
    
    NSError *error = nil;
    self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    if (error == nil) {
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = [self findCaptureSessionPreset];
        [self.captureSession addInput:self.captureInput];
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    }
    
    if (initialMode == kSCMCaptureSessionLiveScanningMode) {
        [self switchToLiveScanningMode];
    } else {
        [self switchToSingleShotMode];
    }
}

- (void)startSession
{
    if (self.running == NO) {
        self.running = YES;
        [self.captureSession startRunning];
    } else {
        NSAssert1(NO, @"%@ already running when caling start session!", self);
    }
}

- (void)switchToMode:(SCMCaptureSessionMode)mode
{
    if (self.captureSessionMode == mode) {
        return;
    }
    
    [self turnFlashOff];
    [self turnTorchOff];
    
    if (mode == kSCMCaptureSessionLiveScanningMode) {
        [self switchToLiveScanningMode];
    } else {
        [self switchToSingleShotMode];
    }
}

- (void)configureConnection {
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([port.mediaType isEqualToString:AVMediaTypeVideo]) {
                self.stillImageVideoConnection = connection;
                break;
            }
        }
        
        if (self.stillImageVideoConnection != nil) {
            break;
        }
    }
}

- (void)switchToSingleShotMode
{
    [self.captureSession beginConfiguration];
    
    if (self.videoCaptureOutput != nil) {
        [self.captureSession removeOutput:self.videoCaptureOutput];
        self.videoCaptureOutput = nil;
        self.liveVideoConnection = nil;
    }
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    [self.captureSession addOutput:self.stillImageOutput];
    [self configureConnection];
    [self.captureSession commitConfiguration];
}

- (void)switchToLiveScanningMode
{
    [self.captureSession beginConfiguration];
    
    if (self.stillImageOutput != nil) {
        [self.captureSession removeOutput:self.stillImageOutput];
        self.stillImageOutput = nil;
        self.stillImageVideoConnection = nil;
    }
    
    self.videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    self.videoCaptureOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                             nil];
    
    [self.captureSession addOutput:self.videoCaptureOutput];
    
    for (AVCaptureConnection *connection in self.videoCaptureOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([port.mediaType isEqualToString:AVMediaTypeVideo]) {
                self.liveVideoConnection = connection;
                break;
            }
        }
    }
    
    if ([self.liveVideoConnection isVideoMinFrameDurationSupported]) {
        self.liveVideoConnection.videoMinFrameDuration = self.minimumLiveScanningFrameDuration;
    }
//    if ([_captureDevice.activeFormat.videoSupportedFrameRateRanges containsObject:self.minimumLiveScanningFrameDuration]) {
//        [_captureDevice setActiveVideoMinFrameDuration:self.minimumLiveScanningFrameDuration];
//    }
    
    if (self.sampleBufferDelegate != nil) {
        dispatch_queue_t frameQueue = dispatch_queue_create("VideoFrameQueue", NULL);
        [self.videoCaptureOutput setSampleBufferDelegate:self.sampleBufferDelegate queue:frameQueue];
    } else {
        // There's no point continuing because no one will be watching for the images!
        NSAssert(self.sampleBufferDelegate != nil, @"Switching to scanning mode with no sampleBufferDelegate!");
    }
    
    if ([self.captureSession canAddOutput:self.videoCaptureOutput]) {
        [self.captureSession addOutput:self.videoCaptureOutput];
    }
    
    [self.captureSession commitConfiguration];
    
    self.liveVideoConnection.enabled = YES;
}

- (void)stopSession
{
    if (self.running) {
        [self turnFlashOff];
        [self turnTorchOff];
        
        [self.captureSession stopRunning];
        self.running = NO;
    }
}

- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^)(CMSampleBufferRef imageDataSampleBuffer, NSError *error))handler
{
    switch (UIDevice.currentDevice.orientation)
    {
        case UIDeviceOrientationPortrait :
            self.stillImageVideoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown :
            self.stillImageVideoConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft :
            self.stillImageVideoConnection.videoOrientation =  AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight :
            self.stillImageVideoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default: break;
    }

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:self.stillImageVideoConnection completionHandler:handler];
}

- (BOOL)flashOn
{
    BOOL on = NO;
    
    if ([self hasFlash]) {
        on = (self.captureDevice.flashMode == AVCaptureFlashModeOn);
    }
    
    return on;
}

- (BOOL)hasFlash
{
    BOOL hasFlash = NO;
    
    hasFlash = [self.captureDevice hasFlash] && [self.captureDevice isFlashModeSupported:AVCaptureFlashModeOn];
    
    return hasFlash;
}

- (void)turnFlashOn
{
    if (!self.hasFlash) {
        return;
    }
    
    if (self.captureDevice.flashMode != AVCaptureFlashModeOn) {
        if ([self.captureDevice lockForConfiguration:NULL]) {
            self.captureDevice.flashMode = AVCaptureFlashModeOn;
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (void)turnFlashOff
{
    if (!self.hasFlash) {
        return;
    }
    
    if (self.captureDevice.flashMode != AVCaptureFlashModeOff) {
        if ([self.captureDevice lockForConfiguration:NULL]) {
            self.captureDevice.flashMode = AVCaptureFlashModeOff;
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (void)toggleFlashMode
{
    if (self.flashOn) {
        [self turnFlashOff];
    } else {
        [self turnFlashOn];
    }
}

- (BOOL)torchOn
{
    BOOL on = NO;
    
    if ([self hasTorch]) {
        on = (self.captureDevice.torchMode == AVCaptureTorchModeOn);
    }
    
    return on;
}

- (BOOL)hasTorch
{
    BOOL hasTorch = NO;
    
    hasTorch = [self.captureDevice hasTorch] && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOn];
    
    return hasTorch;
}

- (void)turnTorchOn
{
    if (!self.hasTorch) {
        return;
    }
    
    if (self.captureDevice.torchMode != AVCaptureTorchModeOn) {
        if ([self.captureDevice lockForConfiguration:NULL]) {
            self.captureDevice.torchMode = AVCaptureTorchModeOn;
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (void)turnTorchOff
{
    if (!self.hasTorch) {
        return;
    }
    
    if (self.captureDevice.torchMode != AVCaptureTorchModeOff) {
        if ([self.captureDevice lockForConfiguration:NULL]) {
            self.captureDevice.torchMode = AVCaptureTorchModeOff;
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (void)toggleTorchMode
{
    if (self.torchOn) {
        [self turnTorchOff];
    } else {
        [self turnTorchOn];
    }
}

- (void)focusInPoint:(CGPoint)focusPoint
{
    CGFloat x = focusPoint.x;
    CGFloat y = focusPoint.y;
    
    if (self.captureDevice.position == AVCaptureDevicePositionBack) {
        y = 1.0 - y;
    }
    
    CGPoint pointToFocus = CGPointMake(x, y);
    NSError *error;
    
    @try {
        [self.captureDevice lockForConfiguration:&error];
        if (self.captureDevice.exposurePointOfInterestSupported == YES) {
            self.captureDevice.exposurePointOfInterest = pointToFocus;
            self.captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        if (self.captureDevice.focusPointOfInterestSupported == YES) {
            self.captureDevice.focusPointOfInterest = pointToFocus;
            
            if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] == YES)
            {
                self.captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
            }
        } else if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] == YES)
        {
            self.captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        [self.captureDevice unlockForConfiguration];
    } @catch (NSException *exception) {
        DebugLog(@"Auto Focus in point caught exception");
        // Nothing to be done
    } @finally {
        // Nothing to be done
    }
    
}

@end
