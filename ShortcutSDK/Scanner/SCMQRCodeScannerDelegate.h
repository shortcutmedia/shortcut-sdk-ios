//
//  SCMQRCodeScannerDelegate.h
//  ShortcutSDK
//
//  Created by David Wisti on 4/3/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@class SCMQRCodeScanner;

@protocol SCMQRCodeScannerDelegate <NSObject>

- (void)qrcodeScanner:(SCMQRCodeScanner *)scanner didRecognizeQRCode:(NSString *)text;
- (void)qrcodeScanner:(SCMQRCodeScanner *)scanner didNotRecognizeQRCode:(NSString *)why;

@end
