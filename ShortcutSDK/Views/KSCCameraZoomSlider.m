//
//  KSCCameraZoomSlider.m
//  Shortcut
//
//  Created by David Wisti on 11/3/11.
//  Copyright (c) 2011 kooaba AG. All rights reserved.
//

#import "KSCCameraZoomSlider.h"
#import "KSCSDKConfig.h"


const CGFloat kTrackLeftMargin = 10.0;
const CGFloat kTrackRightMargin = 10.0;
const CGFloat kThumbMargin = 1.0;
const CGFloat kThumbTouchRectMargin = 10.0;
const CGFloat kPlusMinusMargin = 11.0;
const CGFloat kPlusMinusUpdateDelta = 0.02;
const NSTimeInterval kPlusMinusUpdateDelay = 0.02;
const NSTimeInterval kHideZoomControlDelay = 5.0;
const CGFloat kMinCameraZoomScale = 1.0;	// This MUST always be 1.0, otherwise the preview image will not fill the screen.
const CGFloat kMaxCameraZoomScale = 3.0;	// This value specifies the maxium zoom level. Increase this too much and it becomes unusable.

@interface KSCCameraZoomSlider (/* Private */)

@property (nonatomic, strong) UIImage* trackMinImage;
@property (nonatomic, strong) UIImage* trackMaxImage;
@property (nonatomic, strong) UIImage* trackImage;
@property (nonatomic, strong) UIImage* thumbImage;
@property (nonatomic, strong) UIImage* minusImage;
@property (nonatomic, strong) UIImage* plusImage;
@property (nonatomic, assign) CGRect trackRect;
@property (nonatomic, assign) CGRect trackMinRect;
@property (nonatomic, assign) CGRect trackMaxRect;
@property (nonatomic, assign) CGRect thumbImageRect;
@property (nonatomic, assign) CGRect minusImageRect;
@property (nonatomic, assign) CGRect plusImageRect;
@property (nonatomic, assign) CGRect minusTouchRect;
@property (nonatomic, assign) CGRect plusTouchRect;
@property (nonatomic, assign) CGRect thumbTouchRect;
@property (nonatomic, assign) CGFloat touchOrigin;
@property (nonatomic, assign) CGFloat thumbOrigin;
@property (nonatomic, strong) NSNumber* initialDelta;
@property (nonatomic, assign) BOOL draggingThumb;
@property (nonatomic, assign) BOOL zoomingIn;
@property (nonatomic, assign) BOOL zoomingOut;
@property (nonatomic, strong) NSTimer* hideControlsTimer;
@property (nonatomic, assign, readwrite) CGFloat initialPinchZoomScale;

- (void)updateThumbRects;
- (CGFloat)scaleForX:(CGFloat)x;
- (CGFloat)XForScale:(CGFloat)scale;
- (void)continueZooming;
- (void)updateZoomLevel;
- (void)cancelHideZoomControlTimer;
- (void)hideZoomControlTimerExpired:(NSTimer*)timer;
- (void)animateToHidden;

@end

@implementation KSCCameraZoomSlider

@synthesize zoomScale;
@synthesize maxScale;
@synthesize trackMinImage;
@synthesize trackMaxImage;
@synthesize trackImage;
@synthesize thumbImage;
@synthesize minusImage;
@synthesize plusImage;
@synthesize trackRect;
@synthesize trackMinRect;
@synthesize trackMaxRect;
@synthesize thumbImageRect;
@synthesize minusImageRect;
@synthesize plusImageRect;
@synthesize minusTouchRect;
@synthesize plusTouchRect;
@synthesize thumbTouchRect;
@synthesize touchOrigin;
@synthesize thumbOrigin;
@synthesize draggingThumb;
@synthesize zoomingIn;
@synthesize zoomingOut;
@synthesize initialDelta;
@synthesize hideControlsTimer;
@synthesize initialPinchZoomScale;

- (void)awakeFromNib
{
	[super awakeFromNib];

	self.trackMinImage = [UIImage imageNamed:@"PLCameraZoomTrackMin"
                                    inBundle:[KSCSDKConfig SDKBundle]
               compatibleWithTraitCollection:nil];
	self.trackMaxImage = [UIImage imageNamed:@"PLCameraZoomTrackMax"
                                    inBundle:[KSCSDKConfig SDKBundle]
               compatibleWithTraitCollection:nil];
	self.trackImage = [[UIImage imageNamed:@"PLCameraZoomTrack"
                                  inBundle:[KSCSDKConfig SDKBundle]
             compatibleWithTraitCollection:nil] stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
	self.thumbImage = [UIImage imageNamed:@"PLCameraZoomThumb"
                                 inBundle:[KSCSDKConfig SDKBundle]
            compatibleWithTraitCollection:nil];
	self.minusImage = [UIImage imageNamed:@"PLCameraZoomMin"
                                 inBundle:[KSCSDKConfig SDKBundle]
            compatibleWithTraitCollection:nil];
	self.plusImage = [UIImage imageNamed:@"PLCameraZoomMax"
                                inBundle:[KSCSDKConfig SDKBundle]
           compatibleWithTraitCollection:nil];
	self.backgroundColor = [UIColor clearColor];
	
	// These are initialized without the accessors. If accessors are used, then maxScale must be set first, since
	// zoomScale uses maxScale to constrain the value of zoomScale.
	maxScale = 3.0;
	zoomScale = 1.0;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGFloat genericY = floorf((CGRectGetHeight(self.bounds) - self.trackImage.size.height) / 2.0);
	self.trackMinRect = CGRectMake(kTrackLeftMargin, genericY, self.trackMinImage.size.width, self.trackMinImage.size.height);
	
	CGFloat minusImageX = CGRectGetMinX(self.trackMinRect) + kPlusMinusMargin;
	CGFloat minusImageY = floorf((self.trackMinImage.size.height - self.minusImage.size.height) / 2.0) + genericY;
	self.minusImageRect = CGRectMake(minusImageX, minusImageY, self.minusImage.size.width, self.minusImage.size.height);
	
	CGFloat trackMaxImageX = CGRectGetMaxX(self.bounds) - kTrackRightMargin - self.trackMaxImage.size.width;
	self.trackMaxRect = CGRectMake(trackMaxImageX, genericY, self.trackMaxImage.size.width, self.trackMaxImage.size.height);

	CGFloat plusImageX = CGRectGetMaxX(self.trackMaxRect) - kPlusMinusMargin - self.plusImage.size.width;
	CGFloat plusImageY = floorf((self.trackMaxImage.size.height - self.plusImage.size.height) / 2.0) + genericY;
	self.plusImageRect = CGRectMake(plusImageX, plusImageY, self.plusImage.size.width, self.plusImage.size.height);
	
	CGFloat minusMaxX = kTrackLeftMargin + self.trackMinImage.size.width;
	self.minusTouchRect = CGRectMake(0.0, 0.0, minusMaxX, CGRectGetMaxY(self.bounds));
	
	self.plusTouchRect = CGRectMake(trackMaxImageX, 0.0, CGRectGetMaxX(self.bounds) - trackMaxImageX, CGRectGetMaxY(self.bounds));
	
	CGFloat trackMinX = kTrackLeftMargin + self.trackMinImage.size.width;
	CGFloat trackWidth = trackMaxImageX - trackMinX;
	self.trackRect = CGRectMake(trackMinX, genericY, trackWidth, self.trackImage.size.height);
	
	[self updateThumbRects];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	[self.trackMinImage drawInRect:self.trackMinRect];
	[self.trackMaxImage drawInRect:self.trackMaxRect];
	[self.trackImage drawInRect:self.trackRect];
	[self.thumbImage drawInRect:self.thumbImageRect];
	[self.plusImage drawInRect:self.plusImageRect];
	[self.minusImage drawInRect:self.minusImageRect];
}

- (void)dealloc
{
	[self.hideControlsTimer invalidate];
}

- (void)setZoomScale:(CGFloat)scale
{
	// Constrain the zoomScale to 1.0 to maxScale.
	if (scale < 1.0)
	{
		scale = 1.0;
	}
	else if (scale > self.maxScale)
	{
		scale = self.maxScale;
	}
	zoomScale = scale;
	[self updateThumbRects];
	[self setNeedsDisplay];
}

- (void)updateThumbRects
{
	CGFloat genericY = floorf((CGRectGetHeight(self.bounds) - self.trackImage.size.height) / 2.0);
	CGFloat thumbX = [self XForScale:self.zoomScale];
	CGFloat thumbY = floorf((self.trackImage.size.height - self.thumbImage.size.height) / 2.0) + genericY;
	self.thumbImageRect = CGRectMake(thumbX, thumbY, self.thumbImage.size.width, self.thumbImage.size.height);

	CGFloat trackMinX = CGRectGetMinX(self.trackRect);
	CGFloat trackMaxX = CGRectGetMaxX(self.trackRect);

	CGFloat touchRectWidth = self.thumbImage.size.width + (2 * kThumbTouchRectMargin);
	CGFloat touchRectX = thumbX - kThumbTouchRectMargin;
	CGFloat touchRectMaxX = thumbX + self.thumbImage.size.width + kThumbTouchRectMargin;
	if (touchRectX < trackMinX)
	{
		touchRectX = trackMinX;
	}
	else if (touchRectMaxX > trackMaxX)
	{
		touchRectX = trackMaxX - touchRectWidth;
	}
	
	self.thumbTouchRect = CGRectMake(touchRectX, 0.0, touchRectWidth, CGRectGetMaxY(self.bounds));
}

- (void)continueZooming
{
	[self performSelector:@selector(updateZoomLevel) withObject:nil afterDelay:kPlusMinusUpdateDelay];
}

- (void)updateZoomLevel
{
	CGFloat delta = 0.0;
	if (self.zoomingIn)
	{
		delta = kPlusMinusUpdateDelta;
	}
	else if (self.zoomingOut)
	{
		delta = -kPlusMinusUpdateDelta;
	}
	
	if (delta != 0.0)
	{
		CGFloat relativeScale = (self.zoomScale - 1.0) / (self.maxScale - 1.0);
		CGFloat updatedRelativeScale = relativeScale + delta;
		updatedRelativeScale = MAX(0.0, updatedRelativeScale);
		updatedRelativeScale = MIN(1.0, updatedRelativeScale);
		CGFloat updatedScale = (updatedRelativeScale * (self.maxScale - 1.0)) + 1.0;
		self.zoomScale = updatedScale;
		[self sendActionsForControlEvents:UIControlEventValueChanged];
		[self continueZooming];
	}
}

- (CGFloat)scaleForX:(CGFloat)x
{
	CGFloat thumbMinX = CGRectGetMinX(self.trackRect) + kThumbMargin;
	CGFloat thumbMaxX = CGRectGetMaxX(self.trackRect) - self.thumbImage.size.width - kThumbMargin;
	if (x < thumbMinX)
	{
		x = thumbMinX;
	}
	else if (x > thumbMaxX)
	{
		x = thumbMaxX;
	}
	
	CGFloat relativeThumbX = x - thumbMinX;
	CGFloat relativeTrackMaxX = thumbMaxX - thumbMinX;
	CGFloat relativeScale = relativeThumbX / relativeTrackMaxX;
	CGFloat scale = (relativeScale * (self.maxScale - 1.0)) + 1.0;
	return scale;
}

- (CGFloat)XForScale:(CGFloat)scale
{
	CGFloat thumbMinX = CGRectGetMinX(self.trackRect) + kThumbMargin;
	CGFloat thumbMaxX = CGRectGetMaxX(self.trackRect) - self.thumbImage.size.width - kThumbMargin;
	CGFloat thumbTrackWidth = thumbMaxX - thumbMinX;
	CGFloat relativeScale = (scale - 1.0) / (self.maxScale - 1.0);
	CGFloat x = (relativeScale * thumbTrackWidth) + thumbMinX;
	return x;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint location = [touch locationInView:self];
//	NSLog(@"beginTracking at %@", NSStringFromCGPoint(location));

	if (CGRectContainsPoint(self.minusTouchRect, location))
	{
		self.zoomingOut = YES;
		[self continueZooming];
	}
	else if (CGRectContainsPoint(self.plusTouchRect, location))
	{
		self.zoomingIn = YES;
		[self continueZooming];
	}
	else if (CGRectContainsPoint(self.thumbTouchRect, location))
	{
		self.thumbOrigin = CGRectGetMinX(self.thumbImageRect);
		self.touchOrigin = location.x;
		self.draggingThumb = YES;
	}
	
	// We'll set the timer once the tracking is done.
	[self cancelHideZoomControlTimer];
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.draggingThumb == NO && self.zoomingIn == NO && self.zoomingOut == NO)
	{
		return YES;
	}

	if (self.draggingThumb)
	{
		CGPoint location = [touch locationInView:self];
		CGFloat delta = location.x - self.touchOrigin;
		
		if (self.initialDelta == nil)
		{
			self.initialDelta = [NSNumber numberWithFloat:delta];
		}
		
		delta = delta - [self.initialDelta floatValue];
		
		CGFloat thumbX = self.thumbOrigin + delta;
		self.zoomScale = [self scaleForX:thumbX];
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
	
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	self.draggingThumb = NO;
	self.zoomingIn = NO;
	self.zoomingOut = NO;
	self.initialDelta = nil;
	
	[self resetHideZoomControlTimer];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
	self.draggingThumb = NO;
	self.zoomingIn = NO;
	self.zoomingOut = NO;
	self.initialDelta = nil;
	
	[self resetHideZoomControlTimer];
}

- (void)showZoomControl
{
	self.hidden = NO;
	[self resetHideZoomControlTimer];
}

- (void)hideZoomControl
{
	[self cancelHideZoomControlTimer];
	[self animateToHidden];
}

- (void)cancelHideZoomControlTimer
{
	if (self.hideControlsTimer != nil)
	{
		[self.hideControlsTimer invalidate];
		self.hideControlsTimer = nil;
	}
}

- (void)resetHideZoomControlTimer
{
	[self cancelHideZoomControlTimer];
	
	self.hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:kHideZoomControlDelay
																														target:self
																													selector:@selector(hideZoomControlTimerExpired:)
																													userInfo:nil
																													 repeats:NO];
}

- (void)animateToHidden
{
	[UIView animateWithDuration:0.2
									 animations:^{
										 
										 self.alpha = 0.0;
									 }
									 completion:^(BOOL finished) {
										 
										 self.hidden = YES;
										 self.alpha = 1.0;
									 }];
}

- (void)hideZoomControlTimerExpired:(NSTimer*)timer
{
	self.hideControlsTimer = nil;
	[self animateToHidden];
}

- (void)pinchToZoom:(UIGestureRecognizer*)gestureRecognizer
{
	NSAssert([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]], @"Requires a UIPinchGestureRecognizer");
	
	UIPinchGestureRecognizer* pinchGestureRecognizer = (UIPinchGestureRecognizer*)gestureRecognizer;
	
	if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		self.initialPinchZoomScale = self.zoomScale;
	}
	
	if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan ||
			pinchGestureRecognizer.state == UIGestureRecognizerStateChanged ||
			pinchGestureRecognizer.state == UIGestureRecognizerStateEnded)
	{
		CGFloat scale = self.initialPinchZoomScale * pinchGestureRecognizer.scale;
		self.zoomScale = scale;
		[self sendActionsForControlEvents:UIControlEventValueChanged];
		
		[self showZoomControl];
	}
	
}

@end
