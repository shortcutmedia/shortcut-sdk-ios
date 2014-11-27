//
//  KSCQueryResponse.h
//  Shortcut
//
//  Created by Severin Schoepke on 20/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSCQueryResult.h"

@interface KSCQueryResponse : NSObject

@property (strong, nonatomic, readonly) NSString *queryUUID;
@property (strong, nonatomic, readonly) NSArray *results;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
