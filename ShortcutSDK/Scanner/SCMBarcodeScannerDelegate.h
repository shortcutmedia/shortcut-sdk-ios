//
//  SCMBarcodeScannerDelegate.h
//  Shortcut
//
//  Created by David Wisti on 4/3/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@class SCMBarcodeScanner;

@protocol SCMBarcodeScannerDelegate <NSObject>

- (void)barcodeScanner:(SCMBarcodeScanner*)scanner didRecognize2DBarcode:(NSString*)text;
- (void)barcodeScanner:(SCMBarcodeScanner *)scanner didNotRecognize2DBarcode:(NSString*)why;

@end
