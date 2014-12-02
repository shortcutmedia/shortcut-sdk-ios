//
//  KSCSDKConfig.m
//  Shortcut
//
//  Created by Severin Schoepke on 17/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCSDKConfig.h"

NSString* const kDefaultQueryServerAddress = @"query-api.kooaba.com";
NSString* const kDefaultItemServerAddress = @"shortcut-service.shortcutmedia.com";
NSString* const kDefaultLocalizationTable = @"Localizable";

@implementation KSCSDKConfig

#pragma mark - Properties (default values)

- (NSString *)localizationTable
{
    if (!_localizationTable) {
        _localizationTable = kDefaultLocalizationTable;
    }
    return _localizationTable;
}

- (NSBundle *)localizationTableBundle
{
    if (!_localizationTableBundle) {
        _localizationTableBundle = [NSBundle mainBundle];
    }
    return _localizationTableBundle;
}

- (NSString *)queryServerAddress
{
    if (!_queryServerAddress) {
        _queryServerAddress = kDefaultQueryServerAddress;
    }
    return _queryServerAddress;
}

- (NSString *)itemServerAddress
{
    if (!_itemServerAddress) {
        _itemServerAddress = kDefaultItemServerAddress;
    }
    return _itemServerAddress;
}

#pragma mark - Singleton instance

+ (instancetype)sharedConfig
{
    static KSCSDKConfig* config = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[self alloc] init];
    });
    
    return config;
}

#pragma mark - Other

+ (NSBundle *)SDKBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"ShortcutSDK.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

@end
