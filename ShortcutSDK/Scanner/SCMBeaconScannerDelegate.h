//
//  SCMBeaconScannerDelegate.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 11/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class SCMBeaconScanner;

/**
 *  The SCMBeaconScannerDelegate describes a protocol that allows reacting to events
 *  within an SCMBeaconScanner instance.
 *
 *  @see SCMBeaconScanner
 */
@protocol SCMBeaconScannerDelegate <NSObject>

- (void)beaconScanner:(SCMBeaconScanner *)scanner didSelectBeacon:(CLBeacon *)beacon;

@end
