//
//  KSCJSONUtils.h
//  Shortcut
//
//  Created by David Wisti on 6/21/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCDictionaryUtils : NSObject

+ (NSString*)stringFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path;
+ (NSNumber*)numberFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path;
+ (NSArray*)arrayFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path;
+ (NSDictionary*)dictionaryFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path;

@end
