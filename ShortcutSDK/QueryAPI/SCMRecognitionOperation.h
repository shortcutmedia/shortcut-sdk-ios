//
//  SCMRecognitionRequest.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 14/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResponse.h"

/**
 *  An SCMRecognitionOperation handles the submission of an image to the image
 *  recognition service.
 *
 *  @discussion
 *  This is a subclass of NSOperation. After you have initialized and configured
 *  an instance you must kick it off by either calling the SCMRecognitionOperation -start
 *  method on it or by scheduling it in an operation queue.
 *  @see NSOperationQueue -addOperation:
 */
@interface SCMRecognitionOperation : NSOperation

/**
 *  The image to submit to the image recognition service.
 */
@property (nonatomic, strong, readonly) NSData *imageData;

/**
 *  The location where the image was captured.
 */
@property (nonatomic, strong, readonly) CLLocation *location;

/**
 *  The response of the image recognition service.
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
 *  Returns a new query operation instance.
 *
 *  @param imageData The image to submit to the image recognition service.
 "  @param location The location where the image was captured.
 *
 *  @return A new query operation instance.
 */
- (id)initWithImageData:(NSData *)imageData location:(CLLocation *)location;


extern NSString *kSCMRecognitionOperationErrorDomain;
extern int kSCMRecognitionOperationNoMatchingMetadata;

@end
