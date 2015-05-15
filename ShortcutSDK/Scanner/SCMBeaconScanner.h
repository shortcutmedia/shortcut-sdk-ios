//
//  SCMBeaconScanner.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 11/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCMBeaconScannerDelegate.h"

/**
 *  A SCMBeaconScanner scans the surroundings for iBeacons.
 *
 *  @discussion
 *  A SCMBeaconScanner uses a CLLocationManager instance to look out for iBeacons. It detects
 *  only beacons in the predefined Shortcut beacon region by default.
 *
 *  Important events that happen within the scanner (e.g. beacon recognized) are communicated to
 *  the scanner's delegate. This delegate is the main means of interaction with the
 *  scanner.
 *
 *  The scanner works when the app is in the background and even when it is terminated: it gets
 *  triggered by the system when a matching beacon is nearby and it handles this beacon just as
 *  it would do when the app is in the foreground (all relevant methods on the delegate are
 *  triggered correctly).
 *
 *  The scanner prompts the user for all necessary permissions when it is started for the first
 *  time.
 *
 *  @warning
 *  The scanner only works correctly if the user has allowed "Always" access to location services
 *  for the app. It also does not work when Bluetooth is disabled on the device.
 *
 *  @see SCMBeaconScannerDelegate
 *  @see CLLocationManager
 */
@interface SCMBeaconScanner : NSObject

/**
 *  The delegate of the beacon scanner.
 *
 *  @discussion
 *  The delegate gets notified on important events within the scanner (e.g. beacon recognized).
 *
 *  @see SCMBeaconScannerDelegate
 */
@property (nonatomic, unsafe_unretained, readwrite) id<SCMBeaconScannerDelegate> delegate;

/**
 *  This method starts the scanner.
 *
 *  @discussion
 *  The scanner is idle when not started and only looks out for beacons after it is started. Therefore
 *  it is necessary to start it once it has been configured properly.
 *
 *  @see -stop
 */
- (void)start;

/**
 *  This method stops the scanner.
 *
 *  @discussion
 *  When stopped the scanner is in an idle state and does not react to beacon events. This is also true
 *  for background monitoring, so do NOT stop the scanner if you want your app to look for beacons when
 *  in the background.
 *
 *  @see -start
 */
- (void)stop;

@end
