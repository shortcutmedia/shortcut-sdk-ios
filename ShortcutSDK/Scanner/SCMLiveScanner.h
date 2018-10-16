//
//  SCMLiveScanner.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMLiveScannerDelegate.h"

typedef enum {
    kSCMLiveScannerLiveScanningMode = 0,
    kSCMLiveScannerSingleShotMode
} SCMLiveScannerMode;

@class SCMCaptureSessionController;

@interface SCMLiveScanner : NSObject

@property (nonatomic, unsafe_unretained, readwrite) id <SCMLiveScannerDelegate> delegate;
@property (nonatomic, strong, readwrite) AVCaptureDevice *captureDevice;
@property (nonatomic, assign, readwrite) NSTimeInterval noMotionThreshold;
@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, assign, readwrite) BOOL scanQRCodes;
@property (nonatomic, assign, readonly) SCMLiveScannerMode liveScannerMode;
@property (nonatomic, assign, readonly) BOOL scanning;
@property (nonatomic, assign, readonly) BOOL currentImageIsUnrecognized;
@property (nonatomic, strong, readonly) NSError *recognitionError;
@property (nonatomic, assign, readwrite) BOOL paused;
@property (nonatomic, strong, readwrite) UIImage *originalImage;

- (void)setupForMode:(SCMLiveScannerMode)initialMode;

- (void)startScanning;

- (void)switchToMode:(SCMLiveScannerMode)mode;

- (void)stopScanning;

- (void)takePictureWithZoomFactor:(CGFloat)zoomFactor;

- (void)processImage:(UIImage *)image;

- (void)processImageRef:(CGImageRef)imageRef;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)cancelAllOperations;

@end

extern NSString *kSCMLiveScannerErrorDomain;

typedef enum {
    kSCMLiveScannerErrorServerResponseTooSlow = -1,
    kSCMLiveScannerErrorInternationalRoamingOff = -2
} SCMLiveScannerErrorCode;

