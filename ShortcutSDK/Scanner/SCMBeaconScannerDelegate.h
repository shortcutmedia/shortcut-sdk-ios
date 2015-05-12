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
 *  This method is called whenever a beacon scanner successfully recognizes a beacon.
 *
 *  @discussion
 *  This is basically the "success handler" of a beacon scanner. It is called when a
 *  beacon was successfully mapped to an item in the beacon lookup service.
 *
 *  A typical action that you should implement/trigger in this method is the display
 *  of the matched item(s).
 *
 *  @param beaconScanner The beacon scanner instance that recognized an item.
 *  @param response      The response from the beacon lookup service describing the recognized item(s).
 *  @param beacon        The beacon that was recognized.
 */
- (void)beaconScanner:(SCMBeaconScanner *)beaconScanner recognizedQuery:(SCMQueryResponse *)response fromBeacon:(CLBeacon *)beacon;

- (void)beaconScanner:(SCMBeaconScanner *)beaconScanner didSelectBeacon:(CLBeacon *)beacon;

@end
