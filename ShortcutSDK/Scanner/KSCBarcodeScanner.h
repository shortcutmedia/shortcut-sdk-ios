//
//  KSCBarcodeScanner.h
//  LiveScanner
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DecoderDelegate.h>
#import "KSCBarcodeScannerDelegate.h"


@interface KSCBarcodeScanner : NSObject <DecoderDelegate>

@property (nonatomic, assign, readwrite) id<KSCBarcodeScannerDelegate> delegate;

- (void)decodeImage:(CGImageRef)imageRef;

@end
