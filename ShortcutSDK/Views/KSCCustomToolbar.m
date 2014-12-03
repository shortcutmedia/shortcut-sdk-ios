//
//  KSCCustomToolbar.m
//  Shortcut
//
//  Created by David Wisti on 1/6/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "KSCCustomToolbar.h"
#import "KSCSDKConfig.h"


@interface KSCCustomToolbar (/* Private */)

@end


@implementation KSCCustomToolbar

- (void)awakeFromNib
{
	[super awakeFromNib];

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) { // iOS 6.1 or earlier
        NSString* backgroundImagePath = [[KSCSDKConfig SDKBundle] pathForResource:@"NavigationBarBackground" ofType:@"png"];
        UIImage* backgroundImage = [UIImage imageWithContentsOfFile:backgroundImagePath];
        self.layer.contents = (id)[backgroundImage CGImage];
    }
}


@end
