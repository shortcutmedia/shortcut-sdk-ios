//
//  SCMCameraStatusView.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/27/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SCMStatusView : UIView

- (void)setStatusTitle:(NSString *)title subtitle:(NSString *)subtitle;

- (void)setStatusTitle:(NSString *)title subtitle:(NSString *)subtitle showActivityIndicator:(BOOL)showActivityIndicator;

@end
