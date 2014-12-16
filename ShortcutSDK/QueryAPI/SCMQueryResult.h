//
//  SCMQueryResult.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 21/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  An SCMQueryResult object represents an item in the image recognition service
 *  and its match to the submitted image.
 */
@interface SCMQueryResult : NSObject

/**
 *  The UUID of the item.
 */
@property (strong, nonatomic, readonly) NSString *uuid;

/**
 *  The SHA1 hash of the stored image of the item.
 *
 *  @discussion
 *  An item can have multiple images associated in the image recognition service.
 *  This SHA1 hash can be used to distinguish the different images.
 */
@property (strong, nonatomic, readonly) NSString *imageSHA1;

/**
 *  The likelihood of a match between the item and the submitted image.
 *
 *  @discussion
 *  The match score is represented as a floating point number ranging from 0.0 to 1.0.
 */
@property (strong, nonatomic, readonly) NSNumber *score;

/**
 *  The title of the item.
 */
@property (strong, nonatomic, readonly) NSString *title;

/**
 *  The subtitle of the item.
 */
@property (strong, nonatomic, readonly) NSString *subtitle;

/**
 *  The medium type of the item.
 *
 *  TODO: list of possible values...
 */
@property (strong, nonatomic, readonly) NSString *mediumType;

/**
 *  This value describes the response type of the item.
 *
 *  @discussion
 *  The response target describes special response types of items. The default
 *  value is nil, which just means that the item should be displayed in the
 *  normal result page.
 *  @see SCMQueryResultViewController
 *
 *  The following special responses are also available:
 *
 *  - "web": This means that the item describes an external web page which should
 *           be displayed instead of the result page. The URL of the web page is
 *           stored in the responseContent property.
 *
 *  @see SCMQueryResult responseContent
 */
@property (strong, nonatomic, readonly) NSString *responseTarget;

/**
 *  This contains additional metadata specific to the response target.
 *
 *  @see SCMQueryResult responseTarget
 */
@property (strong, nonatomic, readonly) NSString *responseContent;

/**
 *  URL of a thumbnail image of the item.
 */
@property (strong, nonatomic, readonly) NSString *thumbnailURL;

/**
 *  Array containing all API version numbers supported by this result.
 *
 *  @discussion
 *  This is for internal use only.
 */
@property (strong, nonatomic, readonly) NSArray *metadataVersions;

/**
 *  Returns a new instance populated with data from the dictionary.
 *
 *  @param dictionary The raw data describing the query result.
 *
 *  @return A new query result instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
