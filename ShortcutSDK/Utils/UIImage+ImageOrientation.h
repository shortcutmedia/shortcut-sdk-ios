//
//  UIImage+ImageOrientation.h
//  DejaVu
//
//  Created by David Wisti on 5/3/11.
//  Copyright 2011 kooaba AG. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (ImageOrientation)
    
+ (UIImageOrientation)uiImageOrientationForCGImageOrientation:(NSNumber*)cgOrientation;
+ (NSNumber*)cgImageOrientationForUIImageOrientation:(UIImageOrientation)uiOrientation;
+ (NSNumber*)cgImageOrientationForUIDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end
