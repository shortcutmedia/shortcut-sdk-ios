//
//  KSCQueryResult.h
//  Shortcut
//
//  Created by Severin Schoepke on 21/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCQueryResult : NSObject

@property (strong, nonatomic, readonly) NSString *uuid;
@property (strong, nonatomic, readonly) NSString *imageSHA1;
@property (strong, nonatomic, readonly) NSNumber *score;
@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *subtitle;
@property (strong, nonatomic, readonly) NSString *mediumType;
@property (strong, nonatomic, readonly) NSString *responseTarget;
@property (strong, nonatomic, readonly) NSString *responseContent;
@property (strong, nonatomic, readonly) NSString *thumbnailURL;
@property (strong, nonatomic, readonly) NSArray *versions;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
