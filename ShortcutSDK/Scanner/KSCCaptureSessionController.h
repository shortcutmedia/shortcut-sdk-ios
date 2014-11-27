//
//  KSCCaptureSessionController.h
//  Shortcut
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef enum
{
	kKSCCaptureSessionLiveScanningMode = 0,
	kKSCCaptureSessionSingleShotMode
} KSCCaptureSessionMode;

@interface KSCCaptureSessionController : NSObject

@property (nonatomic, unsafe_unretained, readwrite) id<AVCaptureVideoDataOutputSampleBufferDelegate> sampleBufferDelegate;
@property (nonatomic, strong, readonly) NSString* captureSessionPreset;
@property (nonatomic, strong, readonly) AVCaptureDevice* captureDevice;
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, assign, readonly) KSCCaptureSessionMode captureSessionMode;
@property (nonatomic, assign, readonly) BOOL flashOn;

+ (BOOL)authorizedForVideoCapture;

- (void)setupCaptureSessionForMode:(KSCCaptureSessionMode)initialMode;
- (void)startSession;
- (void)switchToMode:(KSCCaptureSessionMode)mode;
- (void)stopSession;
- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^)(CMSampleBufferRef imageDataSampleBuffer, NSError *error))handler;
- (BOOL)hasFlashForCurrentMode;
- (void)toggleFlashMode;

@end
