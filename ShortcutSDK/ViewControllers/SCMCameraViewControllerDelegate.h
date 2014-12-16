//
//  SCMCameraViewControllerDelegate.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/26/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResponse.h"

@class SCMCameraViewController;

/**
 *  The SCMCameraViewControllerDelegate describes a protocol that allows reacting to events
 *  within an SCMCameraViewController instance.
 *
 *  @see SCMCameraViewController
 */
@protocol SCMCameraViewControllerDelegate <NSObject>

@required

/// @name Recognition results

/**
 *  This method is called whenever a scanner view successfully recognizes an image.
 *
 *  @discussion
 *  This is basically the "success handler" of a scanner view controller. It is called when an
 *  image was successfully mapped to an item in the image recognition service.
 *
 *  Typical actions that you should implement/trigger in this method is the dismissal of the scanner
 *  view controller and then the display of the matched item(s).
 *
 *  @param cameraViewController The scanner view controller instance that recognized an item.
 *  @param response             The response from the image recognition service describing the recognized item(s).
 *  @param location             The location where the query was sent from.
 *  @param imageData            The (captured) image that was recognized.
 */
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController recognizedQuery:(SCMQueryResponse*)response atLocation:(CLLocation*)location fromImage:(NSData*)imageData;

@optional

/**
 *  This method is called whenever a scanner view successfully recognizes a barcode.
 *
 *  @discussion
 *  This is basically another "success handler" of a scanner view controller. It is called when a barcode
 *  (actually only QR codes are supported currently) is detected in an image.
 *
 *  Typical actions that you should implement/trigger in this method is the dismissal of the scanner
 *  view controller and then the display of the encoded data.
 *
 *  @note
 *  If you do not implement this method in your delegate then no barcode scanning will be performed. So if
 *  you do not want the scanner to recognize barcodes, then simply do not implement this method in your
 *  delegate.
 *
 *  @param cameraViewController The scanner view controller that recognized a barcode.
 *  @param text                 The content of the barcode.
 *  @param location             The location where the barcode was decoded.
 */
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController recognizedBarcode:(NSString*)text atLocation:(CLLocation*)location;

/**
 *  This method is called when the Snapshot mode of the scanner was used to capture an image but
 *  no internet connection was available and therefore image recognition could not be done.
 *
 *  @discussion
 *  This method gives you the possibility to e.g. store an image taken in Snapshot mode for later handling.
 *  If you do handle this special case then you might as well want to dismiss the scanner view controller
 *  at this moment.
 *  
 *  @note Remember: this method is only invoked when there is no Internet connection and image recognition
 *  therefore impossible.
 *
 *  @param cameraViewController The scanner view controller that was used to capture the image.
 *  @param imageData            The image that was captured.
 *  @param location             The location where the image was captured.
 */
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location;

/**
 *  This method is invoked when the user taps on the "Done" button.
 *
 *  @note If you do not implement this method then the "Done" button will not be displayed.
 *
 *  @param controller The scanner view controller in which the user tapped the "Done" button.
 */
- (void)cameraViewControllerDidFinish:(SCMCameraViewController*)controller;

@end
