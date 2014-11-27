//
//  UIImage+ImageOrientation.m
//  DejaVu
//
//  Created by David Wisti on 5/3/11.
//  Copyright 2011 kooaba AG. All rights reserved.
//

#import "UIImage+ImageOrientation.h"


@implementation UIImage (ImageOrientation)

+ (UIImageOrientation)uiImageOrientationForCGImageOrientation:(NSNumber*)cgOrientation
{
	UIImageOrientation uiOrientation = UIImageOrientationUp;
	switch ([cgOrientation integerValue])
	{
		case 1:
			uiOrientation = UIImageOrientationUp;
			break;
			
		case 3:
			uiOrientation = UIImageOrientationDown;
			break;
			
		case 6:
			uiOrientation = UIImageOrientationRight;
			break;
			
		case 8:
			uiOrientation = UIImageOrientationLeft;
			break;
	}
	
	return uiOrientation;
}

+ (NSNumber*)cgImageOrientationForUIImageOrientation:(UIImageOrientation)uiOrientation
{
	NSInteger cgImageOrientation = 1;
	
	switch (uiOrientation)
	{
		case UIImageOrientationUp:
		case UIImageOrientationUpMirrored:
			cgImageOrientation = 1;
			break;
			
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			cgImageOrientation = 3;
			break;
			
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			cgImageOrientation = 6;
			break;
			
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			cgImageOrientation = 8;
			break;
	}
	
	return [NSNumber numberWithInteger:cgImageOrientation];
}

+ (NSNumber*)cgImageOrientationForUIDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	NSInteger cgImageOrientation = 1;
	
	switch (deviceOrientation)
	{
		case UIDeviceOrientationPortrait:
			cgImageOrientation = 6;
			break;
			
		case UIDeviceOrientationPortraitUpsideDown:
			cgImageOrientation = 8;
			break;
			
		case UIDeviceOrientationLandscapeRight:
			cgImageOrientation = 3;
			break;

		case UIDeviceOrientationLandscapeLeft:
			cgImageOrientation = 1;
			break;
			
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		case UIDeviceOrientationUnknown:
			break;
	}
	
	return [NSNumber numberWithInteger:cgImageOrientation];
}


@end
