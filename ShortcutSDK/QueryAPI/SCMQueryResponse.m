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
    NSMutableArray *usableResults = [[NSMutableArray alloc] init];
    
    NSArray *allResults = [SCMDictionaryUtils arrayFromDictionary:self.responseDictionary atPath:@"results"];
    for (NSDictionary *resultDictionary in allResults) {
        SCMQueryResult *result = [[SCMQueryResult alloc] initWithDictionary:resultDictionary];
        if (result.imageSHA1) {
            if ([result.metadataVersions indexOfObject:@(CURRENT_API_VERSION)] != NSNotFound) {
                [usableResults addObject:result];
            }
        }
    }
    return usableResults;
}

- (BOOL)hasCurrentMetadata
{
    BOOL result = NO;
    
    NSArray *allResults = [SCMDictionaryUtils arrayFromDictionary:self.responseDictionary atPath:@"results"];
    if (allResults.count > 0) {
        SCMQueryResult *firstResult = [[SCMQueryResult alloc] initWithDictionary:[allResults firstObject]];
        if (firstResult.metadataVersions.count > 0) {
            for (NSNumber *number in firstResult.metadataVersions) {
                if (number.intValue == CURRENT_API_VERSION) {
                    result = YES;
                    break;
                }
            }
        } else {
            result = YES;
        }
    } else {
        result = YES;
    }
    
    return result;
}

@end
