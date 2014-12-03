//
//  SCMJSONUtils.m
//  Shortcut
//
//  Created by David Wisti on 6/21/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "SCMDictionaryUtils.h"

@implementation SCMDictionaryUtils

+ (id)objectFromDictionary:(NSDictionary*)dictionary withClass:(Class)class atPath:(NSString*)path
{
	if (class == nil || [dictionary isKindOfClass:[NSDictionary class]] == NO || path.length == 0)
	{
		return nil;
	}
	
	NSArray* components = [path componentsSeparatedByString:@"/"];
	NSMutableArray* remainingComponents = [NSMutableArray arrayWithArray:components];
	
	while (remainingComponents.count > 1)
	{
		NSString* key = [remainingComponents objectAtIndex:0];
		dictionary = [dictionary objectForKey:key];
        if ([dictionary isKindOfClass:[NSArray class]])
        {
            dictionary = [((NSArray*)dictionary) objectAtIndex:0];
        }
		if ([dictionary isKindOfClass:[NSDictionary class]] == NO)
		{
			return nil;
		}
		[remainingComponents removeObjectAtIndex:0];
	}
	
	id result = nil;
	if (remainingComponents.count == 1)
	{
		id object = [dictionary objectForKey:[remainingComponents objectAtIndex:0]];
        if (class == NSNumber.class && [object isKindOfClass:NSString.class])
            object = [NSNumber numberWithInt:((NSString*)object).intValue];
		if ([object isKindOfClass:class])
		{
			result = object;
		}
	}
	
	return result;
}

+ (NSString*)stringFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path
{
	NSString* result = [SCMDictionaryUtils objectFromDictionary:dictionary withClass:[NSString class] atPath:path];
	return result;
}

+ (NSNumber*)numberFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path
{
	NSNumber* result = [SCMDictionaryUtils objectFromDictionary:dictionary withClass:[NSNumber class] atPath:path];
	return result;
}

+ (NSArray*)arrayFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path
{
	NSArray* result = [SCMDictionaryUtils objectFromDictionary:dictionary withClass:[NSArray class] atPath:path];
	return result;
}

+ (NSDictionary*)dictionaryFromDictionary:(NSDictionary*)dictionary atPath:(NSString*)path
{
	NSDictionary* result = [SCMDictionaryUtils objectFromDictionary:dictionary withClass:[NSDictionary class] atPath:path];
	return result;
}


@end
