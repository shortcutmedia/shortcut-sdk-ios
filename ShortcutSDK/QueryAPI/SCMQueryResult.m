//
//  SCMQueryResult.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 21/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMQueryResult.h"
#import "SCMDictionaryUtils.h"
#import "SCMUUIDUtils.h"

@interface SCMQueryResult ()

@property (strong, nonatomic) NSDictionary *resultDictionary;

@end

@implementation SCMQueryResult

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.resultDictionary = dictionary;
    }
    return self;
}

- (NSString *)uuid
{
    NSString *uuid = [SCMDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"uuid"];
    if (uuid != nil) {
        uuid = [SCMUUIDUtils normalizeUUID:uuid];
    }
    
    return uuid;
}

static NSString *const kImageSHA1Prefix = @"image.sha1:";

- (NSString *)imageSHA1
{
    NSString *recognitionId = [SCMDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"recognitions/id"];
    if ([recognitionId hasPrefix:kImageSHA1Prefix]) {
        return [recognitionId stringByReplacingOccurrencesOfString:kImageSHA1Prefix withString:@""];
    } else {
        return nil;
    }
}

- (NSNumber *)score
{
    return [SCMDictionaryUtils numberFromDictionary:self.resultDictionary atPath:@"recognitions/score"];
}

- (NSString *)title
{
    NSString *title = [SCMDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"title"];
    NSDictionary *titleLocalizations = [SCMDictionaryUtils dictionaryFromDictionary:self.currentMetadata atPath:@"title"];
    if (titleLocalizations) {
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        NSString *localizedTitle = [SCMDictionaryUtils stringFromDictionary:titleLocalizations atPath:language];
        if (localizedTitle.length > 0) {
            title = localizedTitle;
        }
    }
    
    return title;
}

- (NSString *)subtitle
{
    NSString *subtitle = [SCMDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"subtitle"];
    NSDictionary *subtitleLocalizations = [SCMDictionaryUtils dictionaryFromDictionary:self.currentMetadata atPath:@"subtitle"];
    if (subtitleLocalizations) {
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        NSString *localizedSubtitle = [SCMDictionaryUtils stringFromDictionary:subtitleLocalizations atPath:language];
        if (localizedSubtitle.length > 0) {
            subtitle = localizedSubtitle;
        }
    }
    
    return subtitle;
}

- (NSString *)mediumType
{
    return [SCMDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"kind"];
}

- (NSString *)responseTarget
{
    return [[SCMDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"response/target"] lowercaseString];
}

- (NSString *)responseContent
{
    return [SCMDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"response/content"];
}

- (NSString *)thumbnailURL
{
    return [SCMDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"thumbnail_url"];
}

- (NSArray *)versions
{
    NSArray *array = [SCMDictionaryUtils arrayFromDictionary:self.resultDictionary atPath:@"metadata"];
    NSMutableArray *foundVersions = [NSMutableArray new];
    for (NSDictionary *dict in array) {
        NSString *versionString = [dict valueForKey:@"version"];
        NSNumber *version = [NSNumber numberWithInt:versionString.intValue];
        [foundVersions addObject:version];
    }
    return foundVersions;
}

#pragma mark - Private

- (NSDictionary *)currentMetadata
{
    NSArray *candidates = [SCMDictionaryUtils arrayFromDictionary:self.resultDictionary atPath:@"metadata"];
    for (NSDictionary *dict in candidates) {
        if ([[SCMDictionaryUtils numberFromDictionary:dict atPath:@"version"] isEqual:@(CURRENT_API_VERSION)]) {
            return dict;
        }
    }
    return NULL;
}

@end
