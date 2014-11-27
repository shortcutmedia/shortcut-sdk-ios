//
//  KSCQueryResponse.m
//  Shortcut
//
//  Created by Severin Schoepke on 20/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCQueryResponse.h"
#import "KSCDictionaryUtils.h"
#import "KSCUUIDUtils.h"

@interface KSCQueryResponse ()

@property (strong, nonatomic) NSDictionary *responseDictionary;

@end

@implementation KSCQueryResponse

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
    NSString* uuid = [KSCDictionaryUtils stringFromDictionary:self.responseDictionary atPath:@"query_id"];
    if (uuid) {
        uuid = [KSCUUIDUtils normalizeUUID:uuid];
    }
    return uuid;
}

- (NSArray *)results
{
    NSMutableArray *usableResults = [[NSMutableArray alloc] init];
    
    NSArray *allResults = [KSCDictionaryUtils arrayFromDictionary:self.responseDictionary atPath:@"results"];
    for (NSDictionary *resultDictionary in allResults) {
        KSCQueryResult *result = [[KSCQueryResult alloc] initWithDictionary:resultDictionary];
        if (result.imageSHA1) {
            if ([result.versions indexOfObject:@(CURRENT_API_VERSION)] != NSNotFound) {
                [usableResults addObject:result];
            }
        }
    }
    return usableResults;
}

@end
