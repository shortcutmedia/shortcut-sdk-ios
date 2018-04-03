//
//  SCMCaptureSessionController.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMCaptureSessionController.h"

@interface SCMCaptureSessionController () <AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong, readwrite) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic, strong, readwrite) AVCaptureDevice *captureDevice;
@property (nonatomic, strong, readwrite) AVCaptureSession *captureSession;
@property (nonatomic, strong, readwrite) AVCaptureDeviceInput *captureInput;
@property (nonatomic, strong, readwrite) AVCaptureVideoDataOutput *videoCaptureOutput;
@property (nonatomic, strong, readwrite) AVCapturePhotoOutput *capturePhotoOutput;
@property (nonatomic, strong, readwrite) NSData *capturePhotoData;
@property (nonatomic, assign, readwrite) AVCaptureFlashMode flashMode;
@property (nonatomic, strong, readwrite) AVCaptureVideoPreviewLayer *previewLayer;
@property (atomic, assign, readwrite) BOOL running;

@property (nonatomic, strong) void (^photoCaptureCompletionHandler)(NSData *_Nullable data, NSError *_Nullable error);

@end

@implementation SCMCaptureSessionController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera]
                                                                                                  mediaType:AVMediaTypeVideo
                                                                                                   position:AVCaptureDevicePositionUnspecified];
    }
    return self;
}

- (void)dealloc
{
    [self stopSession];
}

- (SCMCaptureSessionMode)captureSessionMode
{
    if (self.videoCaptureOutput && !self.capturePhotoOutput) {
        return kSCMCaptureSessionLiveScanningMode;
    } else if (self.capturePhotoOutput && !self.videoCaptureOutput) {
        return kSCMCaptureSessionSingleShotMode;
    } else {
        return kSCMCaptureSessionTrackMode;
    }
}

- (Float64)minimumLiveScanningFrameRate
{
    // Note: This needs to stay at 15fps. Otherwise, the display looks really slow. iOS will automatically throttle our
    //       frame rate if we take longer than 1/15s to process an image.
    return 15.0f;
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
    
//    if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]) {
    sessionPreset = AVCaptureSessionPresetHigh;
//    } else {
//        sessionPreset = AVCaptureSessionPresetHigh;
//    }
    
    return sessionPreset;
}


#pragma mark - Camera Configuration

- (BOOL)hasCameraWithCapturePosition:(AVCaptureDevicePosition)capturePosition
{
    BOOL returnValue = false;

    for(AVCaptureDevice *device in self.videoDeviceDiscoverySession.devices) {
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
        for(AVCaptureDevice *device in self.videoDeviceDiscoverySession.devices) {
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
    if(self.captureDevice != nil && self.captureSessionMode == kSCMCaptureSessionSingleShotMode && [self hasCameraWithCapturePosition:AVCaptureDevicePositionFront])
    {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.captureInput];
        [self.captureSession removeOutput:self.capturePhotoOutput];
        
        //add the new input
        if ([self isCurrentCapturePositionBack] == YES) {
            [self configureCamera:AVCaptureDevicePositionFront];
        } else {
            [self configureCamera:AVCaptureDevicePositionBack];
        }

        NSError *error;
        self.captureSession.sessionPreset = [self findCaptureSessionPreset];
        self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
        self.capturePhotoOutput = [AVCapturePhotoOutput new];
        self.capturePhotoOutput.highResolutionCaptureEnabled = YES;
 
        if ([self.captureSession canAddInput:self.captureInput] && [self.captureSession canAddOutput:self.capturePhotoOutput]){
            [self.captureSession addInput:self.captureInput];
            [self.captureSession addOutput:self.capturePhotoOutput];
        } else {
            [self.captureSession commitConfiguration];
            return;
        }

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

    switch (initialMode) {
        case kSCMCaptureSessionLiveScanningMode:
            [self switchToLiveScanningMode];
            break;
        case kSCMCaptureSessionSingleShotMode:
            [self switchToSingleShotMode];
            break;
        case kSCMCaptureSessionTrackMode:
            [self switchToTrackMode];
            break;
        default:
            break;
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
    
    switch (mode) {
        case kSCMCaptureSessionLiveScanningMode:
            [self switchToLiveScanningMode];
            break;
        case kSCMCaptureSessionSingleShotMode:
            [self switchToSingleShotMode];
            break;
        case kSCMCaptureSessionTrackMode:
            [self switchToTrackMode];
            break;
        default:
            break;
    }
}

- (void)disableVideoOutput {
    if (self.videoCaptureOutput != nil) {
        [self.captureSession removeOutput:self.videoCaptureOutput];
        self.videoCaptureOutput = nil;
    }
}

- (BOOL)enableVideoOutput {
    self.videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    self.videoCaptureOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: [self.videoCaptureOutput availableVideoCVPixelFormatTypes].firstObject};

    [self.captureSession addOutput:self.videoCaptureOutput];
    
    Float64 minFrameRate = ((AVFrameRateRange*) (_captureDevice.activeFormat.videoSupportedFrameRateRanges)[0]).minFrameRate;
    if (minFrameRate <= self.minimumLiveScanningFrameRate) {
        _captureDevice.activeVideoMinFrameDuration = CMTimeMake(10, self.minimumLiveScanningFrameRate * 10);
    }
    [self setupSampleBufferDelegation];
    
    if ([self.captureSession canAddOutput:self.videoCaptureOutput]) {
        [self.captureSession addOutput:self.videoCaptureOutput];
        return true;
    } else {
        return false;
    }
}

- (void)disablePhotoOutput {
    if (self.capturePhotoOutput != nil) {
        [self.captureSession removeOutput:self.capturePhotoOutput];
        self.capturePhotoOutput = nil;
    }
}

- (BOOL)enablePhotoOutput {
    self.capturePhotoOutput = [AVCapturePhotoOutput new];
    self.capturePhotoOutput.highResolutionCaptureEnabled = YES;
    if ([self.captureSession canAddOutput:self.capturePhotoOutput]){
        [self.captureSession addOutput:self.capturePhotoOutput];
        return true;
    } else {
        return false;
    }
}

- (void)setupSampleBufferDelegation {
    if (self.sampleBufferDelegate != nil) {
        dispatch_queue_t frameQueue = dispatch_queue_create("VideoFrameQueue", NULL);
        [self.videoCaptureOutput setSampleBufferDelegate:self.sampleBufferDelegate queue:frameQueue];
    } else {
        // There's no point continuing because no one will be watching for the images!
        NSAssert(self.sampleBufferDelegate != nil, @"Switching to scanning mode with no sampleBufferDelegate!");
    }
}

- (void)switchToSingleShotMode
{
    [self.captureSession beginConfiguration];
    
    [self disableVideoOutput];
    if (![self enablePhotoOutput]) {
        [self.captureSession commitConfiguration];
        return;
    }

    [self.captureSession commitConfiguration];
}

- (void)switchToLiveScanningMode
{
    [self.captureSession beginConfiguration];
    
    [self disablePhotoOutput];
    if (![self enableVideoOutput]) {
        [self.captureSession commitConfiguration];
        return;
    }
    
    [self.captureSession commitConfiguration];
}

- (void)switchToTrackMode
{
    [self.captureSession beginConfiguration];
    
    [self disablePhotoOutput];
    [self disableVideoOutput];
    if (![self enablePhotoOutput]) {
        [self.captureSession commitConfiguration];
        return;
    }
    if (![self enableVideoOutput]) {
        [self.captureSession commitConfiguration];
        return;
    }
    
    [self.captureSession commitConfiguration];
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

- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^)(NSData *_Nullable data, NSError *_Nullable error))handler
{
    AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewLayer.connection.videoOrientation;
    
    AVCaptureConnection *photoOutputConnection = [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo];
    photoOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
    
    self.photoCaptureCompletionHandler = handler;
    [self.capturePhotoOutput capturePhotoWithSettings:[self currentPhotoSettings] delegate:self];
}

- (AVCapturePhotoSettings *)currentPhotoSettings {
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];

    if (self.captureDevice.isFlashAvailable) {
        photoSettings.flashMode = self.flashMode;
    }
    photoSettings.highResolutionPhotoEnabled = YES;
    if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
        photoSettings.previewPhotoFormat = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject};
    }
    
    return photoSettings;
}

- (BOOL)flashOn
{
    BOOL on = NO;
    
    if ([self hasFlash]) {
        on = (self.flashMode == AVCaptureFlashModeOn);
    }
    
    return on;
}

- (BOOL)hasFlash
{
    BOOL hasFlash = NO;

    hasFlash = self.captureDevice.hasFlash && [self.capturePhotoOutput.supportedFlashModes containsObject:@(AVCaptureFlashModeOn)];
    
    return hasFlash;
}

- (void)turnFlashOn
{
    if (!self.hasFlash) {
        return;
    }
    
    if (self.flashMode != AVCaptureFlashModeOn) {
        self.flashMode = AVCaptureFlashModeOn;
    }
}

- (void)turnFlashOff
{
    if (!self.hasFlash) {
        return;
    }
    
    if (self.flashMode != AVCaptureFlashModeOff) {
        self.flashMode = AVCaptureFlashModeOff;
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
    
    hasTorch = self.captureDevice.hasTorch && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOn];
    
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

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error
{
    if (error != nil) {
        self.photoCaptureCompletionHandler(nil, error);
        return;
    }
    
    self.capturePhotoData = [photo fileDataRepresentation];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
    if (error != nil) {
        self.photoCaptureCompletionHandler(nil, error);
        return;
    }
    
    if (self.capturePhotoData == nil) {
        self.photoCaptureCompletionHandler(nil, error);
        return;
    } else {
        self.photoCaptureCompletionHandler(self.capturePhotoData, nil);
    }
}

@end
