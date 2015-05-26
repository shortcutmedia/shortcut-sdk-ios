//
//  SCMBeaconHandler.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 18/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCMBeaconHandlerDelegate.h"

/**
 *  A beacon handler provides a nice interface for displaying items based on nearby iBeacons.
 *
 *  @discussion
 *  An SCMBeaconHandler instance uses a SCMBeaconScanner instance to scan for iBeacons and match
 *  them to items.
 *  It further handles the display of notifications to the user when a beacon was matched while
 *  the app is in the background.
 *
 *  Use this if you want an easy and complete solution to display items based on nearby beacons.
 *  If you want more control over the beacon scanning and lookup process, then have a look at
 *  the SCMBeaconScanner class and the SCMBeaconLookupOperation class.
 *
 *  @see SCMBeaconScanner
 *  @see SCMBeaconLookupOperation
 */
@interface SCMBeaconHandler : NSObject

/**
 *  The delegate of the beacon handler.
 *
 *  @discussion
 *  The delegate gets notified on important events within the handler (e.g. beacon recognized).
 *
 *  @see SCMBeaconHandlerDelegate
 */
@property (nonatomic, unsafe_unretained, readwrite) id<SCMBeaconHandlerDelegate> delegate;

/**
 *  This method initializes a new beacon handler and sets its delegate.
 *
 *  @param delegate The delegate of the new beacon handler instance.
 */
- (instancetype)initWithDelegate:(id<SCMBeaconHandlerDelegate>)delegate;

/**
 *  This method starts the handler.
 *
 *  @discussion
 *  This method sets up and starts an SCMBeaconScanner instance. It acts as its delegate and starts
 *  responding to its events (e.g. looking up beacons, displaying notifications to the user).
 *
 *  @see SCMBeaconScanner -start
 *  @see -stop
 */
- (void)start;

/**
 *  This method stops the handler.
 *
 *  @discussion
 *  This method stops the underlying SCMBeaconScanner instance which stops monitoring for beacons
 *  completely, so do NOT stop the handler if you want your app to look for beacons when in the
 *  background.
 *
 *  @see SCMBeaconScanner -stop
 *  @see -start
 */
- (void)stop;

/**
 *  This method returns YES if the handler is running.
 */
- (BOOL)isRunning;

/**
 *  This method triggers the display of items based on the given notification if needed.
 *
 *  @discussion
 *  Since there is no way in iOS for an arbitrary object to get notified about an incoming
 *  notification, notifications have to be passed on to the handler instance manually using this
 *  method.
 *  Call it from your app delegate in the method -application:didReceiveLocalNotification:
 */
- (void)handleNotification:(UILocalNotification *)notification;

@end
