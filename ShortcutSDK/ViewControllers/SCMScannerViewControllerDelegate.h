//
//  SCMScannerViewControllerDelegate.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/26/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResponse.h"

@class SCMScannerViewController;

/**
 *  The SCMScannerViewControllerDelegate describes a protocol that allows reacting to events
 *  within an SCMScannerViewController instance.
 *
 *  @see SCMScannerViewController
 */
@protocol SCMScannerViewControllerDelegate <NSObject>

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
 *  @param scannerViewController The scanner view controller instance that recognized an item.
 *  @param response             The response from the image recognition service describing the recognized item(s).
 *  @param location             The location where the query was sent from.
 *  @param imageData            The (captured) image that was recognized.
 */
- (void)scannerViewController:(SCMScannerViewController *)scannerViewController recognizedQuery:(SCMQueryResponse *)response atLocation:(CLLocation *)location fromImage:(UIImage *)imageData;

@optional

/**
 *  This method is called whenever a scanner view successfully recognizes a QR code.
 *
 *  @discussion
 *  This is basically another "success handler" of a scanner view controller. It is called when a QR code
 *  (actually only QR codes are supported currently) is detected in an image.
 *
 *  Typical actions that you should implement/trigger in this method is the dismissal of the scanner
 *  view controller and then the display of the encoded data.
 *
 *  @note
 *  If you do not implement this method in your delegate then no QR code scanning will be performed. So if
 *  you do not want the scanner to recognize QR codes, then simply do not implement this method in your
 *  delegate.
 *
 *  @param scannerViewController The scanner view controller that recognized a QR code.
 *  @param text                 The content of the QR code.
 *  @param location             The location where the QR code was decoded.
 */
- (void)scannerViewController:(SCMScannerViewController *)scannerViewController recognizedQRCode:(NSString *)text atLocation:(CLLocation *)location;

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
 *  @param scannerViewController The scanner view controller that was used to capture the image.
 *  @param imageData            The image that was captured.
 *  @param location             The location where the image was captured.
 */
- (void)scannerViewController:(SCMScannerViewController *)scannerViewController capturedSingleImageWhileOffline:(NSData *)imageData atLocation:(CLLocation *)location;

/**
 *  This method is invoked when the user taps on the "Done" button.
 *
 *  @note If you do not implement this method then the "Done" button will not be displayed.
 *
 *  @param controller The scanner view controller in which the user tapped the "Done" button.
 */
- (void)scannerViewControllerDidFinish:(SCMScannerViewController *)controller;

@end
