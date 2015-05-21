//
//  SCMBeaconScannerDelegate.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 11/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResponse.h"

@class SCMBeaconScanner;

/**
 *  The SCMBeaconScannerDelegate describes a protocol that allows reacting to events
 *  within an SCMBeaconScanner instance.
 *
 *  @see SCMBeaconScanner
 */
@protocol SCMBeaconScannerDelegate <NSObject>

/**
 *  This method is called whenever a new beacon is selected as the closest to the scanner.
 *
 *  @discussion
 *  This is basically the "success handler" of a beacon scanner. It is called when a
 *  beacon was detected, successfully ranged and recognized as being the closest to
 *  the device.
 *
 *  @param beaconScanner The beacon scanner instance that selected a beacon.
 *  @param beacon        The beacon that was selected and is closest to the device.
 */
- (void)beaconScanner:(SCMBeaconScanner *)beaconScanner didSelectBeacon:(CLBeacon *)beacon;

@end
