//
//  SCMMockBeacon.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/06/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface SCMMockBeacon : CLBeacon

@property (strong, nonatomic, readwrite) NSUUID *proximityUUID;
@property (strong, nonatomic, readwrite) NSNumber *major;
@property (strong, nonatomic, readwrite) NSNumber *minor;
@property (assign, nonatomic, readwrite) CLProximity proximity;

- (instancetype)initWithProximityUUID:(NSUUID *)uuid
                                major:(NSNumber *)major
                                minor:(NSNumber *)minor
                            proximity:(CLProximity)proximity;

@end
