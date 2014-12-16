//
//  SCMUUIDUtils.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCMUUIDUtils : NSObject

+ (NSString *)generateUUID;
+ (NSString *)normalizeUUID:(NSString *)uuid;

@end
