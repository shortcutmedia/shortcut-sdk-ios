//
//  SCMLocalization.m
//  ShortcutSDKSDK
//
//  Created by Severin Schoepke on 02/12/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMLocalization.h"
#import "SCMSDKConfig.h"

@implementation SCMLocalization

+ (NSString *)translationFor:(NSString *)key withDefaultValue:(NSString *)defaultValue {
    return [[SCMSDKConfig sharedConfig].localizationTableBundle localizedStringForKey:key
                                                                                value:defaultValue
                                                                                table:[SCMSDKConfig sharedConfig].localizationTable];
}

@end
