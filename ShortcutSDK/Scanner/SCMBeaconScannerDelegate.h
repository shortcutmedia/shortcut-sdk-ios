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
 *  This method is called whenever a new beacon is detected to be the closest to the scanner.
 *
 *  @discussion
 *  This is basically the "success handler" of a beacon scanner. It is called when a
 *  beacon was detected, successfully ranged and recognized as being the closest to
 *  the device.
 *
 *  @param beaconScanner The beacon scanner instance whose closest beacon changed.
 *  @param beacon        The beacon that is now closest to the device.
 */
- (void)beaconScanner:(SCMBeaconScanner *)beaconScanner closestBeaconChanged:(CLBeacon *)beacon;

/**
 *  This method is called whenever an error is encountered by the scanner.
 *
 *  @discussion
 *  This is basically the "error handler" of a beacon scanner. It is called whenever an error
 *  is encountered.
 *
 *  Errors to look out for are:
 *  * kCLErrorDomain/kCLErrorRegionMonitoringFailure: Bluetooth turned off
 *  * kCLErrorDomain/kCLErrorRangingUnavailable:      Bluetooth turned off
 *  * kCLErrorDomain/kCLErrorRegionMonitoringDenied:  No "Always" access for Location Services
 *
 *  @param beaconScanner The beacon scanner instance that encountered an error.
 *  @param error         The error that occured.
 */
- (void)beaconScanner:(SCMBeaconScanner *)beaconScanner didEncounterError:(NSError *)error;

@end
