//
//  SCMCaptureSessionController.m
//  Shortcut
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "SCMCaptureSessionController.h"


static const NSInteger kLiveScanningCaptureSize = 1280;

@interface SCMCaptureSessionController (/* Private */)

@property (nonatomic, strong, readwrite) AVCaptureDevice* captureDevice;
@property (nonatomic, strong, readwrite) AVCaptureSession* captureSession;
@property (nonatomic, strong, readwrite) AVCaptureInput* captureInput;
@property (nonatomic, strong, readwrite) AVCaptureVideoDataOutput* videoCaptureOutput;
@property (nonatomic, strong, readwrite) AVCaptureStillImageOutput* stillImageOutput;
@property (nonatomic, strong, readwrite) AVCaptureConnection* stillImageVideoConnection;
@property (nonatomic, strong, readwrite) AVCaptureConnection* liveVideoConnection;
@property (nonatomic, strong, readwrite) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, assign, readwrite) SCMCaptureSessionMode captureSessionMode;
@property (atomic, assign, readwrite) BOOL running;

- (void)turnTorchOff;
- (void)switchToSingleShotMode;
- (void)switchToLiveScanningMode;

@end

@implementation SCMCaptureSessionController

@synthesize sampleBufferDelegate;
@synthesize captureDevice;
@synthesize captureSession;
@synthesize captureInput;
@synthesize videoCaptureOutput;
@synthesize stillImageOutput;
@synthesize stillImageVideoConnection;
@synthesize liveVideoConnection;
@synthesize previewLayer;
@synthesize captureSessionMode;
@synthesize running;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.captureSessionMode = kSCMCaptureSessionLiveScanningMode;
	}
	
	return self;
}

- (void)dealloc
{
	[self stopSession];
}

- (CMTime)minimumLiveScanningFrameDuration
{
    // Note: This needs to stay at 15fps. Otherwise, the display looks really slow. iOS will automatically throttle our
    //       frame rate if we take longer than 1/15s to process an image.
    return CMTimeMake(1, 15);
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

- (NSString*)captureSessionPreset
{
	return self.captureSession.sessionPreset;
}

- (NSString*)captureSessionPresetForMode:(SCMCaptureSessionMode)mode
{
	NSInteger captureSize = kLiveScanningCaptureSize;
	
	// Defaults in the rare case that the device doesn't support any of the following presets.
	NSString* sessionPreset = AVCaptureSessionPresetHigh;
	
	if (captureSize == 480)
	{
		// Test for the iPhone 3G
		if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480])
		{
			// The device supports 640x480, it's the 3GS or higher.
			sessionPreset = AVCaptureSessionPresetMedium;
		}
		else
		{
			// The 3G won't support 640x480, so if the value ends up being High, we know it's the 3G.
			sessionPreset = AVCaptureSessionPresetHigh;
		}
	}
	else if (captureSize == 640)
	{
		if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480])
		{
			sessionPreset = AVCaptureSessionPreset640x480;
		}
	}
	else
	{
		if (mode == kSCMCaptureSessionLiveScanningMode)
		{
			if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720])
			{
				sessionPreset = AVCaptureSessionPreset1280x720;
			}
			else if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480])
			{
				sessionPreset = AVCaptureSessionPreset640x480;
			}
		}
		else if ([self.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPresetPhoto])
		{
			sessionPreset = AVCaptureSessionPresetPhoto;
		}
	}
	
	return sessionPreset;
}

- (void)setupCaptureSessionForMode:(SCMCaptureSessionMode)initialMode
{
	if (self.captureSession != nil) {
		return;
	}
	
	self.captureSession = [[AVCaptureSession alloc] init];
	self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		
	self.captureSession.sessionPreset = [self captureSessionPresetForMode:initialMode];
    
	NSError* error = nil;
	self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
	if (error == nil)
	{
		[self.captureSession addInput:self.captureInput];
		self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
	}
	
	if (initialMode == kSCMCaptureSessionLiveScanningMode)
	{
		[self switchToLiveScanningMode];
	}
	else
	{
		[self switchToSingleShotMode];
	}
}

- (void)startSession
{
	if (self.running == NO)
	{
		self.running = YES;
		[self.captureSession startRunning];
	}
	else
	{
		NSAssert1(NO, @"%@ already running when caling start session!", self);
	}
}

- (void)switchToMode:(SCMCaptureSessionMode)mode
{
	if (self.captureSessionMode == mode)
	{
		return;
	}
	
	if (mode == kSCMCaptureSessionLiveScanningMode)
	{
		[self switchToLiveScanningMode];
	}
	else
	{
		[self switchToSingleShotMode];
	}
}

- (void)switchToSingleShotMode
{
	self.captureSessionMode = kSCMCaptureSessionSingleShotMode;

	// Disable the torch since we don't use it in single shot mode.
	[self turnTorchOff];
	
	[self.captureSession beginConfiguration];

	if (self.videoCaptureOutput != nil)
	{
		[self.captureSession removeOutput:self.videoCaptureOutput];
		self.videoCaptureOutput = nil;
		self.liveVideoConnection = nil;
	}
	
	self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary* outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
	[self.stillImageOutput setOutputSettings:outputSettings];
	[self.captureSession addOutput:self.stillImageOutput];
	
	for (AVCaptureConnection *connection in self.stillImageOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts]) 
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo])
			{
				self.stillImageVideoConnection = connection;
				break;
			}
		}
		
		if (self.stillImageVideoConnection != nil) 
		{
			break;
		}
	}

	self.captureSession.sessionPreset = [self captureSessionPresetForMode:kSCMCaptureSessionSingleShotMode];

	[self.captureSession commitConfiguration];
	DebugLog(@"captureSession preset %@", self.captureSession.sessionPreset);
}

- (void)switchToLiveScanningMode
{
	self.captureSessionMode = kSCMCaptureSessionLiveScanningMode;
	
	[self.captureSession beginConfiguration];
	
	if (self.stillImageOutput != nil)
	{
		[self.captureSession removeOutput:self.stillImageOutput];
		self.stillImageOutput = nil;
		self.stillImageVideoConnection = nil;
	}

	self.videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
	self.videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
	self.videoCaptureOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
																					 nil];
	
	[self.captureSession addOutput:self.videoCaptureOutput];
	
	for (AVCaptureConnection* connection in self.videoCaptureOutput.connections)
	{
		for (AVCaptureInputPort* port in connection.inputPorts)
		{
			if ([port.mediaType isEqualToString:AVMediaTypeVideo])
			{
				self.liveVideoConnection = connection;
				break;
			}
		}
	}
	
	if ([self.liveVideoConnection isVideoMinFrameDurationSupported])
    {
        self.liveVideoConnection.videoMinFrameDuration = self.minimumLiveScanningFrameDuration;
    }
    
	if (self.sampleBufferDelegate != nil)
	{
		dispatch_queue_t frameQueue = dispatch_queue_create("VideoFrameQueue", NULL);
		[self.videoCaptureOutput setSampleBufferDelegate:self.sampleBufferDelegate queue:frameQueue];
	}
	else
	{
		// There's no point continuing because no one will be watching for the images!
		NSAssert(self.sampleBufferDelegate != nil, @"Switching to scanning mode with no sampleBufferDelegate!");
	}

	self.captureSession.sessionPreset = [self captureSessionPresetForMode:kSCMCaptureSessionLiveScanningMode];
	
	if ([self.captureSession canAddOutput:self.videoCaptureOutput])
	{
		[self.captureSession addOutput:self.videoCaptureOutput];
	}

	[self.captureSession commitConfiguration];
	DebugLog(@"captureSession preset %@", self.captureSession.sessionPreset);

	self.liveVideoConnection.enabled = YES;
}

- (void)stopSession
{
	if (self.running)
	{
		// Turn the torch off if it was on. Better not to leave it in an on state.
		[self turnTorchOff];
        
		[self.captureSession stopRunning];
		self.running = NO;
	}
}

- (void)takePictureAsynchronouslyWithCompletionHandler:(void (^)(CMSampleBufferRef imageDataSampleBuffer, NSError *error))handler
{
	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:self.stillImageVideoConnection completionHandler:handler];
}

- (BOOL)flashOn
{
	BOOL on = NO;
	
	if ([self hasFlashForCurrentMode])
	{
		if (self.captureSessionMode == kSCMCaptureSessionLiveScanningMode)
		{
			on = (self.captureDevice.torchMode == AVCaptureTorchModeOn);
		}
		else
		{
			on = (self.captureDevice.flashMode == AVCaptureFlashModeOn);
		}
	}
	
	return on;
}

- (BOOL)hasFlashForCurrentMode
{
	BOOL hasFlash = NO;
	
	if (self.captureSessionMode == kSCMCaptureSessionLiveScanningMode)
	{
		hasFlash = [self.captureDevice hasTorch] && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOn];
	}
	else
	{
		hasFlash = [self.captureDevice hasFlash] && [self.captureDevice isFlashModeSupported:AVCaptureFlashModeOn];
	}
	
	return hasFlash;
}

- (void)turnTorchOff
{
	if ([self.captureDevice hasTorch] && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOff] &&
			self.captureDevice.torchMode != AVCaptureTorchModeOff)
	{
		if ([self.captureDevice lockForConfiguration:NULL])
		{
			self.captureDevice.torchMode = AVCaptureTorchModeOff;
			[self.captureDevice unlockForConfiguration];
		}
	}
}

- (void)toggleFlashMode
{
	if ([self hasFlashForCurrentMode])
	{
		if (self.captureSessionMode == kSCMCaptureSessionLiveScanningMode)
		{
			if (self.captureDevice.torchMode == AVCaptureTorchModeOff)
			{
				if ([self.captureDevice lockForConfiguration:NULL])
				{
					self.captureDevice.torchMode = AVCaptureTorchModeOn;
					[self.captureDevice unlockForConfiguration];
				}
			}
			else
			{
				if ([self.captureDevice lockForConfiguration:NULL])
				{
					self.captureDevice.torchMode = AVCaptureTorchModeOff;
					[self.captureDevice unlockForConfiguration];
				}
			}
		}
		else
		{
			if (self.captureDevice.flashMode == AVCaptureFlashModeOff)
			{
				if ([self.captureDevice lockForConfiguration:NULL])
				{
					self.captureDevice.flashMode = AVCaptureFlashModeOn;
					[self.captureDevice unlockForConfiguration];
				}
			}
			else
			{
				if ([self.captureDevice lockForConfiguration:NULL])
				{
					self.captureDevice.flashMode = AVCaptureFlashModeOff;
					[self.captureDevice unlockForConfiguration];
				}
			}
		}
	}
}


@end
