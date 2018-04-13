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
    kSCMCaptureSessionSingleShotMode,
    kSCMCaptureSessionTrackMode
} SCMCaptureSessionMode;

@interface SCMCaptureSessionController : NSObject

@property (nonatomic, unsafe_unretained, readwrite) id<AVCaptureVideoDataOutputSampleBufferDelegate> _Nullable sampleBufferDelegate;
@property (nonatomic, strong, readonly) AVCaptureDevice * _Nullable captureDevice;
@property (nonatomic, strong, readonly) AVCaptureSession * _Nullable captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * _Nullable previewLayer;
@property (nonatomic, assign, readonly) SCMCaptureSessionMode captureSessionMode;
@property (nonatomic, assign, readonly) BOOL flashOn;
@property (nonatomic, assign, readonly) BOOL torchOn;
@property (nonatomic, assign, readonly) Float64 minimumLiveScanningFrameRate;

@property (strong, nonatomic) void (^ _Nullable onSetupPhotoCapture)(void);

+ (BOOL)authorizedForVideoCapture;
- (instancetype _Nullable)initWithMode:(SCMCaptureSessionMode)mode
                  sampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate> _Nullable)sampleBufferDelegate;

- (void)startSession;
- (void)switchToMode:(SCMCaptureSessionMode)mode;
- (void)stopSession;
- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^_Nonnull)(NSData *_Nullable data, NSError *_Nullable error))handler;
- (BOOL)hasTorch;
- (void)toggleTorchMode;
- (BOOL)hasFlash;
- (void)toggleFlashMode;
- (void)focusInPoint:(CGPoint)focusPoint;
- (void)toggleBackFrontCamera;
- (BOOL)hasCameraWithCapturePosition:(AVCaptureDevicePosition)capturePosition;
- (void)changeZoomToScale:(CGFloat)scale;
- (CGFloat)zoomFactor;

@end
