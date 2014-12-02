//
//  KSCLocalization.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 02/12/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCLocalization : NSObject

+ (NSString *)translationFor:(NSString *)key withDefaultValue:(NSString *)defaultValue;

@end
