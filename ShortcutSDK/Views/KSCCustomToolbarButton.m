//
//  KSCCustomToolbarButton.m
//  Shortcut
//
//  Created by David Wisti on 1/6/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "KSCCustomToolbarButton.h"
#import "KSCSDKConfig.h"


@implementation KSCCustomToolbarButton

- (void)awakeFromNib
{
	[super awakeFromNib];

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) { // iOS 6.1 or earlier
        NSString* barButtonBackgroundPath = [[KSCSDKConfig SDKBundle] pathForResource:@"BarButtonBackground" ofType:@"png"];
        UIImage* barButtonBackground = [UIImage imageWithContentsOfFile:barButtonBackgroundPath];
        UIImage* stretchableBarButtonBackground = [barButtonBackground stretchableImageWithLeftCapWidth:6 topCapHeight:0];
        [self setBackgroundImage:stretchableBarButtonBackground forState:UIControlStateNormal];
    }
}

@end
