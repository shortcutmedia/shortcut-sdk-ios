//
//  SCMBeaconHandlerDelegate.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 18/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResult.h"

@class SCMBeaconHandler;

/**
 *  The SCMBeaconHandlerDelegate describes a protocol that allows reacting to events
 *  within an SCMBeaconHandler instance.
 *
 *  @see SCMBeaconHandler
 */
@protocol SCMBeaconHandlerDelegate <NSObject>

/**
 *  This method is called whenever a beacon handler successfully recognizes a beacon.
 *
 *  @discussion
 *  This is basically the "success handler" of a beacon handler. It is called when a
 *  beacon was successfully mapped to an item in the beacon lookup service.
 *  If a beacon was recognized in the background, the handler displays a notification
 *  and this method is only invoked after the user taps on the notification.
 *
 *  A typical action that you should implement/trigger in this method is the display
 *  of the matched item(s).
 *
 *  @param beaconHandler    The beacon handler instance that recognized an item.
 *  @param result           The item that was recognized.
 *  @param fromNotification The flag indicates whether the handler was invoked directly
 *                          or only after the user tapped on a notification about the item.
 */
- (void)beaconHandler:(SCMBeaconHandler *)beaconHandler recognizedItem:(SCMQueryResult *)result fromNotification:(BOOL)fromNotification;

/**
 *  This method is called whenever a beacon handler loses contact with all nearby beacons.
 *
 *  @discussion
 *  It is called when no beacon is nearby or no beacon could be mapped to an item in the
 *  beacon lookup service.
 *
 *  A typical action that you should implement/trigger in this method is the dismissal of
 *  any UI element indicating a nearby item.
 *
 *  This method is only invoked if there was a beacon successfully recognized before by the
 *  handler instance.
 *
 *  @param beaconHandler The beacon handler instance that recognized no items.
 */
- (void)beaconHandlerLostContactToItems:(SCMBeaconHandler *)beaconHandler;

@end

