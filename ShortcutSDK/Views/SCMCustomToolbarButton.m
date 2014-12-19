//
//  SCMCustomToolbarButton.m
//  ShortcutSDK
//
//  Created by David Wisti on 1/6/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMCustomToolbarButton.h"
#import "SCMSDKConfig.h"


@implementation SCMCustomToolbarButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) { // iOS 6.1 or earlier
        NSString *barButtonBackgroundPath = [[SCMSDKConfig SDKBundle] pathForResource:@"BarButtonBackground" ofType:@"png"];
        UIImage *barButtonBackground = [UIImage imageWithContentsOfFile:barButtonBackgroundPath];
        UIImage *stretchableBarButtonBackground = [barButtonBackground stretchableImageWithLeftCapWidth:6 topCapHeight:0];
        [self setBackgroundImage:stretchableBarButtonBackground forState:UIControlStateNormal];
        [self setContentEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    }
}

@end
