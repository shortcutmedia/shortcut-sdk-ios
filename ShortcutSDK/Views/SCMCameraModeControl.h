//
//  SCMCameraModeControl.h
//  ShortcutSDK
//
//  Created by David Wisti on 4/4/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum
{
	kCameraModeSingleShot = 0,
	kCameraModeLiveScanning
} SCMCameraMode;

@interface SCMCameraModeControl : UIControl

@property (nonatomic, assign, readwrite) SCMCameraMode cameraMode;
@property (nonatomic, strong, readonly) UIImageView *singleShotIcon;
@property (nonatomic, strong, readonly) UIImageView *liveScannerIcon;

@end
