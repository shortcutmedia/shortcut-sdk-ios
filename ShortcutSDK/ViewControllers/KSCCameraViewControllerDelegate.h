//
//  KSCCameraViewControllerDelegate.h
//  Shortcut
//
//  Created by David Wisti on 3/26/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "KSCQueryResponse.h"

@class KSCCameraViewController;

@protocol KSCCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(KSCCameraViewController*)cameraViewController recognizedQuery:(KSCQueryResponse*)response atLocation:(CLLocation*)location fromImage:(NSData*)imageData;
- (void)cameraViewController:(KSCCameraViewController*)cameraViewController recognizedBarcode:(NSString*)text atLocation:(CLLocation*)location;
- (void)cameraViewController:(KSCCameraViewController*)cameraViewController capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location;

- (void)cameraViewControllerDidFinish:(KSCCameraViewController*)controller;

@end
