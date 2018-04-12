//
//  SCMPreviewView.m
//  ShortcutDocumentScanner
//
//  Created by Vladislav Jevremovic on 1/26/18.
//  Copyright © 2018 Shortcut. All rights reserved.
//

#import "SCMPreviewView.h"

@implementation SCMPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *) self.layer;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    self.videoPreviewLayer.session = session;
}

@end
