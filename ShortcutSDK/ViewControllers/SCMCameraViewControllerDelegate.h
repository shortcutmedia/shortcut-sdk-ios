//
//  SCMCameraViewControllerDelegate.h
//  Shortcut
//
//  Created by David Wisti on 3/26/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResponse.h"

@class SCMCameraViewController;

@protocol SCMCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(SCMCameraViewController*)cameraViewController recognizedQuery:(SCMQueryResponse*)response atLocation:(CLLocation*)location fromImage:(NSData*)imageData;
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController recognizedBarcode:(NSString*)text atLocation:(CLLocation*)location;
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location;

- (void)cameraViewControllerDidFinish:(SCMCameraViewController*)controller;

@end
