//
//  SCMMockBeacon.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/06/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMMockBeacon.h"

@implementation SCMMockBeacon

@synthesize proximityUUID = _proximityUUID;
@synthesize major = _major;
@synthesize minor = _minor;
@synthesize proximity = _proximity;

- (instancetype)initWithProximityUUID:(NSUUID *)uuid major:(NSNumber *)major minor:(NSNumber *)minor proximity:(CLProximity)proximity
{
    if (self = [super init]) {
        self.proximityUUID = uuid;
        self.major         = major;
        self.minor         = minor;
        self.proximity     = proximity;
    }
    
    return self;
}

- (NSUUID *)proximityUUID
{
    return _proximityUUID;
}

- (NSNumber *)major
{
    return _major;
}

- (NSNumber *)minor
{
    return _minor;
}

- (CLProximity)proximity
{
    return _proximity;
}

@end
