//
//  SCMPreviewView.h
//  ShortcutDocumentScanner
//
//  Created by Vladislav Jevremovic on 1/26/18.
//  Copyright © 2018 Shortcut. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SCMPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) AVCaptureSession *session;

@end
