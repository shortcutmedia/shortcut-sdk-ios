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
static const CGFloat kDefaultOutputImageWidth = 640.0;
static const CGFloat kDefaultOutputImageHeight = 360.0;
static const CGFloat kDefaultOutputCompressionLevel = 0.30;
static const NSTimeInterval kMaximumServerResponseTime = 8.0;

@interface SCMLiveScanner () <AVCaptureVideoDataOutputSampleBufferDelegate, SCMQRCodeScannerDelegate>

@property (nonatomic, strong, readwrite) SCMCaptureSessionController *captureSessionController;
@property (nonatomic, strong, readwrite) SCMMotionDetector *motionDetector;
@property (nonatomic, strong, readwrite) SCMHistogramFilter *histogramFilter;
@property (nonatomic, strong, readwrite) SCMQRCodeScanner *qrCodeScanner;
@property (nonatomic, strong, readwrite) NSOperationQueue *recognitionQueue;
@property (nonatomic, assign, readwrite) NSInteger numImagesSentForRecognition;
@property (   atomic, assign, readwrite) NSInteger outstandingRecognitionOperations;
@property (nonatomic, assign, readwrite) CGFloat outputImageWidth;
@property (nonatomic, assign, readwrite) CGFloat outputImageHeight;
@property (nonatomic, assign, readwrite) CGFloat outputCompressionLevel;
@property (nonatomic, assign, readwrite) SCMLiveScannerMode liveScannerMode;
@property (nonatomic, assign, readwrite) BOOL scanning;
@property (nonatomic, assign, readwrite) BOOL running;
@property (nonatomic, assign, readwrite) BOOL lastImageUnrecognized;
@property (nonatomic, assign, readwrite) BOOL currentImageIsUnrecognized;
@property (nonatomic, strong, readwrite) NSError *recognitionError;
@property (atomic, assign, readwrite) BOOL imageRecognized;

@end

@implementation SCMLiveScanner

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.noMotionThreshold = kDefaultNoMotionThreshold;
        
        self.captureSessionController = [[SCMCaptureSessionController alloc] init];
        self.motionDetector = [[SCMMotionDetector alloc] init];
        self.histogramFilter = [[SCMHistogramFilter alloc] init];
        self.qrCodeScanner = [[SCMQRCodeScanner alloc] init];
        self.qrCodeScanner.delegate = self;
        
        self.outputImageWidth = kDefaultOutputImageWidth;
        self.outputImageHeight = kDefaultOutputImageHeight;
        self.outputCompressionLevel = kDefaultOutputCompressionLevel;
        
        self.recognitionQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [self cancelAllOperations];
}

#pragma mark - Public Methods

- (void)setupForMode:(SCMLiveScannerMode)initialMode
{
    self.histogramFilter.histogramThreshold = 45000.0;
    
    SCMCaptureSessionMode captureMode = kSCMCaptureSessionLiveScanningMode;
    if (initialMode == kSCMLiveScannerSingleShotMode) {
        captureMode = kSCMCaptureSessionSingleShotMode;
    }
    
    self.captureSessionController.sampleBufferDelegate = self;
    [self.captureSessionController setupCaptureSessionForMode:captureMode];
    
    // Optimize the output size based on the capture preset.
    NSInteger outputSize = 640;
    NSString *sessionPreset = self.captureSessionController.captureSessionPreset;
    if (sessionPreset == AVCaptureSessionPreset1280x720) {
        if (outputSize == 1280) {
            self.outputImageWidth = 1280;
            self.outputImageHeight = 720;
        } else if (outputSize == 640)
        {
            self.outputImageWidth = 640;
            self.outputImageHeight = 360;
        } else if (outputSize == 480)
        {
            self.outputImageWidth = 480;
            self.outputImageHeight = 360;
        } else {
            self.outputImageWidth = 320;
            self.outputImageHeight = 240;
        }
    } else if (sessionPreset == AVCaptureSessionPreset640x480)
    {
        if (outputSize == 1280 || outputSize == 640) {
            self.outputImageWidth = 640;
            self.outputImageHeight = 480;
        } else if (outputSize == 480)
        {
            self.outputImageWidth = 480;
            self.outputImageHeight = 360;
        } else {
            self.outputImageWidth = 320;
            self.outputImageHeight = 240;
        }
    } else if (sessionPreset == AVCaptureSessionPresetMedium)
    {
        if (outputSize == 1280 || outputSize == 640 || outputSize == 480) {
            self.outputImageWidth = 480;
            self.outputImageHeight = 360;
        } else {
            self.outputImageWidth = 320;
            self.outputImageHeight = 240;
        }
    } else if (sessionPreset == AVCaptureSessionPresetHigh)
    {
        // Must be the 3G
        self.outputImageWidth = 400;
        self.outputImageHeight = 304;
    }
    
    if (self.captureSessionController.captureSessionMode == kSCMCaptureSessionLiveScanningMode) {
        self.liveScannerMode = kSCMLiveScannerLiveScanningMode;
    } else {
        self.liveScannerMode = kSCMLiveScannerSingleShotMode;
    }
}

- (void)startScanning
{
    if (self.running == NO) {
        if (![SCMCaptureSessionController authorizedForVideoCapture]) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[SCMLocalization translationFor:@"CameraAccessRequiredTitle" withDefaultValue:@"Camera access required"]
                                                             message:[SCMLocalization translationFor:@"CameraAccessRequiredBody" withDefaultValue:@"The app needs access to the camera to scan things.\nPlease allow usage of the camera by enabling it in the privacy settings."]
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:[SCMLocalization translationFor:@"OKButtonTitle" withDefaultValue:@"OK"], nil];
            [alert show];
            [self.delegate liveScannerShouldClose:self];
            
        }
        
        self.running = YES;
        self.imageRecognized = NO;
        self.numImagesSentForRecognition = 0;
        [self.captureSessionController startSession];
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
        [self.captureSessionController stopSession];
        [self.motionDetector stopDetectingMotion];
    }
}

- (void)cancelAllOperations
{
    [self.recognitionQueue cancelAllOperations];
}

- (void)switchToMode:(SCMLiveScannerMode)mode
{
    if (mode == kSCMLiveScannerLiveScanningMode) {
        self.liveScannerMode = kSCMLiveScannerLiveScanningMode;
        self.recognitionError = nil;
        self.numImagesSentForRecognition = 0;
        [self.motionDetector startDetectingMotion];
        [self.captureSessionController switchToMode:kSCMCaptureSessionLiveScanningMode];
        [self.histogramFilter reset];
    } else {
        self.liveScannerMode = kSCMLiveScannerSingleShotMode;
        self.scanning = NO;
        [self cancelAllOperations];
        [self.motionDetector stopDetectingMotion];
        [self.captureSessionController switchToMode:kSCMCaptureSessionSingleShotMode];
    }
}

- (void)takePictureWithZoomFactor:(CGFloat)zoomFactor
{
    [self.captureSessionController takePictureAsynchronouslyWithCompletionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            CFDataRef imgData = (__bridge CFDataRef)jpegData;
            CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData (imgData);
            CGImageRef image = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
            
            [self processImage:image];
            
            CGImageRelease(image);
        } else {
            DebugLog(@"could not take picture because: %@", [error localizedDescription]);
        }
    }];
}

- (void)setPaused:(BOOL)value
{
    _paused = value;
    
    if (value) {
        self.scanning = NO;
        [self cancelAllOperations];
    }
}

#pragma mark - Capture Output Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFAbsoluteTime startOfFrameHandling = CFAbsoluteTimeGetCurrent();
    
    BOOL similar = [self.histogramFilter isSampleBufferHistogramSimilar:sampleBuffer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (similar) {
            // The image was the same as the last one sent to the server.
            if (self.lastImageUnrecognized && self.currentImageIsUnrecognized == NO) {
                self.currentImageIsUnrecognized = YES;
                self.scanning = NO;
            }
        } else {
            self.lastImageUnrecognized = NO;
            if (self.currentImageIsUnrecognized) {
                self.currentImageIsUnrecognized = NO;
            }
            
            if (self.liveScannerMode == kSCMLiveScannerLiveScanningMode && self.paused == NO) {
                self.scanning = YES;
            } else {
                self.scanning = NO;
            }
        }
    });
    
    if (similar == NO && ![self shouldSkipImage] && [self shouldSendImageForRecognition]) {
        CGImageRef sampleBufferImage = [SCMImageUtils newImageFromSampleBuffer:sampleBuffer];
        [self processImage:sampleBufferImage];
        CGImageRelease(sampleBufferImage);
    }
    
    CFAbsoluteTime endOfFrameHandling = CFAbsoluteTimeGetCurrent();
    
    // Let other threads/the network thread work for a bit if this handler basically runs all the time...
    if (endOfFrameHandling - startOfFrameHandling > CMTimeGetSeconds(self.captureSessionController.minimumLiveScanningFrameDuration)) {
        DebugLog(@"sample buffer handler is too slow");
        [NSThread sleepForTimeInterval:0.01];
    }
}

#pragma mark - Handling images

- (void)processImage:(CGImageRef)image
{
    if (self.scanQRCodes == YES && self.imageRecognized == NO) {
        [self.qrCodeScanner decodeImage:image];
    }
    
    NSData *scaledImageData = [SCMImageUtils scaledImageDataWithImage:image
                                                          orientation:6
                                                              maxSize:MAX(self.outputImageWidth, self.outputImageHeight)
                                                          compression:self.outputCompressionLevel
                                                           zoomFactor:1.0];
    
    [self.delegate liveScanner:self recognizingImage:scaledImageData];
    
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
    } else if (self.captureSessionController.captureDevice.adjustingFocus)
    {
        skipImage = YES;
    }
    
    //	DebugLog(@"still: %f, adjustingFocus: %@, adjustingExposure: %@, adjustingWhiteBalance: %@ (%@)",
    //					 timeSinceLastMotion,
    //					 self.captureSessionController.captureDevice.adjustingFocus ? @"YES" : @"NO",
    //					 self.captureSessionController.captureDevice.adjustingExposure ? @"YES" : @"NO",
    //					 self.captureSessionController.captureDevice.adjustingWhiteBalance ? @"YES" : @"NO",
    //					 skipImage ? @"YES" : @"NO");
    
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
    // TODO: readd timeout?
    //operation.responseTimeoutInterval = kMaximumServerResponseTime;
    
    __weak SCMRecognitionOperation *completedOperation = operation;
    [operation setCompletionBlock:^{
        if ([completedOperation isCancelled] == NO) {
            [self recognitionOperationCompleted:completedOperation];
        }
    }];
    
    self.recognitionError = nil;
    [self.recognitionQueue addOperation:operation];
    self.numImagesSentForRecognition += 1;
    self.outstandingRecognitionOperations++;
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
                    }
                }
            }
            if (!self.recognitionError) {
                self.recognitionError = recognitionOperation.error;
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
    [self.delegate liveScanner:self recognizedQRCode:text atLocation:self.location];
}

- (void)qrcodeScanner:(SCMQRCodeScanner *)scanner didNotRecognizeQRCode:(NSString *)why
{
    //empty
}

@end
