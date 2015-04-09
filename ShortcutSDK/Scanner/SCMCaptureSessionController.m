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
@property (nonatomic, assign, readwrite) SCMCaptureSessionMode captureSessionMode;
@property (atomic, assign, readwrite) BOOL running;

@end

@implementation SCMCaptureSessionController

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.captureSessionMode = kSCMCaptureSessionLiveScanningMode;
    }
    
    return self;
}

- (void)dealloc
{
    [self stopSession];
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
    NSString *sessionPreset = self.captureSession.sessionPreset;
    
    if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]) {
        sessionPreset = AVCaptureSessionPreset1280x720;
    } else if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
        sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    return sessionPreset;
}

- (void)setupCaptureSessionForMode:(SCMCaptureSessionMode)initialMode
{
    if (self.captureSession != nil) {
        return;
    }
    
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
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
    
    if (mode == kSCMCaptureSessionLiveScanningMode) {
        [self switchToLiveScanningMode];
    } else {
        [self switchToSingleShotMode];
    }
}

- (void)switchToSingleShotMode
{
    self.captureSessionMode = kSCMCaptureSessionSingleShotMode;
    
    // Disable the torch since we don't use it in single shot mode.
    [self turnTorchOff];
    
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
    
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                self.stillImageVideoConnection = connection;
                break;
            }
        }
        
        if (self.stillImageVideoConnection != nil) {
            break;
        }
    }
    
    [self.captureSession commitConfiguration];
}

- (void)switchToLiveScanningMode
{
    self.captureSessionMode = kSCMCaptureSessionLiveScanningMode;
    
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
        // Turn the torch off if it was on. Better not to leave it in an on state.
        [self turnTorchOff];
        
        [self.captureSession stopRunning];
        self.running = NO;
    }
}

- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^)(CMSampleBufferRef imageDataSampleBuffer, NSError *error))handler
{
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:self.stillImageVideoConnection completionHandler:handler];
}

- (BOOL)flashOn
{
    BOOL on = NO;
    
    if ([self hasFlashForCurrentMode]) {
        if (self.captureSessionMode == kSCMCaptureSessionLiveScanningMode) {
            on = (self.captureDevice.torchMode == AVCaptureTorchModeOn);
        } else {
            on = (self.captureDevice.flashMode == AVCaptureFlashModeOn);
        }
    }
    
    return on;
}

- (BOOL)hasFlashForCurrentMode
{
    BOOL hasFlash = NO;
    
    if (self.captureSessionMode == kSCMCaptureSessionLiveScanningMode) {
        hasFlash = [self.captureDevice hasTorch] && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOn];
    } else {
        hasFlash = [self.captureDevice hasFlash] && [self.captureDevice isFlashModeSupported:AVCaptureFlashModeOn];
    }
    
    return hasFlash;
}

- (void)turnTorchOff
{
    if ([self.captureDevice hasTorch] && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOff] &&
        self.captureDevice.torchMode != AVCaptureTorchModeOff) {
        if ([self.captureDevice lockForConfiguration:NULL]) {
            self.captureDevice.torchMode = AVCaptureTorchModeOff;
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (void)toggleFlashMode
{
    if ([self hasFlashForCurrentMode]) {
        if (self.captureSessionMode == kSCMCaptureSessionLiveScanningMode) {
            if (self.captureDevice.torchMode == AVCaptureTorchModeOff) {
                if ([self.captureDevice lockForConfiguration:NULL]) {
                    self.captureDevice.torchMode = AVCaptureTorchModeOn;
                    [self.captureDevice unlockForConfiguration];
                }
            } else {
                if ([self.captureDevice lockForConfiguration:NULL]) {
                    self.captureDevice.torchMode = AVCaptureTorchModeOff;
                    [self.captureDevice unlockForConfiguration];
                }
            }
        } else {
            if (self.captureDevice.flashMode == AVCaptureFlashModeOff) {
                if ([self.captureDevice lockForConfiguration:NULL]) {
                    self.captureDevice.flashMode = AVCaptureFlashModeOn;
                    [self.captureDevice unlockForConfiguration];
                }
            } else {
                if ([self.captureDevice lockForConfiguration:NULL]) {
                    self.captureDevice.flashMode = AVCaptureFlashModeOff;
                    [self.captureDevice unlockForConfiguration];
                }
            }
        }
    }
}


@end
