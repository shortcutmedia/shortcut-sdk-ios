//
//  SCMQRCodeScanner.h
//  LiveScanner
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DecoderDelegate.h>
#import "SCMQRCodeScannerDelegate.h"


@interface SCMQRCodeScanner : NSObject <DecoderDelegate>

@property (nonatomic, assign, readwrite) id<SCMQRCodeScannerDelegate> delegate;

- (void)decodeImage:(CGImageRef)imageRef;

@end
