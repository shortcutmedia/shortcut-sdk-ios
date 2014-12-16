//
//  SCMCustomToolbar.m
//  ShortcutSDK
//
//  Created by David Wisti on 1/6/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMCustomToolbar.h"
#import "SCMSDKConfig.h"


@interface SCMCustomToolbar (/* Private */)

@end


@implementation SCMCustomToolbar

- (void)awakeFromNib
{
	[super awakeFromNib];

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) { // iOS 6.1 or earlier
        NSString* backgroundImagePath = [[SCMSDKConfig SDKBundle] pathForResource:@"NavigationBarBackground" ofType:@"png"];
        UIImage* backgroundImage = [UIImage imageWithContentsOfFile:backgroundImagePath];
        self.layer.contents = (id)[backgroundImage CGImage];
    }
}


@end
