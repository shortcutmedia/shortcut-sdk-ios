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
@property (strong, nonatomic) NSDictionary *metadataDictionary;
@property (strong, nonatomic) NSDictionary *currentMetadata;

@end

@implementation SCMQueryResult

#pragma mark - Properties

@synthesize currentMetadata = _currentMetadata;


- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.resultDictionary = dictionary;
        self.currentMetadata = NULL;
        NSString *applicationMetadata = [SCMDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"target_data/application_metadata"];
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:applicationMetadata options:0];
        self.metadataDictionary = [NSJSONSerialization JSONObjectWithData:decodedData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:NULL];
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
    NSString *recognitionId = [SCMDictionaryUtils stringFromDictionary:[self currentMetadata] atPath:@"response/content"];
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
        NSString *language = [self shortLanguage];
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
        NSString *language = [self shortLanguage];
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

- (NSArray *)metadataVersions
{
    NSMutableArray *foundVersions = [NSMutableArray new];
    for (NSDictionary *dict in self.metadataDictionary) {
        NSString *versionString = [dict valueForKey:@"version"];
        NSNumber *version = [NSNumber numberWithInt:versionString.intValue];
        [foundVersions addObject:version];
    }
    return foundVersions;
}

#pragma mark - Private

- (NSDictionary *)currentMetadata
{
    if (!_currentMetadata) {
        NSString *applicationMetadata = [SCMDictionaryUtils stringFromDictionary:self.resultDictionary atPath:@"target_data/application_metadata"];
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:applicationMetadata options:0];
        self.metadataDictionary = [NSJSONSerialization JSONObjectWithData:decodedData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:NULL];
        
        for (NSDictionary *dict in self.metadataDictionary) {
            if ([[SCMDictionaryUtils numberFromDictionary:dict atPath:@"version"] isEqual:@(QUERY_API_METADATA_VERSION)]) {
                _currentMetadata = dict;
                break;
            }
        }
    }
    
    return _currentMetadata;
}

- (NSString *)shortLanguage {
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if (language) {
        language = [[language componentsSeparatedByString:@"-"] firstObject];
    }
    return language;
}

@end
