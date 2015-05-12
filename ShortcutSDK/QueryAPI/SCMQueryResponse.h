//
//  SCMQueryResponse.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 20/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCMQueryResult.h"

/**
 *  An SCMQueryResponse object wraps a response from the image recognition service.
 *
 *  @discussion
 *  A query response can contain zero or more query results, each describing a different
 *  item that matches the submitted image. Each query result has a score property that
 *  describes the likelihood of its item matching the image.
 */
@interface SCMQueryResponse : NSObject

/**
 *  The UUID of the query sent to the image recognition service.
 *
 *  @discussion
 *  If you want to store complete query responses you can use this value
 *  as identifier of a query.
 */
@property (strong, nonatomic, readonly) NSString *queryUUID;

/**
 *  All results matching the query.
 *
 *  @discussion
 *  This is an NSArray instance that contains zero or more SCMQueryResult
 *  instances.
 *
 *  @see SCMQueryResult
 */
@property (strong, nonatomic, readonly) NSArray *results;

/**
 *  Returns true if the current SDK version understands the metadata provided in the response.
 *
 *  @discussion
 *  This is for internal use only.
 */
@property (nonatomic, readonly) BOOL hasCurrentMetadata;

/**
 *  Returns a new instance populated with data from the dictionary.
 *
 *  @param dictionary The raw data describing the query response.
 *
 *  @return A new query response instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;


extern NSString *kSCMQueryResponseErrorDomain;
extern int kSCMQueryResponseNoMatchingMetadata;

@end
