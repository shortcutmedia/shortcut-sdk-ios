//
//  KSCQueryResult.m
//  Shortcut
//
//  Created by Severin Schoepke on 21/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCQueryResult.h"
#import "KSCDictionaryUtils.h"
#import "KSCUUIDUtils.h"

@interface KSCQueryResult ()

@property (strong, nonatomic) NSDictionary *resultDictionary;

@end

@implementation KSCQueryResult

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
    NSString* uuid = [KSCDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"uuid"];
    if (uuid != nil) {
        uuid = [KSCUUIDUtils normalizeUUID:uuid];
    }
    
    return uuid;
}

static NSString* const kImageSHA1Prefix = @"image.sha1:";

- (NSString *)imageSHA1
{
    NSString* recognitionId = [KSCDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"recognitions/id"];
    if ([recognitionId hasPrefix:kImageSHA1Prefix]) {
        return [recognitionId stringByReplacingOccurrencesOfString:kImageSHA1Prefix withString:@""];
    } else {
        return nil;
    }
}

- (NSNumber *)score
{
    return [KSCDictionaryUtils numberFromDictionary:self.resultDictionary atPath:@"recognitions/score"];
}

- (NSString *)title
{
    NSString* title = [KSCDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"title"];
    NSDictionary* titleLocalizations = [KSCDictionaryUtils dictionaryFromDictionary:self.currentMetadata atPath:@"title"];
    if (titleLocalizations) {
        NSString* language = [[NSLocale preferredLanguages] firstObject];
        NSString* localizedTitle = [KSCDictionaryUtils stringFromDictionary:titleLocalizations atPath:language];
        if (localizedTitle.length > 0) {
            title = localizedTitle;
        }
    }
    
    return title;
}

- (NSString *)subtitle
{
    NSString* subtitle = [KSCDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"subtitle"];
    NSDictionary* subtitleLocalizations = [KSCDictionaryUtils dictionaryFromDictionary:self.currentMetadata atPath:@"subtitle"];
    if (subtitleLocalizations) {
        NSString* language = [[NSLocale preferredLanguages] firstObject];
        NSString* localizedSubtitle = [KSCDictionaryUtils stringFromDictionary:subtitleLocalizations atPath:language];
        if (localizedSubtitle.length > 0) {
            subtitle = localizedSubtitle;
        }
    }
    
    return subtitle;
}

- (NSString *)mediumType
{
    return [KSCDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"kind"];
}

- (NSString *)responseTarget
{
    return [[KSCDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"response/target"] lowercaseString];
}

- (NSString *)responseContent
{
    return [KSCDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"response/content"];
}

- (NSString *)thumbnailURL
{
    return [KSCDictionaryUtils stringFromDictionary:self.currentMetadata atPath:@"thumbnail_url"];
}

- (NSArray *)versions
{
    NSArray *array = [KSCDictionaryUtils arrayFromDictionary:self.resultDictionary atPath:@"metadata"];
    NSMutableArray *foundVersions = [NSMutableArray new];
    for (NSDictionary *dict in array) {
        NSString *versionString = [dict valueForKey:@"version"];
        NSNumber *version = [NSNumber numberWithInt:versionString.intValue];
        [foundVersions addObject:version];
    }
    return foundVersions;
}

#pragma mark - Private

- (NSDictionary*)currentMetadata
{
    NSArray *candidates = [KSCDictionaryUtils arrayFromDictionary:self.resultDictionary atPath:@"metadata"];
    for (NSDictionary *dict in candidates)
    {
        if ([[KSCDictionaryUtils numberFromDictionary:dict atPath:@"version"] isEqual:@(CURRENT_API_VERSION)]) {
            return dict;
        }
    }
    return NULL;
}

@end
