//
//  KSCUUIDUtils.m
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCUUIDUtils.h"

@implementation KSCUUIDUtils

+ (NSString *)generateUUID
{
    return [[[NSUUID UUID] UUIDString] lowercaseString];
}

+ (NSString *)normalizeUUID:(NSString *)uuid
{
    // lowercase
    NSString* normalizedUUID = [uuid lowercaseString];
    
    //with dashes
    if (normalizedUUID.length == 32)
    {
        // UUID contains no dashes. Add them back in.
        NSMutableString* canonicalUUID = [NSMutableString stringWithString:normalizedUUID];
        [canonicalUUID insertString:@"-" atIndex:8];
        [canonicalUUID insertString:@"-" atIndex:13];
        [canonicalUUID insertString:@"-" atIndex:18];
        [canonicalUUID insertString:@"-" atIndex:23];
        normalizedUUID = canonicalUUID;
    }
    return normalizedUUID;
}

@end
