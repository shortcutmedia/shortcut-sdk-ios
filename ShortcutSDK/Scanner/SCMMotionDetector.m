//
//  SCMMotionDetector.m
//  Shortcut
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "SCMMotionDetector.h"
#import <CoreMotion/CoreMotion.h>


// static const double kFilteringFactor = 0.1;
static const double kAccelerometerUpdateFrequency = 30.0;		// n times per second
static const double kAccelerometerCutoffFrequency = 5.0;		// value taken from AccelerometerGraph demo code

@interface SCMMotionDetector (/* Private */)

@property (nonatomic, assign, readwrite) BOOL moving;
@property (nonatomic, strong, readwrite) CMMotionManager* deviceMotionManager;
@property (nonatomic, strong, readwrite) NSOperationQueue* deviceMotionQueue;
@property (nonatomic, strong, readwrite) NSDate* lastStillTimestamp;
@property (nonatomic, assign, readwrite) double accelerationX;
@property (nonatomic, assign, readwrite) double accelerationY;
@property (nonatomic, assign, readwrite) double accelerationZ;
@property (nonatomic, assign, readwrite) double lastAccelerationX;
@property (nonatomic, assign, readwrite) double lastAccelerationY;
@property (nonatomic, assign, readwrite) double lastAccelerationZ;
@property (nonatomic, assign, readwrite) double highPassAlpha;

- (BOOL)isAccelerating;
- (BOOL)isRotating:(CMRotationRate)rotation;
- (void)processDeviceMotionUpdate:(CMDeviceMotion*)motion;
- (void)processDeviceAccelerationUpdate:(CMAccelerometerData*)accelerometerData;

@end


@implementation SCMMotionDetector

@synthesize rotationThreshold;
@synthesize accelerationThreshold;
@synthesize moving;
@synthesize deviceMotionManager;
@synthesize deviceMotionQueue;
@synthesize lastStillTimestamp;
@synthesize accelerationX;
@synthesize accelerationY;
@synthesize accelerationZ;
@synthesize lastAccelerationX;
@synthesize lastAccelerationY;
@synthesize lastAccelerationZ;
@synthesize highPassAlpha;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.deviceMotionManager = [[CMMotionManager alloc] init];
		self.deviceMotionQueue = [[NSOperationQueue alloc] init];
		
		self.rotationThreshold = 0.2;
		self.accelerationThreshold = 0.1;
	}
	
	return self;
}

- (BOOL)canDetectDeviceMotion
{
	return self.deviceMotionManager.deviceMotionAvailable;
}

- (void)startDetectingMotion
{
	self.lastStillTimestamp = nil;
	
	DebugLog(@"deviceMotionAvailable %@", self.deviceMotionManager.deviceMotionAvailable ? @"YES" : @"NO");

	if (self.deviceMotionManager.deviceMotionAvailable)
	{
		self.deviceMotionManager.deviceMotionUpdateInterval = 0.025;
		[self.deviceMotionManager startDeviceMotionUpdatesToQueue:self.deviceMotionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
			
			if (error == nil)
			{
				[self processDeviceMotionUpdate:motion];
			}
			else
			{
				// From the documentation: "If an error occurs, you should stop gyroscope updates and inform the user of the problem."
				// Weird.
				[self stopDetectingMotion];
			}
			
		}];
	}
	else
	{
		// This needs work. It is too sensitive to gravity and cannot properly detect motion with just an accelerometer.
		self.moving = NO;
		self.accelerationX = 0.0;
		self.accelerationY = 0.0;
		self.accelerationZ = 0.0;
		self.lastAccelerationX = 0.0;
		self.lastAccelerationY = 0.0;
		self.lastAccelerationZ = 0.0;
		
		self.deviceMotionManager.accelerometerUpdateInterval = 1.0 / kAccelerometerUpdateFrequency;
		double dt = 1.0 / kAccelerometerUpdateFrequency;
		double rc = 1.0 / kAccelerometerCutoffFrequency;
		self.highPassAlpha = rc / (dt + rc);
		[self.deviceMotionManager startAccelerometerUpdatesToQueue:self.deviceMotionQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
			
			if (error == nil)
			{
				[self processDeviceAccelerationUpdate:accelerometerData];
			}
			else
			{
				// From the documentation: If an error occurs, you should stop accelerometer updates and inform the user of the problem.
				[self stopDetectingMotion];
			}
		}];
	}
}

- (void)stopDetectingMotion
{
	if (self.deviceMotionManager.deviceMotionAvailable)
	{
		[self.deviceMotionManager stopDeviceMotionUpdates];
	}
	else
	{
		[self.deviceMotionManager stopAccelerometerUpdates];
	}
}

- (BOOL)isAccelerating
{
	double totalAcceleration = sqrt((self.accelerationX * self.accelerationX) + (self.accelerationY * self.accelerationY) + (self.accelerationZ * self.accelerationZ));

	BOOL accelerating = NO;
	if (totalAcceleration > self.accelerationThreshold)
	{
		accelerating = YES;
	}
//	DebugLog(@"acceleration: %+1.2f, %+1.2f, %+1.2f (%+1.2f) %@", self.accelerationX, self.accelerationY, self.accelerationZ, totalAcceleration, accelerating ? @"YES" : @"NO");
	
	return accelerating;
}

- (BOOL)isRotating:(CMRotationRate)rotation
{
	double totalRotation = sqrt((rotation.x * rotation.x) + (rotation.y * rotation.y) + (rotation.z * rotation.z));
	
	BOOL rotating = NO;
	if (totalRotation > self.rotationThreshold)
	{
		rotating = YES;
	}
//	DebugLog(@"rotating: %f, %f, %f (%f) %@", rotation.x, rotation.y, rotation.z, totalRotation, rotating ? @"YES" : @"NO");
	
	return rotating;
}

- (void)processDeviceMotionUpdate:(CMDeviceMotion*)motion
{
	NSDate* now = [NSDate date];
	BOOL rotating = [self isRotating:motion.rotationRate];
	
	self.accelerationX = motion.userAcceleration.x;
	self.accelerationY = motion.userAcceleration.y;
	self.accelerationZ = motion.userAcceleration.z;
	
	BOOL accelerating = [self isAccelerating];
	BOOL currentlyMoving = (rotating | accelerating);
	if (currentlyMoving != self.moving)
	{
		// Only set this when the value changes so that observers aren't bombarded with updates.
		self.moving = currentlyMoving;
	}

	if (currentlyMoving)
	{
		self.lastStillTimestamp = nil;
	}
	else if (self.lastStillTimestamp == nil)
	{
		self.lastStillTimestamp = now;
	}
	
//	DebugLog(@"moving: %@ (%f)", self.moving ? @"YES" : @"NO", [self timeIntervalSinceLastMotionDetected]);
}

- (void)processDeviceAccelerationUpdate:(CMAccelerometerData*)accelerometerData
{
	NSDate* now = [NSDate date];

//	DebugLog(@"before: %+1.1f, %+1.1f, %+1.1f (%+1.1f, %+1.1f, %+1.1f)", self.accelerationX, self.accelerationY, self.accelerationZ,
//					 accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z);

	double alpha = self.highPassAlpha;
	self.accelerationX = alpha * (self.accelerationX + accelerometerData.acceleration.x - self.lastAccelerationX);
	self.accelerationY = alpha * (self.accelerationY + accelerometerData.acceleration.y - self.lastAccelerationY);
	self.accelerationZ = alpha * (self.accelerationZ + accelerometerData.acceleration.z - self.lastAccelerationZ);
	self.lastAccelerationX = accelerometerData.acceleration.x;
	self.lastAccelerationY = accelerometerData.acceleration.y;
	self.lastAccelerationZ = accelerometerData.acceleration.z;

//	DebugLog(@" after: %+1.1f, %+1.1f, %+1.1f", self.accelerationX, self.accelerationY, self.accelerationZ);
	
	BOOL currentlyMoving = [self isAccelerating];
	if (currentlyMoving != self.moving)
	{
		// Only set this when the value changes so that observers aren't bombarded with updates.
		self.moving = currentlyMoving;
	}

	if (currentlyMoving)
	{
		self.lastStillTimestamp = nil;
	}
	else if (self.lastStillTimestamp == nil)
	{
		self.lastStillTimestamp = now;
	}
}

- (NSTimeInterval)timeIntervalSinceLastMotionDetected
{
	if (self.lastStillTimestamp == nil)
	{
		return 0.0;
	}
	
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.lastStillTimestamp];
	return interval;
}

@end
