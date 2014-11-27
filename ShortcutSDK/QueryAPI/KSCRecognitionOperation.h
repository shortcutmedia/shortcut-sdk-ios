//
//  KSCRecognitionRequest.h
//  Shortcut
//
//  Created by Severin Schoepke on 14/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "KSCQueryResponse.h"

@interface KSCRecognitionOperation : NSOperation

@property (nonatomic, strong, readonly) CLLocation* location;
@property (nonatomic, strong, readonly) NSData* imageData;
@property (nonatomic, strong, readonly) NSMutableURLRequest* request;
@property (nonatomic, strong, readonly) KSCQueryResponse* queryResponse;
@property (nonatomic, strong, readonly) NSError* error;
@property (nonatomic, readonly) bool closeCamera;

- (id)initWithImageData:(NSData*)imageData location:(CLLocation*)location;

@end
