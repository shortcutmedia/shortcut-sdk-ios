//
//  SCMMotionDetector.h
//  ShortcutSDK
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SCMMotionDetector : NSObject

// The amount of total rotation required to consider that the device is moving.
@property (nonatomic, assign, readwrite) double rotationThreshold;

// The amount of total acceleration required to consider that the device is moving.
@property (nonatomic, assign, readwrite) double accelerationThreshold;

// YES, if the device is moving (rotating or accelerating). Observable.
@property (nonatomic, assign, readonly) BOOL moving;

- (BOOL)canDetectDeviceMotion;
- (NSTimeInterval)timeIntervalSinceLastMotionDetected;
- (void)startDetectingMotion;
- (void)stopDetectingMotion;

@end
