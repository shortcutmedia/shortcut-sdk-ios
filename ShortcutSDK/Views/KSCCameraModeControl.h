//
//  KSCCameraModeControl.h
//  Shortcut
//
//  Created by David Wisti on 4/4/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum
{
	kCameraModeSingleShot = 0,
	kCameraModeLiveScanning
} KSCCameraMode;

@interface KSCCameraModeControl : UIControl

@property (nonatomic, assign, readwrite) KSCCameraMode cameraMode;
@property (nonatomic, strong, readonly) UIImageView* singleShotIcon;
@property (nonatomic, strong, readonly) UIImageView* liveScannerIcon;

@end
