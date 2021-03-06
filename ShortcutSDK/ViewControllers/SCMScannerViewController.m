//
//  SCMScannerViewController.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMScannerViewController.h"
#import "SCMCameraZoomSlider.h"
#import "SCMCaptureSessionController.h"
#import "SCMLiveScanner.h"
#import "SCMRecognitionOperation.h"
#import "SCMCameraToolbar.h"
#import "SCMProgressToolbar.h"
#import "SCMCustomToolbarButton.h"
#import "SCMStatusView.h"
#import "SCMCameraModeControl.h"
#import "SCMSDKConfig.h"
#import "SCMLocalization.h"
#import "SCMImageUtils.h"
#import "SCMPreviewView.h"

static NSString *kUnrecognizedChanged = @"unrecognized changed";
static NSString *kScanningStatusChanged = @"scanning status changed";
static NSString *kRecognitionErrorChanged = @"recognition error changed";
NSString *const kUserPreferenceCameraStartsInScanMode = @"CameraStartsInScanMode";

static const NSTimeInterval kStatusViewTemporarilyVisibleDuration = 5.0;

typedef enum {
    kStatusViewStateHidden = 0,
    kStatusViewStateAnimatingVisible,
    kStatusViewStateVisible,
    kStatusViewStateAnimatingHidden
} StatusViewState;

@interface SCMScannerViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, SCMLiveScannerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
- (IBAction)collectionButtonPressed:(UIButton *)sender;

@property (nonatomic, strong, readwrite) SCMCaptureSessionController *captureSessionController;
@property (nonatomic, strong, readwrite) SCMLiveScanner *liveScanner;
@property (nonatomic, strong, readwrite) IBOutlet SCMPreviewView *previewView;
@property (nonatomic, strong, readwrite) IBOutlet SCMStatusView *cameraStatusView;
@property (nonatomic, strong, readwrite) IBOutlet SCMCameraZoomSlider *cameraZoomSlider;
@property (nonatomic, strong, readwrite) IBOutlet SCMCameraToolbar *cameraToolbar;
@property (nonatomic, strong, readwrite) IBOutlet SCMProgressToolbar *progressToolbar;
@property (nonatomic, strong, readwrite) IBOutlet SCMCameraModeControl *cameraModeControl;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *infoButton;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *flashButton;
@property (nonatomic, strong, readwrite) IBOutlet UIView *flashBackground;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView *previewImageView;
@property (nonatomic, strong, readwrite) CALayer *scanLineView;
@property (nonatomic, assign, readwrite) BOOL showingCameraHelp;
@property (nonatomic, assign, readwrite) StatusViewState statusViewState;
@property (nonatomic, strong, readwrite) NSTimer *statusViewTimer;
@property (nonatomic, assign, readwrite) BOOL shouldResumeScanning;
@property (nonatomic, strong, readwrite) NSData *previewImageData;
@property (nonatomic, assign, readwrite) BOOL shouldShowNavigationBarWhenDisappearing;
@property (nonatomic, assign, readwrite) BOOL scanQRCodes;
@property (nonatomic, assign, readwrite) BOOL showDoneButton;
@property (nonatomic, assign, readwrite) BOOL photoFromCameraRoll;
@property (nonatomic, assign, readwrite) BOOL QRCodeRecognized;
@property (weak, nonatomic) IBOutlet UIView *flashBackgroundView;

@end

@implementation SCMScannerViewController

#pragma mark - Live scanner configuration

- (IBAction)collectionButtonPressed:(UIButton *)sender {
    [self hideCameraHelp];
    [self choosePhotoFromLibrary];
}

- (SCMLiveScanner *)liveScanner {
    if (!_liveScanner) {
        _liveScanner = [[SCMLiveScanner alloc] init];
        _liveScanner.delegate = self;
    }
    return _liveScanner;
}

- (UIImage *)originalImage {
    return self.liveScanner.originalImage;
}

- (UIImage *)cropToDefaultAspectRatio:(UIImage *)image {
    UIImage *returnImage;
    UIImage *referenceImage = [[UIImage alloc] initWithCGImage:image.CGImage];
    CGFloat aspect = 1.333333333333333;
    CGSize imageSize = referenceImage.size;

    // initialize values assuming that imageSize.width < imageSize.height
    CGFloat shortSideLength = MIN(imageSize.width, imageSize.height);
    CGFloat longSideLength = shortSideLength * aspect;
    CGFloat offset = round(self.flashBackgroundView.frame.size.height / self.view.layer.frame.size.width * imageSize.width);
    CGFloat posX = 0.0;
    CGFloat posY = offset;
    CGRect rect = CGRectMake(posX, posY, shortSideLength, longSideLength);

    // mutate variables in case imageSize.height < imageSize.width
    if (imageSize.height < imageSize.width) {
        offset = round(self.flashBackgroundView.frame.size.height / self.view.layer.frame.size.width * imageSize.height);
        posX = offset;
        posY = 0.0;
        rect = CGRectMake(posX, posY, longSideLength, shortSideLength);
    }

    // Create bitmap image from context using the rect
    CGImageRef imageRef = CGImageCreateWithImageInRect(referenceImage.CGImage, rect);

    // Create a new image based on the imageRef and rotate back to the original orientation
    returnImage = [[UIImage alloc] initWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];

    image = nil;
    referenceImage = nil;
    CGImageRelease(imageRef);

    return returnImage;
}

- (CLLocation *)location {
    return self.liveScanner.location;
}

- (void)setLocation:(CLLocation *)location {
    self.liveScanner.location = location;
}

- (BOOL)scanQRCodes {
    return self.liveScanner.scanQRCodes;
}

- (void)setScanQRCodes:(BOOL)value {
    self.liveScanner.scanQRCodes = value;
}

#pragma mark - Initialization

- (instancetype)init {
    // Load view classes referenced in xib-file. TODO: is there another way??
    // => the alternative is to force all apps using the SDK to use the -ObjC
    // linker flag, see https://developers.facebook.com/docs/ios/troubleshooting#unrecognizedselector
    [SCMCameraModeControl class];
    [SCMCameraToolbar class];
    [SCMCameraZoomSlider class];
    [SCMCustomToolbar class];
    [SCMCustomToolbarButton class];
    [SCMProgressToolbar class];


    self = [super initWithNibName:@"SCMScannerViewController" bundle:[SCMSDKConfig SDKBundle]];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {}

    [self.captureSessionController stopSession];

    self.previewView = nil;
    self.cameraStatusView = nil;
    self.cameraZoomSlider = nil;
    self.cameraToolbar = nil;
    self.progressToolbar = nil;
    self.cameraModeControl = nil;
    self.infoButton = nil;
    self.flashButton = nil;
    self.flashBackground = nil;
    self.previewImageView = nil;
    self.scanLineView = nil;
    self.statusViewState = kStatusViewStateHidden;
    self.showingCameraHelp = NO;
    self.liveScanner.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.

    // capture session controller
    self.captureSessionController = [[SCMCaptureSessionController alloc] initWithMode:kSCMCaptureSessionTrackMode
                                                                 sampleBufferDelegate:self];
    self.captureSessionController.previewLayer = self.previewView.videoPreviewLayer;
    self.previewView.session = self.captureSessionController.captureSession;
    [self.captureSessionController startSession];

    // The default mode is single shot mode.
    SCMLiveScannerMode mode = kSCMLiveScannerSingleShotMode;
    BOOL startInScanMode = [[NSUserDefaults standardUserDefaults] boolForKey:kUserPreferenceCameraStartsInScanMode];
    if (self.previewImageData != nil || startInScanMode == NO) {
        mode = kSCMLiveScannerSingleShotMode;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.liveScanner.captureDevice = self.captureSessionController.captureDevice;
        [self.liveScanner setupForMode:mode];
        [self.liveScanner addObserver:self forKeyPath:@"currentImageIsUnrecognized" options:0 context:&kUnrecognizedChanged];
        [self.liveScanner addObserver:self forKeyPath:@"scanning" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&kScanningStatusChanged];
        [self.liveScanner addObserver:self forKeyPath:@"recognitionError" options:0 context:&kRecognitionErrorChanged];
        [self.liveScanner startScanning];
    });

    [self.cameraZoomSlider addTarget:self action:@selector(cameraZoomChanged) forControlEvents:UIControlEventValueChanged];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.cameraStatusView.hidden = YES;
    self.cameraStatusView.alpha = 0.0;

    [self updateModeStatus];
    [self updateFlashStatus];

    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewImageView.backgroundColor = [UIColor blackColor];

    // Only show the status view if we are not re-submitting a single shot image.
    [self showStatusViewForModeStatusChange];

    self.captureSessionController.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    self.cameraToolbar.doneButton.hidden = !self.showDoneButton;

    self.shouldShowNavigationBarWhenDisappearing = !self.navigationController.navigationBarHidden;
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.previewImageData == nil) { //
        [self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration]; //
    } //
    self.shouldResumeScanning = YES;

    // While the camera is displayed, don't allow the device to go to sleep or dim the screen.
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    if (self.cameraModeControl.cameraMode == kCameraModeLiveScanning) {
        [self startScanLineAnimation];
    }
}

- (void)viewDidLayoutSubviews {
    self.previewImageView.frame = self.previewView.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.cameraModeControl.cameraMode == kCameraModeLiveScanning) {
        [self stopScanLineAnimation];
    }

    // Re-instate the idle timer.
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    [self.liveScanner stopScanning];

    @try {
        [self.liveScanner removeObserver:self forKeyPath:@"currentImageIsUnrecognized"];
    } @catch (NSException *exception) {}
    @try {
        [self.liveScanner removeObserver:self forKeyPath:@"scanning"];
    } @catch (NSException *exception) {}
    @try {
        [self.liveScanner removeObserver:self forKeyPath:@"recognitionError"];
    } @catch (NSException *exception) {}

    self.navigationController.navigationBarHidden = !self.shouldShowNavigationBarWhenDisappearing;
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.captureSessionController stopSession];
    [super viewDidDisappear:animated];
}

#pragma mark - Delegate handling

- (void)setDelegate:(id <SCMScannerViewControllerDelegate>)newDelegate {
    _delegate = newDelegate;

    // enable QR code scanning if delegate has related callback
    self.scanQRCodes = [newDelegate respondsToSelector:@selector(scannerViewController:recognizedQRCode:atLocation:)];

    // show "Done" button if delegate has related callback
    self.showDoneButton = [newDelegate respondsToSelector:@selector(scannerViewControllerDidFinish:)];
}

#pragma mark - UI

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark - Single image handling

- (void)processImage:(NSData *)imageData {
    self.cameraStatusView.hidden = YES;
    self.statusViewState = kStatusViewStateHidden;

    [self switchToMode:kSCMLiveScannerSingleShotMode];

    self.previewImageData = imageData;

    if (self.liveScanner.originalImage != nil) {
        self.previewImageView.image = self.liveScanner.originalImage;
    } else {
        self.previewImageView.image = [UIImage imageWithData:self.previewImageData];
    }

    CGImageRef image = [UIImage imageWithData:imageData].CGImage;
    [self.liveScanner processImageRef:image];

    [self singleImageRecognitionStarted];
}

- (void)singleImageSentForRecognition:(NSData *)imageData {
    self.previewImageData = imageData;
    if (self.liveScanner.originalImage != nil) {
        self.previewImageView.image = self.liveScanner.originalImage;
    } else {
        self.previewImageView.image = [UIImage imageWithData:self.previewImageData];
    }

    [self singleImageRecognitionStarted];
}


- (void)singleImageFailedRecognition {
    [self singleImageRecognitionFinished];

    [self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"LiveScannerItemNotRecognizedTitle" withDefaultValue:@"No results found"]
                                 subtitle:nil];
    [self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];
}

- (void)singleImageDidFailWithError:(NSError *)error {
    [self singleImageRecognitionFinished];

    NSString *title = [SCMLocalization translationFor:@"Submission failed" withDefaultValue:@"Submission failed"];
    NSString *message = error.localizedDescription;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[SCMLocalization translationFor:@"OKButtonTitle" withDefaultValue:@"OK"]
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

- (void)singleImageRecognitionStarted {
    if (self.viewLoaded) {
        [self showSingleImagePreviewAnimated:YES];
        self.progressToolbar.animating = YES;
    }
}

- (void)singleImageRecognitionFinished {
//
    [self hideSingleImagePreview];
    self.previewImageData = nil;
//
    self.progressToolbar.animating = NO;
}

#pragma mark - Internal

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &kUnrecognizedChanged) {
        [self updateImageNotRecognizedStatus];
    } else if (context == &kScanningStatusChanged) {
        NSNumber *oldValue = change[NSKeyValueChangeOldKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];

        if (oldValue.boolValue == NO && newValue.boolValue) {
            [self startScanLineAnimation];
        } else if (oldValue.boolValue && newValue.boolValue == NO) {
            [self stopScanLineAnimation];
        }
    } else if (context == &kRecognitionErrorChanged) {
        if (self.liveScanner.recognitionError != nil) {
            NSError *error = self.liveScanner.recognitionError;
            NSString *title = nil;
            NSString *subtitle = nil;

            // no internet connection
            if ([error.domain isEqualToString:NSURLErrorDomain] &&
                (error.code == NSURLErrorTimedOut ||
                 error.code == NSURLErrorCannotFindHost ||
                 error.code == NSURLErrorCannotConnectToHost ||
                 error.code == NSURLErrorNetworkConnectionLost ||
                 error.code == NSURLErrorDNSLookupFailed ||
                 error.code == NSURLErrorNotConnectedToInternet)) {
                    title = [SCMLocalization translationFor:@"NoInternetConnectionTitle" withDefaultValue:@"No Internet connection"];
            }
            // slow internet connection
            else if ([error.domain isEqualToString:kSCMLiveScannerErrorDomain]) {
                if (error.code == kSCMLiveScannerErrorInternationalRoamingOff) {
                    title = [SCMLocalization translationFor:@"InternationalRoamingOff" withDefaultValue:@"International roaming is currently off."];
                    if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
                        subtitle = [SCMLocalization translationFor:@"SwitchingToSnapshotModeBody" withDefaultValue:@"Switching to Snapshot mode"];
                        [self switchToMode:kSCMLiveScannerSingleShotMode];
                    }

                } else if (error.code == kSCMLiveScannerErrorServerResponseTooSlow) {
                    title = [SCMLocalization translationFor:@"SlowInternetConnectionTitle" withDefaultValue:@"No Internet connection"];
                    if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
                        subtitle = [SCMLocalization translationFor:@"SwitchingToSnapshotModeBody" withDefaultValue:@"Switching to Snapshot mode"];
                        [self switchToMode:kSCMLiveScannerSingleShotMode];
                    }
                }
            }
            // authentication error
            else if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorUserCancelledAuthentication)) {
                title = [SCMLocalization translationFor:@"AuthenticationErrorTitle" withDefaultValue:@"Authentication error"];
                subtitle = [SCMLocalization translationFor:@"AuthenticationErrorBody" withDefaultValue:@"The image recognition service could not authenticate your request"];
            }
            // outdated API version
            else if ([error.domain isEqualToString:kSCMRecognitionOperationErrorDomain] && (error.code == kSCMRecognitionOperationNoMatchingMetadata)) {
                title = [SCMLocalization translationFor:@"OutdatedAPIErrorTitle" withDefaultValue:@"App is outdated"];
                subtitle = [SCMLocalization translationFor:@"OutdatedAPIErrorBody" withDefaultValue:@"The app cannot understand the image recognition service response.\nPlease update the app."];
            }
            // unknown error
            else {
                title = [SCMLocalization translationFor:@"RecognitionOperationFailedTitle" withDefaultValue:@"Recognition could not be completed"];
                subtitle = [NSString stringWithFormat:@"Error code %ld", (long) error.code];
            }

            [self.cameraStatusView setStatusTitle:title subtitle:subtitle];
            [self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];

            [self singleImageRecognitionFinished];
        }
    }
}

- (IBAction)done:(id)sender {
    self.shouldResumeScanning = NO;
    if ([self.delegate respondsToSelector:@selector(scannerViewControllerDidFinish:)]) {
        [self.delegate scannerViewControllerDidFinish:self];
    }
}

- (IBAction)takePicture:(id)sender {
    self.photoFromCameraRoll = NO;

    [self hideCameraHelp];

#if TARGET_IPHONE_SIMULATOR
    [self choosePhotoFromLibrary];
#else
    [self.liveScanner takePictureWithZoomFactor:self.cameraZoomSlider.zoomScale];
#endif

}

- (void)choosePhotoFromLibrary {
    self.photoFromCameraRoll = YES;

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];

    self.liveScanner.originalImage = image;

    UIImage *rotatedImage = [self fixImageRotation:image];

    [self.liveScanner processImageRef:rotatedImage.CGImage];
}

- (UIImage *)fixImageRotation:(UIImage *)image {
    CGSize size = image.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationLeft] drawInRect:CGRectMake(0, 0, size.height, size.width)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (void)updateModeStatus {
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
        self.cameraModeControl.cameraMode = kCameraModeLiveScanning;
        self.cameraToolbar.cameraButton.hidden = YES;
        self.cameraZoomSlider.hidden = YES;
    } else {
        self.cameraModeControl.cameraMode = kCameraModeSingleShot;
        self.cameraToolbar.cameraButton.hidden = NO;
    }
}

- (void)showStatusViewForModeStatusChange {
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {

        [self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"LiveScanningModeStatusTitle" withDefaultValue:@"Scanning mode"]
                                     subtitle:[SCMLocalization translationFor:@"LiveScanningModeStatusBody" withDefaultValue:@"Make sure that the whole item is visible in the scanner"]];
    } else {
        [self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"SingleShotModeStatusTitle" withDefaultValue:@"Snapshot mode"]
                                     subtitle:[SCMLocalization translationFor:@"SingleShotModeStatusBody" withDefaultValue:@"Make sure to capture the whole item"]];
    }
    [self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];
}

- (void)showStatusViewAndHideAfterTimeInterval:(NSTimeInterval)timeInterval {
    if (self.statusViewState == kStatusViewStateHidden ||
            self.statusViewState == kStatusViewStateAnimatingHidden) {
        self.cameraStatusView.hidden = NO;
        self.statusViewState = kStatusViewStateAnimatingVisible;

        [UIView animateWithDuration:0.25
                         animations:^{

                             self.cameraStatusView.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             self.statusViewState = kStatusViewStateVisible;
                         }];
    }

    [self.statusViewTimer invalidate];
    self.statusViewTimer = nil;
    if (timeInterval > 0.0) {
        self.statusViewTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                target:self
                                                              selector:@selector(hideStatusView)
                                                              userInfo:nil
                                                               repeats:NO];
    }
}

- (void)hideStatusView {
    if (self.statusViewState == kStatusViewStateVisible) {
        self.statusViewState = kStatusViewStateAnimatingHidden;
        [UIView animateWithDuration:0.3
                         animations:^{

                             self.cameraStatusView.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {

                             if (self.statusViewState == kStatusViewStateAnimatingHidden) {
                                 self.cameraStatusView.hidden = YES;
                                 self.statusViewState = kStatusViewStateHidden;
                             }
                         }];
    }
}

- (void)switchToMode:(SCMLiveScannerMode)mode {
    [self.liveScanner switchToMode:mode];

    [self updateModeStatus];
    [self updateFlashStatus];

    // Reset the zoom level when switching modes
    self.cameraZoomSlider.zoomScale = 1.0;
    [self cameraZoomChanged];
}

- (IBAction)cameraModeChanged:(id)sender {
    DebugLog(@"switching to mode: %@", self.liveScanner.liveScannerMode == kSCMCaptureSessionLiveScanningMode ? @"snapshot" : @"live");
    [self hideCameraHelp];

    if (self.cameraModeControl.cameraMode == kCameraModeLiveScanning && self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self switchToMode:kSCMLiveScannerLiveScanningMode];
        [self showStatusViewForModeStatusChange]; //
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserPreferenceCameraStartsInScanMode];
        [self startScanLineAnimation];
    } else if (self.cameraModeControl.cameraMode == kCameraModeSingleShot && self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
        [self switchToMode:kSCMLiveScannerSingleShotMode];
        [self showStatusViewForModeStatusChange]; //
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserPreferenceCameraStartsInScanMode];
        [self stopScanLineAnimation];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)cameraZoomChanged {
    [self hideCameraHelp];

    CGFloat scale = self.cameraZoomSlider.zoomScale;
    CGAffineTransform t = CGAffineTransformIdentity;
    self.previewView.transform = CGAffineTransformScale(t, scale, scale);
}

- (IBAction)toggleHelp {
    if (self.showingCameraHelp) {
        [self hideCameraHelp];
    } else {
        [self showCameraHelp];
    }
}

- (void)showCameraHelp {
    self.liveScanner.paused = YES;
    [self hideStatusView];
    [self.cameraZoomSlider hideZoomControl];
    self.showingCameraHelp = YES;

    self.helpView.frame = CGRectMake(CGRectGetMidX(self.view.frame) - self.helpView.frame.size.width / 2,
            CGRectGetMidY(self.view.frame) - self.helpView.frame.size.height / 2,
            self.helpView.frame.size.width,
            self.helpView.frame.size.height);
    self.helpView.alpha = 0;
    [self.view addSubview:self.helpView];
    [UIView transitionWithView:self.helpView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.helpView.alpha = 1.0;
                    }
                    completion:NULL];

    // Reinstate the idle timer while the user views the info screen.
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)hideCameraHelp {
    if (self.showingCameraHelp == NO) {
        return;
    }

    if (self.helpView)
        [UIView transitionWithView:self.helpView
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.helpView.alpha = 0.0;
                        }
                        completion:^(BOOL finished) {
                            [self.helpView removeFromSuperview];
                        }];

    self.liveScanner.paused = NO;
    self.showingCameraHelp = NO;

    [self updateImageNotRecognizedStatus];

    // Disable the idle timer since we are going back to the camera view.
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)updateFlashStatus {
    if ([self.captureSessionController hasTorch]) {
        if (self.captureSessionController.torchOn) {
            [self.flashButton setImage:[SCMImageUtils SDKBundleImageNamed:@"CameraFlashOn"] forState:UIControlStateNormal];
        } else {
            [self.flashButton setImage:[SCMImageUtils SDKBundleImageNamed:@"CameraFlashOff"] forState:UIControlStateNormal];
        }
        self.flashBackground.hidden = NO;
    } else {
        self.flashBackground.hidden = YES;
    }
}

- (IBAction)toggleTorchMode:(id)sender {
    [self.captureSessionController toggleTorchMode];
    [self updateFlashStatus];
}

- (void)showSingleImagePreviewAnimated:(BOOL)animated {
    [self.view insertSubview:self.previewImageView aboveSubview:self.previewView];

    if (animated) {
        [UIView transitionFromView:self.cameraToolbar
                            toView:self.progressToolbar
                          duration:0.3
                           options:UIViewAnimationOptionShowHideTransitionViews
                        completion:nil];
    } else {
        self.cameraToolbar.hidden = YES;
        self.progressToolbar.hidden = NO;
    }

    self.infoButton.enabled = NO;
    self.flashButton.enabled = NO;

    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             if (self.helpView) {
                                 self.infoButton.alpha = 0.0;
                             }
                             self.flashButton.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             if (self.helpView) {
                                 self.infoButton.hidden = YES;
                             }
                             self.flashBackground.hidden = YES;
                         }];
    } else {
        if (self.helpView) {
            self.infoButton.hidden = YES;
        }
        self.flashBackground.hidden = YES;
    }
}

- (void)hideSingleImagePreview {
    [self.previewImageView removeFromSuperview];

    [UIView transitionFromView:self.progressToolbar
                        toView:self.cameraToolbar
                      duration:0.3
                       options:UIViewAnimationOptionShowHideTransitionViews
                    completion:nil];

    self.infoButton.enabled = YES;
    self.flashButton.enabled = YES;

    [UIView animateWithDuration:0.3
                     animations:^{
                         if (self.helpView) {
                             self.infoButton.alpha = 1.0;
                         }
                         self.flashButton.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (self.helpView) {
                             self.infoButton.hidden = NO;
                         }
                         self.flashBackground.hidden = NO;
                     }];
}

- (void)startScanLineAnimation {
    if (self.scanLineView != nil) {
        // The scan line is already animating.
        return;
    }

    double maxX = CGRectGetMaxX(self.previewView.bounds);
    double maxY = CGRectGetMaxY(self.previewView.bounds);
    double lineLength = MAX(maxX, maxY) * 2;
    double lineWidth = 2;

    self.scanLineView = [CALayer layer];
    self.scanLineView.frame = CGRectMake(-maxX, -maxY, maxX * 2, maxY * 2);

    CALayer *verticalLine = [CALayer layer];
    verticalLine.frame = CGRectMake(0, maxY, lineLength, lineWidth);
    CALayer *horizontalLine = [CALayer layer];
    horizontalLine.frame = CGRectMake(maxX, 0, lineWidth, lineLength);

    UIColor *color;

    UIColor *themeColor = [UIColor colorWithRed:0.682f green:0.161f blue:0.067f alpha:1.0f];
    color = themeColor;

    verticalLine.backgroundColor = horizontalLine.backgroundColor = color.CGColor;

    [self.scanLineView addSublayer:verticalLine];
    [self.scanLineView addSublayer:horizontalLine];

    UIBezierPath *movePath = [UIBezierPath bezierPath];
    [movePath moveToPoint:CGPointMake(maxX - 1, maxY - 1)];
    [movePath addLineToPoint:CGPointMake(1, 1)];
    [movePath addLineToPoint:CGPointMake(maxX - 1, maxY - 1)];

    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    anim.path = movePath.CGPath;
    anim.rotationMode = kCAAnimationLinear;
    anim.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    anim.repeatCount = HUGE_VALF;
    anim.duration = 3.0;
    [self.scanLineView addAnimation:anim forKey:@"anim"];

    [self.view.layer insertSublayer:self.scanLineView above:self.previewView.layer];
}

- (void)stopScanLineAnimation {
    [self.scanLineView removeFromSuperlayer];
    self.scanLineView = nil;
}

- (void)updateImageNotRecognizedStatus {
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode && self.liveScanner.currentImageIsUnrecognized) {
        [self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"LiveScannerItemNotRecognizedTitle" withDefaultValue:@"No results found"]
                                     subtitle:nil];
        [self showStatusViewAndHideAfterTimeInterval:0.0];
    } else {
        [self hideStatusView];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.shouldResumeScanning) {
        [self.liveScanner startScanning];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self.liveScanner stopScanning];
}

- (void)updateIconOrientation {
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait: {
            transform = CGAffineTransformIdentity;
        }
            break;

        case UIDeviceOrientationLandscapeLeft: {
            transform = CGAffineTransformMakeRotation(M_PI_2);
        }
            break;

        case UIDeviceOrientationLandscapeRight: {
            transform = CGAffineTransformMakeRotation(-M_PI_2);
        }
            break;

        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            break;
    }

    [UIView animateWithDuration:0.25
                     animations:^{
                         self.infoButton.imageView.transform = transform;
                         self.flashButton.imageView.transform = transform;
                         //self.cameraToolbar.cameraButton.imageView.transform = transform;
                         self.cameraModeControl.singleShotIcon.transform = transform;
                         self.cameraModeControl.liveScannerIcon.transform = transform;
                     }];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    [self updateIconOrientation];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
            [self stopScanLineAnimation];
        }
    }                            completion:^(id <UIViewControllerTransitionCoordinatorContext> context) {
        if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
            [self startScanLineAnimation];
        }
    }];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.navigationController.navigationBarHidden = (viewController == self);
}

#pragma mark - SCMLiveScannerDelegate

- (void)liveScanner:(SCMLiveScanner *)scanner recognizingImage:(NSData *)imageData {
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageSentForRecognition:imageData];
    }
}

- (void)liveScanner:(SCMLiveScanner *)scanner didNotRecognizeImage:(NSData *)imageData {
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageFailedRecognition];
    }
}

- (void)liveScanner:(SCMLiveScanner *)scanner recognizedImage:(NSData *)imageData atLocation:(CLLocation *)location withResponse:(SCMQueryResponse *)response {
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageRecognitionFinished];
    }
    [self.delegate scannerViewController:self recognizedQuery:response atLocation:location fromImage:[self originalImage]];
}

- (void)liveScanner:(SCMLiveScanner *)scanner recognizedQRCode:(NSString *)text atLocation:(CLLocation *)location {
    self.QRCodeRecognized = YES;
    if ([self.delegate respondsToSelector:@selector(scannerViewController:recognizedQRCode:atLocation:)]) {
        [self.delegate scannerViewController:self recognizedQRCode:text atLocation:location];
    }
}

- (void)liveScanner:(SCMLiveScanner *)scanner capturedSingleImageWhileOffline:(NSData *)imageData atLocation:(CLLocation *)location {
    if (self.QRCodeRecognized) {
        self.QRCodeRecognized = NO;
        return;
    }

    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageDidFailWithError:nil];
        if ([self.delegate respondsToSelector:@selector(scannerViewController:capturedSingleImageWhileOffline:atLocation:)]) {
            [self.delegate scannerViewController:self capturedSingleImageWhileOffline:imageData atLocation:location];
        }
    }
}

- (void)liveScannerShouldClose:(SCMLiveScanner *)scanner {
    if ([self.delegate respondsToSelector:@selector(scannerViewControllerDidFinish:)]) {
        [self.delegate scannerViewControllerDidFinish:self];
    }
}

- (void)liveScanner:(SCMLiveScanner *)scanner didRequestPictureTakeWithCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler {
    [self.captureSessionController takePictureAsynchronouslyWithCompletionHandler:completionHandler];
}

#pragma mark - Capture Output Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!CMSampleBufferIsValid(sampleBuffer)) {
        return;
    }

    [self.liveScanner processSampleBuffer:sampleBuffer];
}

@end
