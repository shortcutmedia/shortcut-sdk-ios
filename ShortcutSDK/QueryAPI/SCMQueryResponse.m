//
//  SCMQueryResponse.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 20/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMQueryResponse.h"
#import "SCMDictionaryUtils.h"
#import "SCMUUIDUtils.h"

@interface SCMQueryResponse ()

@property (strong, nonatomic) NSDictionary *responseDictionary;

@end

@implementation SCMQueryResponse

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.responseDictionary = dictionary;
    }
    return self;
}

- (NSString *)queryUUID
{
    NSString *uuid = [SCMDictionaryUtils stringFromDictionary:self.responseDictionary atPath:@"query_id"];
    if (uuid) {
        uuid = [SCMUUIDUtils normalizeUUID:uuid];
    }
    return uuid;
}

- (NSArray *)results
{
    NSArray *usableResults = [self.allResults filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
        SCMQueryResult *result = (SCMQueryResult *)obj;
        return [result hasCurrentMetadata];
    }]];
    
    return usableResults;
}

- (BOOL)hasCurrentMetadata
{
    BOOL result;
    
    if (self.allResults.count > 0) {
        SCMQueryResult *firstResult = [self.allResults firstObject];
        result = firstResult.hasCurrentMetadata;
    } else {
        result = YES;
    }
    
    return result;
}

#pragma mark - Helpers

- (NSArray *)allResults
{
    NSMutableArray *allResults = [NSMutableArray array];
    for (NSDictionary *dict in [SCMDictionaryUtils arrayFromDictionary:self.responseDictionary atPath:@"results"]) {
        SCMQueryResult *result = [[SCMQueryResult alloc] initWithDictionary:dict];
        if (result) {
            [allResults addObject:result];
        }
    }
    return allResults;
}

@end
