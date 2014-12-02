//
//  KSCLocalization.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 02/12/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "KSCLocalization.h"
#import "KSCSDKConfig.h"

@implementation KSCLocalization

+ (NSString *)translationFor:(NSString *)key withDefaultValue:(NSString *)defaultValue
{
    return [[KSCSDKConfig sharedConfig].localizationTableBundle localizedStringForKey:key
                                                                                value:defaultValue
                                                                                table:[KSCSDKConfig sharedConfig].localizationTable];
}

@end
