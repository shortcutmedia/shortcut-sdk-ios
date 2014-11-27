//
//  KSCCameraViewController.h
//  Shortcut
//
//  Created by David Wisti on 3/13/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSCCameraViewControllerDelegate.h"

@interface KSCCameraViewController : UIViewController

@property (nonatomic, unsafe_unretained, readwrite) id<KSCCameraViewControllerDelegate> delegate;
@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, readwrite) BOOL scanQRCodes;
@property (nonatomic, strong, readwrite) UIView* helpView;

- (instancetype)init;

- (IBAction)toggleHelp;
- (void)processImage:(NSData*)imageData;

@end
