//
//  SCMTestCase.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 27/01/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMTestCase.h"

#import <ShortcutSDK/SCMSDKConfig.h>

@implementation SCMTestCase

- (void)setUp
{
    [super setUp];
    
    // The following credentials belong to the "SDK Demo" query key which works with only
    // a couple of demo items.
    [SCMSDKConfig sharedConfig].accessKey = @"677795eb-4fba-4797-963d-2e455f7d08f6";
    [SCMSDKConfig sharedConfig].secretKey = @"4NoTXkiaw4mLze0irkTuIg0KDj7D73er6v4lTvEm";
}

+ (NSBundle *)testBundle
{
    return [NSBundle bundleForClass:[self class]];
}

@end
