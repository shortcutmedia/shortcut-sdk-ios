//
//  SCMCameraModeControl.m
//  ShortcutSDK
//
//  Created by David Wisti on 4/4/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMCameraModeControl.h"
#import "SCMSDKConfig.h"


static const CGFloat kModeIconHorizontalMargin = 4.0;
static const CGFloat KModeIconVerticalMargin = 3.0;
static const CGFloat kSliderHorizontalMargin = 1.0;
static const CGFloat KSliderDragThreshold = 4.0;

@interface SCMCameraModeControl (/* Private */)

@property (nonatomic, strong, readwrite) UIImageView *sliderBackground;
@property (nonatomic, strong, readwrite) UIImageView *singleShotIcon;
@property (nonatomic, strong, readwrite) UIImageView *liveScannerIcon;
@property (nonatomic, strong, readwrite) UIImageView *slider;
@property (nonatomic, assign, readwrite) CGFloat initialTouchX;
@property (nonatomic, assign, readwrite) BOOL userDraggedSlider;

- (CGRect)sliderRectForMode:(SCMCameraMode)mode;
- (void)switchModes;

@end


@implementation SCMCameraModeControl

@synthesize cameraMode;
@synthesize sliderBackground;
@synthesize singleShotIcon;
@synthesize liveScannerIcon;
@synthesize slider;
@synthesize initialTouchX;
@synthesize userDraggedSlider;

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSString *sliderBackroundImagePath = [[SCMSDKConfig SDKBundle] pathForResource:@"CameraModeSliderBackground" ofType:@"png"];
	UIImage *sliderBackgroundImage = [UIImage imageWithContentsOfFile:sliderBackroundImagePath];
	self.sliderBackground = [[UIImageView alloc] initWithImage:sliderBackgroundImage];
	[self addSubview:self.sliderBackground];
	
	NSString *singleShotPath = [[SCMSDKConfig SDKBundle] pathForResource:@"CameraModeSingleShotIcon" ofType:@"png"];
	UIImage *singleShotImage = [UIImage imageWithContentsOfFile:singleShotPath];
	self.singleShotIcon = [[UIImageView alloc] initWithImage:singleShotImage];
	self.singleShotIcon.contentMode = UIViewContentModeCenter;
	[self addSubview:self.singleShotIcon];
	
	NSString *liveIconPath = [[SCMSDKConfig SDKBundle] pathForResource:@"CameraModeLiveScannerIcon" ofType:@"png"];
	UIImage *liveIconImage = [UIImage imageWithContentsOfFile:liveIconPath];
	self.liveScannerIcon = [[UIImageView alloc] initWithImage:liveIconImage];
	self.liveScannerIcon.contentMode = UIViewContentModeCenter;
	[self addSubview:self.liveScannerIcon];
	
	NSString *sliderPath = [[SCMSDKConfig SDKBundle] pathForResource:@"CameraModeSlider" ofType:@"png"];
	UIImage *sliderImage = [UIImage imageWithContentsOfFile:sliderPath];
	self.slider = [[UIImageView alloc] initWithImage:sliderImage];
	[self addSubview:self.slider];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self.sliderBackground sizeToFit];
	[self.singleShotIcon sizeToFit];
	[self.liveScannerIcon sizeToFit];
	[self.slider sizeToFit];
	
	CGFloat backgroundHeight = CGRectGetHeight(self.sliderBackground.frame);
	CGFloat liveHeight = MAX(CGRectGetHeight(self.liveScannerIcon.frame), CGRectGetWidth(self.liveScannerIcon.frame));
	CGFloat singleHeight = MAX(CGRectGetHeight(self.singleShotIcon.frame), CGRectGetWidth(self.singleShotIcon.frame));
	
	CGFloat totalHeight = backgroundHeight + KModeIconVerticalMargin + MAX(singleHeight, liveHeight);
	
	CGFloat frameWidth = CGRectGetWidth(self.bounds);
	CGFloat backgroundWidth = CGRectGetWidth(self.sliderBackground.frame);
	
	CGFloat backgroundX = floorf((frameWidth - backgroundWidth) / 2.0);
	CGFloat backgroundY = floorf((CGRectGetMaxY(self.bounds) - totalHeight) / 2.0) + totalHeight - backgroundHeight;
	self.sliderBackground.frame = CGRectMake(backgroundX, backgroundY, backgroundWidth, CGRectGetHeight(self.sliderBackground.frame));
	
	CGFloat iconCenter = backgroundY - KModeIconVerticalMargin - floorf(MAX(singleHeight, liveHeight) / 2.0);
	
	CGFloat singleX = backgroundX + kModeIconHorizontalMargin;
	CGFloat singleY = floorf(iconCenter - (singleHeight / 2.0));
	self.singleShotIcon.frame = CGRectMake(singleX, singleY, singleHeight, singleHeight);
	
	CGFloat liveX = CGRectGetMaxX(self.sliderBackground.frame) - kModeIconHorizontalMargin - liveHeight;
	CGFloat liveY = floorf(iconCenter - (liveHeight / 2.0));
	self.liveScannerIcon.frame = CGRectMake(liveX, liveY, liveHeight, liveHeight);
	
	self.slider.frame = [self sliderRectForMode:self.cameraMode];
}

- (void)setCameraMode:(SCMCameraMode)mode
{
	cameraMode = mode;
	[self setNeedsLayout];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	self.userDraggedSlider = NO;
	CGPoint location = [touch locationInView:self];
	self.initialTouchX = location.x;
	return YES;
}

- (void)updateSliderFrameWithTouch:(UITouch *)touch
{
	CGPoint location = [touch locationInView:self];
	CGFloat deltaX = location.x - self.initialTouchX;
	if (fabsf(deltaX) > KSliderDragThreshold)
	{
		self.userDraggedSlider = YES;
	}
	
	CGRect initialSliderRect = [self sliderRectForMode:self.cameraMode];
	CGFloat minSliderX = CGRectGetMinX(self.sliderBackground.frame) + kSliderHorizontalMargin;
	CGFloat maxSliderX = CGRectGetMaxX(self.sliderBackground.frame) - CGRectGetWidth(self.slider.frame) - kSliderHorizontalMargin;
	
	CGFloat updatedSliderX = CGRectGetMinX(initialSliderRect) + deltaX;
	updatedSliderX = MIN(updatedSliderX, maxSliderX);
	updatedSliderX = MAX(updatedSliderX, minSliderX);
	
	self.slider.frame = CGRectMake(updatedSliderX, CGRectGetMinY(self.slider.frame),
																 CGRectGetWidth(self.slider.frame), CGRectGetHeight(self.slider.frame));
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self updateSliderFrameWithTouch:touch];
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self updateSliderFrameWithTouch:touch];
	
	if (self.userDraggedSlider == NO)
	{
		[self switchModes];
	}
	else
	{
		BOOL shouldSwitchModes = NO;
		CGFloat backgroundCenterX = CGRectGetMidX(self.sliderBackground.frame);
		CGFloat sliderCenterX = CGRectGetMidX(self.slider.frame);
		if (sliderCenterX < backgroundCenterX)
		{
			if (self.cameraMode == kCameraModeLiveScanning)
			{
				shouldSwitchModes = YES;
			}
		}
		else if (sliderCenterX >= backgroundCenterX)
		{
			if (self.cameraMode == kCameraModeSingleShot)
			{
				shouldSwitchModes = YES;
			}
		}
		
		if (shouldSwitchModes)
		{
			[self switchModes];
		}
		else
		{
			// Animate the slider back to its original position
			[UIView animateWithDuration:0.15
											 animations:^{
												 self.slider.frame = [self sliderRectForMode:self.cameraMode];
											 }];
		}
	}
	
	self.userDraggedSlider = NO;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
	self.userDraggedSlider = NO;
	
	// Make sure the slider gets put back into its place.
	[self setNeedsLayout];
}

- (CGRect)sliderRectForMode:(SCMCameraMode)mode
{
	CGFloat sliderX = CGRectGetMinX(self.sliderBackground.frame) + kSliderHorizontalMargin;
	if (self.cameraMode == kCameraModeLiveScanning)
	{
		sliderX = CGRectGetMaxX(self.sliderBackground.frame) - CGRectGetWidth(self.slider.frame) - kSliderHorizontalMargin;
	}
	CGFloat sliderWidth = CGRectGetWidth(self.slider.frame);
	CGFloat sliderY = CGRectGetMinY(self.sliderBackground.frame) + 1.0;
	CGRect sliderFrame = CGRectMake(sliderX, sliderY, sliderWidth, CGRectGetHeight(self.slider.frame));
	
	return sliderFrame;
}

- (void)switchModes
{
	self.cameraMode = self.cameraMode == kCameraModeSingleShot ? kCameraModeLiveScanning : kCameraModeSingleShot;
	[UIView animateWithDuration:0.15
									 animations:^{
										 self.slider.frame = [self sliderRectForMode:self.cameraMode];
									 }
									 completion:^(BOOL finished) {
										 [self sendActionsForControlEvents:UIControlEventValueChanged];
									 }];
}


@end
