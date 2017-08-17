//
//  SCMCaptureSessionController.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef enum
{
    kSCMCaptureSessionUnsetMode = -1,
    kSCMCaptureSessionLiveScanningMode = 0,
    kSCMCaptureSessionSingleShotMode
} SCMCaptureSessionMode;

@interface SCMCaptureSessionController : NSObject

@property (nonatomic, unsafe_unretained, readwrite) id<AVCaptureVideoDataOutputSampleBufferDelegate> sampleBufferDelegate;
@property (nonatomic, strong, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign, readonly) SCMCaptureSessionMode captureSessionMode;
@property (nonatomic, assign, readonly) BOOL flashOn;
@property (nonatomic, assign, readonly) BOOL torchOn;
@property (nonatomic, assign, readonly) CMTime minimumLiveScanningFrameDuration;

+ (BOOL)authorizedForVideoCapture;

- (void)setupCaptureSessionForMode:(SCMCaptureSessionMode)initialMode;
- (void)startSession;
- (void)switchToMode:(SCMCaptureSessionMode)mode;
- (void)stopSession;
- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^)(CMSampleBufferRef imageDataSampleBuffer, NSError *error))handler;
- (BOOL)hasTorch;
- (void)toggleTorchMode;
- (BOOL)hasFlash;
- (void)toggleFlashMode;
- (void)focusInPoint:(CGPoint)focusPoint;
- (void)toggleBackFrontCamera;
- (BOOL)hasCameraWithCapturePosition:(AVCaptureDevicePosition)capturePosition;

@end
