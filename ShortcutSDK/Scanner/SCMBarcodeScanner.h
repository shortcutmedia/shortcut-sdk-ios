//
//  SCMBarcodeScanner.h
//  LiveScanner
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DecoderDelegate.h>
#import "SCMBarcodeScannerDelegate.h"


@interface SCMBarcodeScanner : NSObject <DecoderDelegate>

@property (nonatomic, assign, readwrite) id<SCMBarcodeScannerDelegate> delegate;

- (void)decodeImage:(CGImageRef)imageRef;

@end
