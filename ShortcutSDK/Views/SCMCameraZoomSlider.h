//
//  SCMCameraZoomSlider.h
//  Shortcut
//
//  Created by David Wisti on 11/3/11.
//  Copyright (c) 2011 kooaba AG. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SCMCameraZoomSlider : UIControl

@property (nonatomic, assign, readwrite) CGFloat zoomScale;
@property (nonatomic, assign, readwrite) CGFloat maxScale;

- (void)showZoomControl;
- (void)resetHideZoomControlTimer;
- (void)hideZoomControl;
- (void)pinchToZoom:(UIGestureRecognizer*)gestureRecognizer;

@end
