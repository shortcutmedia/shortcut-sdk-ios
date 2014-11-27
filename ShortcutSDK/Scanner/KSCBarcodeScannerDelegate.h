//
//  KSCBarcodeScannerDelegate.h
//  Shortcut
//
//  Created by David Wisti on 4/3/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@class KSCBarcodeScanner;

@protocol KSCBarcodeScannerDelegate <NSObject>

- (void)barcodeScanner:(KSCBarcodeScanner*)scanner didRecognize2DBarcode:(NSString*)text;
- (void)barcodeScanner:(KSCBarcodeScanner *)scanner didNotRecognize2DBarcode:(NSString*)why;

@end
