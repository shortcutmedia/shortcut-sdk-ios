//
//  SCMScannerViewController.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCMScannerViewControllerDelegate.h"

/**
 *  The SCMScannerViewController implements a complete scanner view.
 *
 *  @discussion
 *  The SCMScannerViewController displays the scanner and performs image recognition queries.
 *
 *  Important events that happen within the scanner (e.g. image detected) are communicated to
 *  the view controller's delegate. This delegate is the main means of interaction with the
 *  scanner view controller.
 *
 *  @warning
 *  A scanner view should always be presented in portrait-mode only; it takes care of rotating
 *  its UI elements by itself.
 *  So if you want to present the scanner view controller  within another view controller (i.e
 *  UINavigationController or UITabBarController) then make sure that this view controller does
 *  not autorotate when presenting the scanner.
 *
 *  @see SCMScannerViewControllerDelegate
 */
@interface SCMScannerViewController : UIViewController

/**
 *  The delegate of the scanner view controller.
 *
 *  @discussion
 *  The delegate gets notified on important events within the scanner (e.g. image recognized).
 *
 *  @see SCMScannerViewControllerDelegate
 */
@property (nonatomic, unsafe_unretained, readwrite) id <SCMScannerViewControllerDelegate> delegate;

/**
 *  The current location of the user/device.
 *
 *  @discussion
 *  If you know the current location of the user/device you can set this property to it. The location,
 *  if available, is sent to the image recognition server and stored with the query.
 */
@property (nonatomic, strong, readwrite) CLLocation *location;


/// @name Help view

/**
 *  A UIView instance that is displayed when the help button is tapped.
 *
 *  @discussion
 *  To help your users (e.g. explain what they can scan) you can set this property to a UIView instance. When
 *  the property is set a help button is displayed in the scanner view which displays the view when
 *  tapped.
 */
@property (nonatomic, strong, readwrite) UIView *helpView;

/**
 *  This method toggles the help view display if a help view is set.
 *
 *  @discussion
 *  By invoking this method you can programmatically toggle the help view if one is set. You might want
 *  to do that from within you help view (e.g. to implement a close button).
 */
- (IBAction)toggleHelp;


/// @name Processing single images

/**
 *  This method processes a given image just as if it the scanner view had captured it itself.
 *
 *  @discussion
 *  If you already have obtained an image (e.g. from the user's photo roll or from a download)
 *  and you want to perform image recognition on it using the scanner UI then you can use this
 *  method. It will handle the image in exactly the same way as if it was captured using the
 *  scanner view.
 *
 *  @param imageData The image to process.
 */
- (void)processImage:(NSData *)imageData;

@end
