//
//  SCMCameraViewController.m
//  Shortcut
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "SCMCameraViewController.h"
#import "SCMCameraZoomSlider.h"
#import "SCMCaptureSessionController.h"
#import "SCMLiveScanner.h"
#import "SCMCameraToolbar.h"
#import "SCMProgressToolbar.h"
#import "SCMCustomToolbarButton.h"
#import "SCMStatusView.h"
#import "SCMCameraModeControl.h"
#import "SCMLiveScannerDelegate.h"
#import "SCMSDKConfig.h"
#import "SCMLocalization.h"

static NSString* kUnrecognizedChanged = @"unrecognized changed";
static NSString* kScanningStatusChanged = @"scanning status changed";
static NSString* kRecognitionErrorChanged = @"recognition error changed";
NSString* const kUserPreferenceCameraStartsInSnapshotMode = @"CameraStartsInSnapshotMode";

static const NSTimeInterval kStatusViewTemporarilyVisibleDuration = 5.0;

typedef enum
{
	kStatusViewStateHidden = 0,
	kStatusViewStateAnimatingVisible,
	kStatusViewStateVisible,
	kStatusViewStateAnimatingHidden
} StatusViewState;

@interface SCMCameraViewController (/* Private */) <SCMLiveScannerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong, readwrite) SCMLiveScanner* liveScanner;
@property (nonatomic, strong, readwrite) IBOutlet UIView* previewView;
@property (nonatomic, strong, readwrite) IBOutlet SCMStatusView* cameraStatusView;
@property (nonatomic, strong, readwrite) IBOutlet SCMCameraZoomSlider* cameraZoomSlider;
@property (nonatomic, strong, readwrite) IBOutlet SCMCameraToolbar* cameraToolbar;
@property (nonatomic, strong, readwrite) IBOutlet SCMProgressToolbar* progressToolbar;
@property (nonatomic, strong, readwrite) IBOutlet SCMCameraModeControl* cameraModeControl;
@property (nonatomic, strong, readwrite) IBOutlet UIButton* infoButton;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView* infoButtonIcon;
@property (nonatomic, strong, readwrite) IBOutlet UIButton* flashButton;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView* flashButtonIcon;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView* cameraButtonIcon;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView* previewImageView;
@property (nonatomic, strong, readwrite) CALayer* scanLineView;
@property (nonatomic, strong, readwrite) UITapGestureRecognizer* tapGestureRecognizer;
@property (nonatomic, strong, readwrite) UIPinchGestureRecognizer* pinchGestureRecognizer;
@property (nonatomic, assign, readwrite) BOOL showingCameraHelp;
@property (nonatomic, assign, readwrite) StatusViewState statusViewState;
@property (nonatomic, strong, readwrite) NSTimer* statusViewTimer;
@property (nonatomic, assign, readwrite) BOOL shouldResumeScanning;
@property (nonatomic, strong, readwrite) NSData* previewImageData;
@property (nonatomic, assign, readwrite) BOOL shouldShowNavigationBarWhenDisappearing;

- (IBAction)done:(id)sender;
- (IBAction)takePicture:(id)sender;
- (IBAction)cancelSingleImageRequest;
- (IBAction)cameraModeChanged:(id)sender;
- (void)tapToZoom;
- (void)cameraZoomChanged;
- (void)updateModeStatus;
- (void)showStatusViewForModeStatusChange;
- (void)showStatusViewAndHideAfterTimeInterval:(NSTimeInterval)timeInterval;
- (void)hideStatusView;
- (void)switchToMode:(SCMLiveScannerMode)mode;
- (void)showCameraHelp;
- (void)hideCameraHelp;
- (void)updateFlashStatus;
- (void)updateInfoStatus;
- (IBAction)toggleFlashMode:(id)sender;
- (void)startScanLineAnimation;
- (void)stopScanLineAnimation;
- (void)showSingleImagePreviewAnimated:(BOOL)animated;
- (void)hideSingleImagePreview;
- (void)updateImageNotRecognizedStatus;
- (void)applicationDidBecomeActive:(NSNotification*)notification;
- (void)applicationWillResignActive:(NSNotification*)notification;
- (void)updateIconOrientation;
- (void)deviceOrientationDidChange:(NSNotification*)notification;

@end

@implementation SCMCameraViewController

@synthesize delegate;
@synthesize cameraStatusView;
@synthesize previewView;
@synthesize cameraZoomSlider;
@synthesize cameraToolbar;
@synthesize progressToolbar;
@synthesize cameraModeControl;
@synthesize infoButton;
@synthesize infoButtonIcon;
@synthesize flashButton;
@synthesize flashButtonIcon;
@synthesize cameraButtonIcon;
@synthesize previewImageView;
@synthesize scanLineView;
@synthesize tapGestureRecognizer;
@synthesize pinchGestureRecognizer;
@synthesize liveScanner;
@synthesize showingCameraHelp;
@synthesize statusViewState;
@synthesize statusViewTimer;
@synthesize shouldResumeScanning;
@synthesize previewImageData;
@synthesize helpView;
@synthesize shouldShowNavigationBarWhenDisappearing;

#pragma mark - Live scanner configuration

- (SCMLiveScanner *)liveScanner
{
    if (!liveScanner) {
        liveScanner = [[SCMLiveScanner alloc] init];
        liveScanner.delegate = self;
    }
    return liveScanner;
}

- (CLLocation*)location
{
    return self.liveScanner.location;
}

- (void)setLocation:(CLLocation *)location
{
    self.liveScanner.location = location;
}

- (BOOL)scanQRCodes
{
    return self.liveScanner.scanQRCodes;
}

- (void)setScanQRCodes:(BOOL)value
{
    self.liveScanner.scanQRCodes = value;
}

#pragma mark - Initialization

- (instancetype)init
{
    // Load view classes referenced in xib-file. TODO: is there another way??
    // => the alternative is to force all apps using the SDK to use the -ObjC
    // linker flag, see https://developers.facebook.com/docs/ios/troubleshooting#unrecognizedselector
    [SCMCameraModeControl class];
    [SCMCameraToolbar class];
    [SCMCameraZoomSlider class];
    [SCMCustomToolbar class];
    [SCMCustomToolbarButton class];
    [SCMProgressToolbar class];
    
    
	self = [super initWithNibName:@"SCMCameraViewController" bundle:[SCMSDKConfig SDKBundle]];
	
    if (self)
	{
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

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"SCMCameraViewController: custom nib ignored. Use init to instantiate an instance");
    return [self init];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.liveScanner.delegate = nil;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Do any additional setup after loading the view from its nib.
	
	// The default mode is live scanning mode.
	SCMLiveScannerMode mode = kSCMLiveScannerLiveScanningMode;
	BOOL startInSingleShotMode = [[NSUserDefaults standardUserDefaults] boolForKey:kUserPreferenceCameraStartsInSnapshotMode];
	if (self.previewImageData != nil || startInSingleShotMode)
	{
		mode = kSCMLiveScannerSingleShotMode;
	}
	
    /*if ((([[UIScreen mainScreen] bounds].size.height-568)?NO:YES))
    {
        CGRect frame = self.previewView.frame;
        frame.size.height += 176;
        [self.previewView setFrame:frame];
    }*/
    
	[self.liveScanner setupForMode:mode];
	
	self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToZoom)];
	[self.previewView addGestureRecognizer:self.tapGestureRecognizer];

	self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self.cameraZoomSlider action:@selector(pinchToZoom:)];
	[self.previewView addGestureRecognizer:self.pinchGestureRecognizer];
	[self.cameraZoomSlider addTarget:self action:@selector(cameraZoomChanged) forControlEvents:UIControlEventValueChanged];

	self.cameraStatusView.hidden = YES;
	self.cameraStatusView.alpha = 0.0;
	
	self.scanLineView = [CALayer layer];
		
	[self updateModeStatus];
	[self updateFlashStatus];
    [self updateInfoStatus];

	if (self.previewImageData != nil)
	{
		self.previewImageView.image = [UIImage imageWithData:self.previewImageData];
		[self showSingleImagePreviewAnimated:NO];
	}
	else
	{
		// Only show the status view if we are not re-submitting a single shot image.
		[self showStatusViewForModeStatusChange];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	
	self.previewView = nil;
	self.cameraStatusView = nil;
	self.cameraZoomSlider = nil;
	self.cameraToolbar = nil;
	self.progressToolbar = nil;
	self.cameraModeControl = nil;
	self.infoButton = nil;
	self.infoButtonIcon = nil;
	self.flashButton = nil;
	self.flashButtonIcon = nil;
	self.cameraButtonIcon = nil;
	self.previewImageView = nil;
	self.scanLineView = nil;
	self.tapGestureRecognizer = nil;
	self.pinchGestureRecognizer = nil;
	self.statusViewState = kStatusViewStateHidden;
	
	// This is a small cheat to reset the status of the help screen. We dump the supportedContentViewController above,
	// so it is not possible (at this time) to restore the help screen in viewDidLoad properly. Therefore, just indicate
	// that we are not showing the help and the user can tap "i" again to view the help.
	self.showingCameraHelp = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self updateInfoStatus];
    
    self.liveScanner.captureSessionController.previewLayer.frame = self.previewView.bounds;
	self.liveScanner.captureSessionController.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.previewView.layer addSublayer:self.liveScanner.captureSessionController.previewLayer];
    self.previewImageView.frame = self.previewView.bounds;
    
    self.shouldShowNavigationBarWhenDisappearing = !self.navigationController.navigationBarHidden;
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
	if (self.previewImageData == nil)
	{
		[self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];
	}
	[self.liveScanner addObserver:self forKeyPath:@"currentImageIsUnrecognized" options:0 context:&kUnrecognizedChanged];
	[self.liveScanner addObserver:self forKeyPath:@"scanning" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&kScanningStatusChanged];
	[self.liveScanner addObserver:self forKeyPath:@"recognitionError" options:0 context:&kRecognitionErrorChanged];
	[self.liveScanner startScanning];
	self.shouldResumeScanning = YES;
	
	// While the camera is displayed, don't allow the device to go to sleep or dim the screen.
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if (self.cameraModeControl.cameraMode == kCameraModeLiveScanning)
        [self startScanLineAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	// Re-instate the idle timer.
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	[self.liveScanner stopScanning];
	[self.liveScanner removeObserver:self forKeyPath:@"currentImageIsUnrecognized"];
	[self.liveScanner removeObserver:self forKeyPath:@"scanning"];
	[self.liveScanner removeObserver:self forKeyPath:@"recognitionError"];
    
    self.navigationController.navigationBarHidden = !self.shouldShowNavigationBarWhenDisappearing;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationNone;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Single image handling

- (void)processImage:(NSData *)imageData
{
    self.cameraStatusView.hidden = YES;
    self.statusViewState = kStatusViewStateHidden;
    
    [self switchToMode:kSCMLiveScannerSingleShotMode];
        
    self.previewImageData = imageData;
    self.previewImageView.image = [UIImage imageWithData:previewImageData];
    
    CGImageRef image = [UIImage imageWithData:imageData].CGImage;
    [self.liveScanner processImage:image];
    
    [self singleImageRecognitionStarted];
}

- (void)singleImageSentForRecognition:(NSData*)imageData
{
	self.previewImageData = imageData;
	self.previewImageView.image = [UIImage imageWithData:previewImageData];
    
    [self singleImageRecognitionStarted];
}


- (void)singleImageFailedRecognition
{
    [self singleImageRecognitionFinished];
    
    [self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"LiveScannerItemNotRecognizedTitle" withDefaultValue:@"No results found"]
                                 subtitle:nil];
    [self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];
}

- (void)singleImageDidFailWithError:(NSError*)error
{
    [self singleImageRecognitionFinished];
	NSString* title = [SCMLocalization translationFor:@"Submission failed" withDefaultValue:@"Submission failed"];
	NSString* message = [error localizedDescription];
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:[SCMLocalization translationFor:@"OKButtonTitle" withDefaultValue:@"OK"]
                                              otherButtonTitles:nil];
	[alertView show];
}

- (void)singleImageRecognitionStarted
{
    if ([self isViewLoaded])
    {
        [self showSingleImagePreviewAnimated:YES];
        self.progressToolbar.animating = YES;
    }
}

- (void)singleImageRecognitionFinished
{
    [self hideSingleImagePreview];
    self.previewImageData = nil;
    self.progressToolbar.animating = NO;
}

#pragma mark - Internal

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &kUnrecognizedChanged)
	{
		[self updateImageNotRecognizedStatus];
	}
	else if (context == &kScanningStatusChanged)
	{
		NSNumber* oldValue = [change objectForKey:NSKeyValueChangeOldKey];
		NSNumber* newValue = [change objectForKey:NSKeyValueChangeNewKey];

		if ([oldValue boolValue] == NO && [newValue boolValue])
		{
			[self startScanLineAnimation];
		}
		else if ([oldValue boolValue] && [newValue boolValue] == NO)
		{
			[self stopScanLineAnimation];
		}
	}
	else if (context == &kRecognitionErrorChanged)
	{
		if (self.liveScanner.recognitionError != nil)
		{
            NSError *error = self.liveScanner.recognitionError;
            NSString *title = nil;
            NSString *subtitle = nil;
            
            if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorTimedOut ||
                                                                    error.code == NSURLErrorCannotFindHost ||
                                                                    error.code == NSURLErrorCannotConnectToHost ||
                                                                    error.code == NSURLErrorNetworkConnectionLost ||
                                                                    error.code == NSURLErrorDNSLookupFailed ||
                                                                    error.code == NSURLErrorNotConnectedToInternet)) {
                // no internet connection
                title = [SCMLocalization translationFor:@"NoInternetConnectionTitle" withDefaultValue:@"No Internet connection"];
            } else if ([error.domain isEqualToString:kSCMLiveScannerErrorDomain] && error.code == kSCMLiveScannerErrorServerResponseTooSlow) {
                // slow internet connection
                title = [SCMLocalization translationFor:@"SlowInternetConnectionTitle" withDefaultValue:@"No Internet connection"];
                if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode) {
                    subtitle = [SCMLocalization translationFor:@"SwitchingToSnapshotModeBody" withDefaultValue:@"Switching to Snapshot mode"];
                    [self switchToMode:kSCMLiveScannerSingleShotMode];
                }
            } else if ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorUserCancelledAuthentication)) {
                // authentication error
                title = [SCMLocalization translationFor:@"AuthenticationErrorTitle" withDefaultValue:@"Authentication error"];
                subtitle = [SCMLocalization translationFor:@"AuthenticationErrorBody" withDefaultValue:@"The image recognition service could not authenticate your request"];
            } else {
                title = [SCMLocalization translationFor:@"RecognitionOperationFailedTitle" withDefaultValue:@"Recognition could not be completed"];
                subtitle = [NSString stringWithFormat:@"Error code %ld", (long)error.code];
            }
            
            [self.cameraStatusView setStatusTitle:title subtitle:subtitle];
            [self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];
            
            [self singleImageRecognitionFinished];
		}
	}
}

- (IBAction)done:(id)sender
{
	self.shouldResumeScanning = NO;
	[self.delegate cameraViewControllerDidFinish:self];
}

- (IBAction)takePicture:(id)sender
{
	[self hideCameraHelp];

#if TARGET_IPHONE_SIMULATOR
	[self choosePhotoFromLibrary];
#else
	[self.liveScanner takePictureWithZoomFactor:self.cameraZoomSlider.zoomScale];
#endif
}

#if TARGET_IPHONE_SIMULATOR
- (void)choosePhotoFromLibrary
{
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    // TODO: fix image rotation/orientation
    [self.liveScanner processImage:image.CGImage];
}
#endif

- (IBAction)cancelSingleImageRequest
{
	[self hideSingleImagePreview];
}

- (void)updateModeStatus
{
	if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode)
	{
		self.cameraModeControl.cameraMode = kCameraModeLiveScanning;
		self.cameraToolbar.cameraButton.hidden = YES;
		self.cameraButtonIcon.hidden = YES;
		self.cameraZoomSlider.hidden = YES;
		self.tapGestureRecognizer.enabled = NO;
		self.pinchGestureRecognizer.enabled = NO;
	}
	else
	{
		self.cameraModeControl.cameraMode = kCameraModeSingleShot;
		self.cameraToolbar.cameraButton.hidden = NO;
		self.cameraButtonIcon.hidden = NO;
		// Note: We don't need to unhide the camera zoom slider. It will show when the user actually zooms or taps.
		self.tapGestureRecognizer.enabled = YES;
		self.pinchGestureRecognizer.enabled = YES;
	}
}

- (void)showStatusViewForModeStatusChange
{
	if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode)
	{
        
		[self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"LiveScanningModeStatusTitle" withDefaultValue:@"Scanning mode"]
                                     subtitle:[SCMLocalization translationFor:@"LiveScanningModeStatusBody" withDefaultValue:@"Make sure that the whole item is visible in the scanner"]];
	}
	else
	{
        [self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"SingleShotModeStatusTitle" withDefaultValue:@"Snapshot mode"]
                                     subtitle:[SCMLocalization translationFor:@"SingleShotModeStatusBody" withDefaultValue:@"Make sure to capture the whole item"]];
	}
	[self showStatusViewAndHideAfterTimeInterval:kStatusViewTemporarilyVisibleDuration];
}

- (void)showStatusViewAndHideAfterTimeInterval:(NSTimeInterval)timeInterval
{
	if (self.statusViewState == kStatusViewStateHidden ||
			self.statusViewState == kStatusViewStateAnimatingHidden)
	{
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
	if (timeInterval > 0.0)
	{
		self.statusViewTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                target:self
                                                              selector:@selector(hideStatusView)
                                                              userInfo:nil
                                                               repeats:NO];
	}
}

- (void)hideStatusView
{
	if (self.statusViewState == kStatusViewStateVisible)
	{
		self.statusViewState = kStatusViewStateAnimatingHidden;
		[UIView animateWithDuration:0.3
										 animations:^{
											 
											 self.cameraStatusView.alpha = 0.0;
										 } 
										 completion:^(BOOL finished) {
											 
											 if (self.statusViewState == kStatusViewStateAnimatingHidden)
											 {
												 self.cameraStatusView.hidden = YES;
												 self.statusViewState = kStatusViewStateHidden;
											 }
										 }];
	}
}

- (void)switchToMode:(SCMLiveScannerMode)mode
{
	[self.liveScanner switchToMode:mode];
	[self updateModeStatus];
    [self updateFlashStatus];
    [self updateInfoStatus];

	// Reset the zoom level when switching modes
	self.cameraZoomSlider.zoomScale = 1.0;
	[self cameraZoomChanged];
}

- (IBAction)cameraModeChanged:(id)sender
{
	DebugLog(@"switching to mode: %@", self.liveScanner.liveScannerMode == kSCMCaptureSessionLiveScanningMode ? @"snapshot" : @"live");
	[self hideCameraHelp];
	
	if (self.cameraModeControl.cameraMode == kCameraModeLiveScanning && self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode)
	{
		[self switchToMode:kSCMLiveScannerLiveScanningMode];
		[self showStatusViewForModeStatusChange];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserPreferenceCameraStartsInSnapshotMode];
        [self startScanLineAnimation];
	}
	else if (self.cameraModeControl.cameraMode == kCameraModeSingleShot && self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode)
	{
		[self switchToMode:kSCMLiveScannerSingleShotMode];
		[self showStatusViewForModeStatusChange];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserPreferenceCameraStartsInSnapshotMode];
        [self stopScanLineAnimation];
	}
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tapToZoom
{
	[self hideCameraHelp];
	
	if (self.tapGestureRecognizer.state == UIGestureRecognizerStateEnded)
	{
		[self.cameraZoomSlider showZoomControl];
	}
}

- (void)cameraZoomChanged
{
	[self hideCameraHelp];
	
	CGFloat scale = self.cameraZoomSlider.zoomScale;
	CGAffineTransform t = CGAffineTransformIdentity;
	self.previewView.transform = CGAffineTransformScale(t, scale, scale);
}

- (IBAction)toggleHelp
{
	if (self.showingCameraHelp)
	{
		[self hideCameraHelp];
	}
	else
	{
		[self showCameraHelp];
	}
}

- (void)showCameraHelp
{
    self.liveScanner.paused = YES;
	[self hideStatusView];
	[self.cameraZoomSlider hideZoomControl];
	self.showingCameraHelp = YES;
    
    self.helpView.frame = CGRectMake(CGRectGetMidX(self.view.frame) - self.helpView.frame.size.width/2,
                                     CGRectGetMidY(self.view.frame) - self.helpView.frame.size.height/2,
                                     self.helpView.frame.size.width,
                                     self.helpView.frame.size.height);
    self.helpView.alpha = 0;
    [self.view addSubview:self.helpView];
    [UIView transitionWithView:self.helpView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{self.helpView.alpha = 1.0;}
                    completion:NULL];
	
	// Reinstate the idle timer while the user views the info screen.
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void) hideHelpView
{
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
}

- (void)hideCameraHelp
{
	if (self.showingCameraHelp == NO)
	{
		return;
	}
    
    [self hideHelpView];
	
	self.liveScanner.paused = NO;
	self.showingCameraHelp = NO;
	
	[self updateImageNotRecognizedStatus];

	// Disable the idle timer since we are going back to the camera view.
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)updateFlashStatus
{
	if ([self.liveScanner.captureSessionController hasFlashForCurrentMode])
	{
		self.flashButton.hidden = NO;
		self.flashButtonIcon.hidden = NO;
		if (self.liveScanner.captureSessionController.flashOn)
		{
			self.flashButtonIcon.image = [UIImage imageNamed:@"CameraFlashOnIcon"
                                                    inBundle:[SCMSDKConfig SDKBundle]
                               compatibleWithTraitCollection:nil];
		}
		else
		{
			self.flashButtonIcon.image = [UIImage imageNamed:@"CameraFlashOffIcon"
                                                    inBundle:[SCMSDKConfig SDKBundle]
                               compatibleWithTraitCollection:nil];
		}
	}
	else
	{
		self.flashButton.hidden = YES;
		self.flashButtonIcon.hidden = YES;
	}
}

- (void)updateInfoStatus
{
    if (self.helpView) {
        self.infoButton.hidden = NO;
        self.infoButtonIcon.hidden = NO;
    }
    else {
        self.infoButton.hidden = YES;
        self.infoButtonIcon.hidden = YES;
    }
}

- (IBAction)toggleFlashMode:(id)sender
{
	[self hideCameraHelp];
	
	[self.liveScanner.captureSessionController toggleFlashMode];
	[self updateFlashStatus];
}

- (void)showSingleImagePreviewAnimated:(BOOL)animated
{
	[self.view insertSubview:self.previewImageView aboveSubview:self.previewView];
	
	self.progressToolbar.frame = self.cameraToolbar.frame;
	if (animated)
	{
		[UIView transitionFromView:self.cameraToolbar
												toView:self.progressToolbar
											duration:0.3
											 options:UIViewAnimationOptionTransitionCrossDissolve
										completion:^(BOOL finished) {
										}];
	}
	else
	{
		[self.view insertSubview:self.progressToolbar aboveSubview:self.cameraToolbar];
		[self.cameraToolbar removeFromSuperview];
	}
	
	self.infoButton.enabled = NO;
	self.flashButton.enabled = NO;

	if (animated)
	{
		[UIView animateWithDuration:0.3
										 animations:^{
                                             if (self.helpView) {
                                                 self.infoButton.alpha = 0.0;
                                                 self.infoButtonIcon.alpha = 0.0;
                                             }
											 self.flashButton.alpha = 0.0;
											 self.flashButtonIcon.alpha = 0.0;
										 }
										 completion:^(BOOL finished) {
                                             if (self.helpView) {
                                                 self.infoButton.hidden = YES;
                                                 self.infoButtonIcon.hidden = YES;
                                             }
											 self.flashButton.hidden = YES;
											 self.flashButtonIcon.hidden = YES;
										 }];
	}
	else
	{
        if (self.helpView) {
            self.infoButton.hidden = YES;
            self.infoButtonIcon.hidden = YES;
        }
		self.flashButton.hidden = YES;
		self.flashButtonIcon.hidden = YES;
	}
}

- (void)hideSingleImagePreview
{
	[self.previewImageView removeFromSuperview];
	[UIView transitionFromView:self.progressToolbar
											toView:self.cameraToolbar
										duration:0.3
										 options:UIViewAnimationOptionTransitionCrossDissolve
									completion:^(BOOL finished) {
									}];

	self.infoButton.enabled = YES;
	self.flashButton.enabled = YES;
	[UIView animateWithDuration:0.3
									 animations:^{
                                         if (self.helpView) {
                                             self.infoButton.alpha = 1.0;
                                             self.infoButtonIcon.alpha = 1.0;
                                         }
										 self.flashButton.alpha = 1.0;
										 self.flashButtonIcon.alpha = 1.0;
									 }
									 completion:^(BOOL finished) {
                                         if (self.helpView) {
                                             self.infoButton.hidden = NO;
                                             self.infoButtonIcon.hidden = NO;
                                         }
										 self.flashButton.hidden = NO;
										 self.flashButtonIcon.hidden = NO;
									 }];
}

- (void)startScanLineAnimation
{
	if (self.scanLineView.superlayer != nil)
	{
		// The scan line is already animating.
		return;
	}
	
	UIViewAnimationOptions animationOptions = UIViewAnimationOptionCurveEaseInOut;
	animationOptions = animationOptions | UIViewAnimationOptionAllowUserInteraction;
    
    //double midX = CGRectGetMidX(self.previewView.bounds);
    //double midY = CGRectGetMidY(self.previewView.bounds);
    double maxX = CGRectGetMaxX(self.previewView.bounds);
    double maxY = CGRectGetMaxY(self.previewView.bounds);
    
	self.scanLineView.frame = CGRectMake(-maxX, -maxY, maxX*2, maxY*2);
    CALayer *verticalLine = [CALayer layer];
    CALayer *verticalLine2 = [CALayer layer];
    verticalLine.frame = CGRectMake(0, maxY, maxX*2, 3);
    CALayer *horizontalLine = [CALayer layer];
    horizontalLine.frame = CGRectMake(maxX, 0, 3, maxY*2);
    UIImage *color = [UIImage imageNamed:@"OrangeColor.png"
                                inBundle:[SCMSDKConfig SDKBundle]
           compatibleWithTraitCollection:nil];
    verticalLine.contents = verticalLine2.contents = horizontalLine.contents = (id)(color.CGImage);
    [self.scanLineView addSublayer:verticalLine];
    [self.scanLineView addSublayer:verticalLine2];
    [self.scanLineView addSublayer:horizontalLine];
    
    UIBezierPath *movePath = [UIBezierPath bezierPath];
    [movePath moveToPoint:CGPointMake(maxX-1, maxY-1)];
    [movePath addLineToPoint:CGPointMake(1, 1)];
    [movePath addLineToPoint:CGPointMake(maxX-1, maxY-1)];
    
    /*[movePath addCurveToPoint:CGPointMake(maxX-40, maxY-40) controlPoint1:CGPointMake(midX+(midX/5.0), midY+(midY/3.0)) controlPoint2:CGPointMake(midX+(midX/3.0), midY+(midY/3.0*2))];
    [movePath addCurveToPoint:CGPointMake(40, 40) controlPoint1:CGPointMake(maxX-(midX/2.0), midY) controlPoint2:CGPointMake(midX/2.0, midY/3.0)];
    [movePath addCurveToPoint:CGPointMake(midX, midY) controlPoint1:CGPointMake(midX/5.0, midY/3.0) controlPoint2:CGPointMake(midX/3.0, midY/3.0*2)];*/
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    anim.path = movePath.CGPath;
    anim.rotationMode = kCAAnimationLinear;
    anim.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    anim.repeatCount = HUGE_VALF;
    anim.duration = 3.0;
    [self.scanLineView addAnimation:anim forKey:@"anim"];
    
    [self.view.layer insertSublayer:self.scanLineView above:self.previewView.layer];}

- (void)stopScanLineAnimation
{
	if (self.scanLineView.superlayer != nil)
	{
		[self.scanLineView removeAllAnimations];
		[self.scanLineView removeFromSuperlayer];
	}
}

- (void)updateImageNotRecognizedStatus
{
	if (self.liveScanner.liveScannerMode == kSCMLiveScannerLiveScanningMode && self.liveScanner.currentImageIsUnrecognized)
	{
		[self.cameraStatusView setStatusTitle:[SCMLocalization translationFor:@"LiveScannerItemNotRecognizedTitle" withDefaultValue:@"No results found"]
                                     subtitle:nil];
		[self showStatusViewAndHideAfterTimeInterval:0.0];
	}
	else
	{
		[self hideStatusView];
	}
}

- (void)applicationDidBecomeActive:(NSNotification*)notification
{
	if (self.shouldResumeScanning)
	{
		[self.liveScanner startScanning];
	}
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
	[self.liveScanner stopScanning];
}

- (void)updateIconOrientation
{
	UIDevice* device = [UIDevice currentDevice];
	
	BOOL rotate = NO;
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	switch (device.orientation)
	{
		case UIDeviceOrientationPortrait:
		{
			transform = CGAffineTransformIdentity;
			rotate = YES;
		}
			break;
			
		case UIDeviceOrientationLandscapeLeft:
		{
			transform = CGAffineTransformMakeRotation(M_PI_2);
			rotate = YES;
		}
			break;
			
		case UIDeviceOrientationLandscapeRight:
		{
			transform = CGAffineTransformMakeRotation(-M_PI_2);
			rotate = YES;
		}
			break;
			
		case UIDeviceOrientationPortraitUpsideDown:
		case UIDeviceOrientationUnknown:
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
			break;
	}
	
	if (rotate)
	{
		[UIView animateWithDuration:0.25
										 animations:^{
											 self.infoButtonIcon.transform = transform;
											 self.flashButtonIcon.transform = transform;
											 self.cameraButtonIcon.transform = transform;
											 self.cameraModeControl.singleShotIcon.transform = transform;
											 self.cameraModeControl.liveScannerIcon.transform = transform;
										 }];
	}
}

- (void)deviceOrientationDidChange:(NSNotification*)notification
{
	[self updateIconOrientation];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	self.navigationController.navigationBarHidden = (viewController == self);
}

#pragma mark - SCMLiveScannerDelegate

- (void)liveScanner:(SCMLiveScanner*)scanner recognizingImage:(NSData*)imageData
{
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageSentForRecognition:imageData];
    }
}

- (void)liveScanner:(SCMLiveScanner *)scanner didNotRecognizeImage:(NSData *)imageData
{
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageFailedRecognition];
    }
}

- (void)liveScanner:(SCMLiveScanner*)scanner recognizedImage:(NSData*)imageData atLocation:(CLLocation*)location withResponse:(SCMQueryResponse*)response
{
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageRecognitionFinished];
    }
    [self.delegate cameraViewController:self recognizedQuery:response atLocation:location fromImage:imageData];
}

- (void)liveScanner:(SCMLiveScanner*)scanner recognizedBarcode:(NSString*)text atLocation:(CLLocation*)location
{
    [self.delegate cameraViewController:self recognizedBarcode:text atLocation:location];
}

- (void)liveScanner:(SCMLiveScanner*)scanner capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location
{
    if (self.liveScanner.liveScannerMode == kSCMLiveScannerSingleShotMode) {
        [self singleImageDidFailWithError:nil];
    }
    [self.delegate cameraViewController:self capturedSingleImageWhileOffline:imageData atLocation:location];
}

- (void)liveScannerShouldClose:(SCMLiveScanner*)scanner
{
    [self.delegate cameraViewControllerDidFinish:self];
}

@end
