//
//  KSCUUIDUtils.h
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCUUIDUtils : NSObject

+ (NSString *)generateUUID;
+ (NSString *)normalizeUUID:(NSString *)uuid;

@end
