//
//  SCMMockBeacon.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/06/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMMockBeacon.h"
#import <ShortcutSDK/SCMBeaconScanner.h>

@implementation SCMMockBeacon

@synthesize proximityUUID = _proximityUUID;
@synthesize major = _major;
@synthesize minor = _minor;
@synthesize proximity = _proximity;

- (instancetype)initInShortcutRegionWithMajor:(NSNumber *)major minor:(NSNumber *)minor proximity:(CLProximity)proximity
{
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kSCMShortcutRegionUUIDString];
    return [self initWithProximityUUID:proximityUUID major:major minor:minor proximity:proximity];
}

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
