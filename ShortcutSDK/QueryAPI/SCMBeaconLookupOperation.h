//
//  SCMBeaconLookupOperation.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 12/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMHTTPOperation.h"
#import "SCMQueryResponse.h"

/**
 *  An SCMBeaconLookupOperation handles the submission of beacon data to the beacon
 *  lookup service.
 *
 *  @discussion
 *  This is a subclass of NSOperation. After you have initialized and configured
 *  an instance you must kick it off by either calling the SCMBeaconLookupOperation -start
 *  method on it or by scheduling it in an operation queue.
 *  @see NSOperationQueue -addOperation:
 */
@interface SCMBeaconLookupOperation : SCMHTTPOperation

/**
 *  The beacon to submit to the beacon lookup service.
 */
@property (nonatomic, strong, readonly) CLBeacon *beacon;

/**
 *  The response of the beacon lookup service.
 *
 *  @discussion
 *  This is only populated after the operation finished successfully.
 */
@property (nonatomic, strong, readonly) SCMQueryResponse *queryResponse;

/**
 *  The (potential) error that occurred during the operation.
 *
 *  @discussion
 *  This is only populated after to operation finished with a failure.
 */
@property (nonatomic, strong, readonly) NSError *error;

/**
 *  Returns a new lookup operation instance.
 *
 *  @param beacon The beacon to submit to the beacon lookup service.
 *
 *  @return A new lookup operation instance.
 */
- (id)initWithBeacon:(CLBeacon *)beacon;

@end
