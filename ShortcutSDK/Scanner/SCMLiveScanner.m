//
//  SCMLiveScanner.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMLiveScanner.h"
#import "SCMMotionDetector.h"
#import "SCMHistogramFilter.h"
#import "SCMCaptureSessionController.h"
#import "SCMRecognitionOperation.h"
#import "SCMQRCodeScanner.h"
#import "SCMQRCodeScannerDelegate.h"
#import "SCMImageUtils.h"
#import "SCMLocalization.h"


NSString *kSCMLiveScannerErrorDomain = @"SCMLiveScannerErrorDomain";

static const NSInteger kMaxOutstandingImageRecognitionOperations = 2;
static const NSTimeInterval kDefaultNoMotionThreshold = 0.1;
static const CGFloat kDefaultQueryImageSize = 640.0;
static const CGFloat kDefaultOutputCompressionLevel = 0.30;
static const CGFloat kMinimumRequestDelay = 1.0;

@interface SCMLiveScanner () <SCMQRCodeScannerDelegate>

@property (nonatomic, strong, readwrite) SCMMotionDetector *motionDetector;
@property (nonatomic, strong, readwrite) SCMHistogramFilter *histogramFilter;
@property (nonatomic, strong, readwrite) SCMQRCodeScanner *qrCodeScanner;
@property (nonatomic, strong, readwrite) NSOperationQueue *recognitionQueue;
@property (nonatomic, assign, readwrite) NSInteger numImagesSentForRecognition;
@property (   atomic, assign, readwrite) NSInteger outstandingRecognitionOperations;
@property (nonatomic, assign, readwrite) CGFloat queryImageSize;
@property (nonatomic, assign, readwrite) CGFloat outputCompressionLevel;
@property (nonatomic, assign, readwrite) SCMLiveScannerMode liveScannerMode;
@property (nonatomic, assign, readwrite) BOOL scanning;
@property (nonatomic, assign, readwrite) BOOL running;
@property (nonatomic, assign, readwrite) BOOL lastImageUnrecognized;
@property (nonatomic, assign, readwrite) BOOL currentImageIsUnrecognized;
@property (nonatomic, strong, readwrite) NSError *recognitionError;
@property (   atomic, assign, readwrite) BOOL imageRecognized;
@property (nonatomic, strong, readwrite) NSDate *lastRequestTimeStamp;

@end

@implementation SCMLiveScanner

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.noMotionThreshold = kDefaultNoMotionThreshold;

        self.motionDetector = [[SCMMotionDetector alloc] init];
        self.histogramFilter = [[SCMHistogramFilter alloc] init];
        self.qrCodeScanner = [[SCMQRCodeScanner alloc] init];
        self.qrCodeScanner.delegate = self;
        
        self.queryImageSize = kDefaultQueryImageSize;
        self.outputCompressionLevel = kDefaultOutputCompressionLevel;
        
        self.recognitionQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [self cancelAllOperations];
    self.originalImage = nil;
    self.motionDetector = nil;
    self.histogramFilter = nil;
    self.qrCodeScanner = nil;
}

#pragma mark - Public Methods

- (void)setupForMode:(SCMLiveScannerMode)initialMode
{
    self.histogramFilter.histogramThreshold = 45000.0;
    
    // Optimize the output size based on the capture device
    CMVideoDimensions deviceVideoDimensions = CMVideoFormatDescriptionGetDimensions(self.captureDevice.activeFormat.formatDescription);
    int deviceMaxSize = MAX(deviceVideoDimensions.width, deviceVideoDimensions.height);

//    if (deviceMaxSize >= 1280) {
//        self.queryImageSize = 1280;
//    } else
    if (deviceMaxSize >= 640) {
        self.queryImageSize = 640;
    } else {
        self.queryImageSize = 320;
    }

    [self switchToMode:initialMode];
}

- (void)switchToMode:(SCMLiveScannerMode)mode
{
    if (mode == kSCMLiveScannerLiveScanningMode) {
        self.liveScannerMode = kSCMLiveScannerLiveScanningMode;
        self.recognitionError = nil;
        self.numImagesSentForRecognition = 0;
        [self.motionDetector startDetectingMotion];
        [self.histogramFilter reset];
    } else {
        self.liveScannerMode = kSCMLiveScannerSingleShotMode;
        self.scanning = NO;
        [self cancelAllOperations];
        [self.motionDetector stopDetectingMotion];
    }
}

- (void)startScanning
{
    if (!self.running) {
        if (![SCMCaptureSessionController authorizedForVideoCapture]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[SCMLocalization translationFor:@"CameraAccessRequiredTitle" withDefaultValue:@"Camera access required"]
                                                                                     message:[SCMLocalization translationFor:@"CameraAccessRequiredBody" withDefaultValue:@"The app needs access to the camera to scan things.\nPlease allow usage of the camera by enabling it in the privacy settings."]
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:[SCMLocalization translationFor:@"OKButtonTitle" withDefaultValue:@"OK"]
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alertController addAction:okAction];
            UIViewController *displayingViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            [displayingViewController presentViewController:alertController
                                                   animated:YES
                                                 completion:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate liveScannerShouldClose:self];
            });
        }
        
        self.running = YES;
        self.imageRecognized = NO;
        self.numImagesSentForRecognition = 0;
        if (self.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
            [self.motionDetector startDetectingMotion];
        }
    }
}

- (void)stopScanning
{
    if (self.running) {
        self.running = NO;
        self.scanning = NO;
        [self cancelAllOperations];
        [self.motionDetector stopDetectingMotion];
    }
}

- (void)cancelAllOperations
{
    [self.recognitionQueue cancelAllOperations];
}

- (void)takePictureWithZoomFactor:(CGFloat)zoomFactor
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate liveScanner:self didRequestPictureTakeWithCompletionHandler:^(NSData *data, NSError *error) {
            if (data != nil) {
                self.originalImage = [[UIImage alloc] initWithData:data];
                [self processImageRef:self.originalImage.CGImage];
            } else {
                DebugLog(@"could not take picture because: %@", [error localizedDescription]);
            }
        }];
    });
}

- (void)setPaused:(BOOL)value
{
    _paused = value;
    
    if (value) {
        self.scanning = NO;
        [self cancelAllOperations];
    } else {
        self.imageRecognized = NO;
    }
}

#pragma mark - Handling images

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.running) {
        return;
    }
    
    BOOL similar = [self.histogramFilter isSampleBufferHistogramSimilar:sampleBuffer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (similar) {
            // The image was the same as the last one sent to the server.
            if (self.lastImageUnrecognized && !self.currentImageIsUnrecognized) {
                self.currentImageIsUnrecognized = YES;
                self.scanning = NO;
            }
        } else {
            self.lastImageUnrecognized = NO;
            if (self.currentImageIsUnrecognized) {
                self.currentImageIsUnrecognized = NO;
            }
            
            if (self.liveScannerMode == kSCMLiveScannerLiveScanningMode && !self.paused) {
                self.scanning = YES;
            } else {
                self.scanning = NO;
            }
        }
    });
    
    if (!similar && ![self shouldSkipImage] && [self shouldSendImageForRecognition]) {
        CGImageRef sampleBufferImage = [SCMImageUtils newImageFromSampleBuffer:sampleBuffer];
        [self processImageRef:sampleBufferImage];
        CGImageRelease(sampleBufferImage);
    }
}

- (void)processImage:(UIImage *)image {
    CGImageRef imageRef = [UIImage imageWithData:UIImagePNGRepresentation(image)].CGImage;
    [self processImageRef:imageRef];
}

- (void)processImageRef:(CGImageRef)imageRef {
    if (!self.running) {
        return;
    }
    
    NSData *scaledImageData = [SCMImageUtils scaledImageDataWithImage:imageRef
                                                          orientation:6
                                                              maxSize:self.queryImageSize
                                                          compression:self.outputCompressionLevel
                                                           zoomFactor:1.0];
    
    if (self.scanQRCodes && !self.imageRecognized) {
        CGImageRef scaledImage = [UIImage imageWithData:scaledImageData].CGImage;
        [self.qrCodeScanner decodeImage:scaledImage];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate liveScanner:self recognizingImage:scaledImageData];
    });
    
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(backgroundQueue, ^{
        [self sendImageDataForRecognition:scaledImageData];
    });
}

- (BOOL)shouldSkipImage
{
    if (self.paused) {
        // When paused, we don't do anything with the image. We just skip them until we are no longer paused.
        return YES;
    }
    
    if (self.numImagesSentForRecognition == 0) {
        // We always send the first image regardless of motion or focusing.
        return NO;
    }
    
    if (self.imageRecognized) {
        // No need to send an image if we have already recognized one
        return YES;
    }
    
    BOOL skipImage = NO;
    
    NSTimeInterval timeSinceLastMotion = [self.motionDetector timeIntervalSinceLastMotionDetected];
    if (timeSinceLastMotion < self.noMotionThreshold) {
        // The device hasn't been still long enough to use this image.
        skipImage = YES;
    } else if (self.captureDevice.adjustingFocus)
    {
        skipImage = YES;
    }

    if (self.lastRequestTimeStamp) {
        skipImage = ([[NSDate date] timeIntervalSinceDate:self.lastRequestTimeStamp] < kMinimumRequestDelay);
    }

    return skipImage;
}

- (BOOL)shouldSendImageForRecognition
{
    BOOL sendImageForRecognition = YES;
    
    if (self.outstandingRecognitionOperations >= kMaxOutstandingImageRecognitionOperations) {
        // We already have the maximum number of images waiting for recognition.
        // If we have already sent the first set of images (including the very first image), then skip this image.
        // This way, we send a few more images right away while the user is adjusting the framing and this
        // helps improved the overall response time.
        if (self.numImagesSentForRecognition > kMaxOutstandingImageRecognitionOperations) {
            sendImageForRecognition = NO;
        }
    }
    
    return sendImageForRecognition;
}

- (void)sendImageDataForRecognition:(NSData *)scaledImageData
{
    // We need to start this operation on a different thread since this thread may not stick around.
    // For now, we'll use the main thread.
    SCMRecognitionOperation *operation = [[SCMRecognitionOperation alloc] initWithImageData:scaledImageData location:self.location];
    
    __weak SCMRecognitionOperation *completedOperation = operation;
    operation.completionBlock = ^{
        if (!completedOperation.cancelled) {
            [self recognitionOperationCompleted:completedOperation];
        }
    };
    
    self.recognitionError = nil;
    [self.recognitionQueue addOperation:operation];
    self.numImagesSentForRecognition += 1;
    self.outstandingRecognitionOperations++;
    self.lastRequestTimeStamp = [NSDate date];
}

- (void)recognitionOperationCompleted:(SCMRecognitionOperation *)recognitionOperation
{
    self.outstandingRecognitionOperations--;
    
    BOOL imageNotRecognized = NO;
    
    if (recognitionOperation.error == nil) {
        BOOL recognized = (recognitionOperation.queryResponse.results.count > 0);
        if (recognized) {
            if (!self.imageRecognized) {
                self.imageRecognized = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate liveScanner:self
                               recognizedImage:recognitionOperation.imageData
                                    atLocation:self.location
                                  withResponse:recognitionOperation.queryResponse];
                });
                
                // Cancel any other image operations
                [self cancelAllOperations];
            }
        } else {
            imageNotRecognized = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate liveScanner:self didNotRecognizeImage:recognitionOperation.imageData];
            });
        }
    } else {
        DebugLog(@"RecognitionOperation failed: %@", [recognitionOperation.error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL sentOfflineImage = false;
            
            if ([recognitionOperation.error.domain isEqualToString:NSURLErrorDomain]) {

                if (recognitionOperation.error.code == NSURLErrorTimedOut ||
                    recognitionOperation.error.code == NSURLErrorCannotFindHost ||
                    recognitionOperation.error.code == NSURLErrorCannotConnectToHost ||
                    recognitionOperation.error.code == NSURLErrorNetworkConnectionLost ||
                    recognitionOperation.error.code == NSURLErrorDNSLookupFailed ||
                    recognitionOperation.error.code == NSURLErrorNotConnectedToInternet) {

                    if (self.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
                        self.recognitionError = [NSError errorWithDomain:kSCMLiveScannerErrorDomain code:kSCMLiveScannerErrorServerResponseTooSlow userInfo:nil];
                    } else if (self.liveScannerMode == kSCMLiveScannerSingleShotMode) {
                        [self.delegate liveScanner:self capturedSingleImageWhileOffline:recognitionOperation.imageData atLocation:self.location];
                        sentOfflineImage = true;
                    }
                } else if (recognitionOperation.error.code == NSURLErrorInternationalRoamingOff) {
                    // International roaming off
                    if (self.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
                        self.recognitionError = [NSError errorWithDomain:kSCMLiveScannerErrorDomain code:kSCMLiveScannerErrorInternationalRoamingOff userInfo:nil];
                    } else if (self.liveScannerMode == kSCMLiveScannerSingleShotMode) {
                        [self.delegate liveScanner:self capturedSingleImageWhileOffline:recognitionOperation.imageData atLocation:self.location];
                        sentOfflineImage = true;
                    }
                }
            }
            if (!self.recognitionError) {
                if (self.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
                    self.recognitionError = recognitionOperation.error;
                } else {
                    if (!sentOfflineImage)
                    {
                        [self.delegate liveScanner:self capturedSingleImageWhileOffline:recognitionOperation.imageData atLocation:self.location];
                    }
                }
            }
        });
    }
    
    if (self.outstandingRecognitionOperations == 0 && imageNotRecognized) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastImageUnrecognized = YES;
        });
    }
}

#pragma mark - SCMQRCodeScannerDelegate

- (void)qrcodeScanner:(SCMQRCodeScanner *)scanner didRecognizeQRCode:(NSString *)text
{
    self.imageRecognized = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate liveScanner:self recognizedQRCode:text atLocation:self.location];
    });
}

- (void)qrcodeScanner:(SCMQRCodeScanner *)scanner didNotRecognizeQRCode:(NSString *)why
{
    //empty
}

@end
