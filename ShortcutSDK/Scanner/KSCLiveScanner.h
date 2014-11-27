//
//  KSCLiveScanner.h
//  Shortcut
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import "KSCLiveScannerDelegate.h"
#import "KSCBarcodeScannerDelegate.h"


typedef enum
{
	kKSCLiveScannerLiveScanningMode = 0,
	kKSCLiveScannerSingleShotMode
} KSCLiveScannerMode;

@class KSCCaptureSessionController;

@interface KSCLiveScanner : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, KSCBarcodeScannerDelegate>

@property (nonatomic, unsafe_unretained, readwrite) id<KSCLiveScannerDelegate> delegate;
@property (nonatomic, assign, readwrite) NSTimeInterval noMotionThreshold;
@property (nonatomic, strong, readonly) KSCCaptureSessionController* captureSessionController;
@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, assign, readwrite) BOOL scanQRCodes;
@property (nonatomic, assign, readonly) KSCLiveScannerMode liveScannerMode;
@property (nonatomic, assign, readonly) BOOL scanning;
@property (nonatomic, assign, readonly) BOOL currentImageIsUnrecognized;
@property (nonatomic, strong, readonly) NSError* recognitionError;
@property (nonatomic, assign, readwrite) BOOL paused;

- (void)setupForMode:(KSCLiveScannerMode)initialMode;
- (void)startScanning;
- (void)switchToMode:(KSCLiveScannerMode)mode;
- (void)stopScanning;
- (void)takePictureWithZoomFactor:(CGFloat)zoomFactor;
- (void)processImage:(CGImageRef)image;

@end

extern NSString* kKSCLiveScannerErrorDomain;

typedef enum
{
	kKSCLiveScannerErrorServerResponseTooSlow = -1
} KSCLiveScannerErrorCode;