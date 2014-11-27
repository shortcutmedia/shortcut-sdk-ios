//
//  KSCLiveScannerDelegate.h
//  Shortcut
//
//  Created by David Wisti on 3/26/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "KSCQueryResponse.h"

@class KSCLiveScanner;

@protocol KSCLiveScannerDelegate <NSObject>

- (void)liveScanner:(KSCLiveScanner*)scanner recognizingImage:(NSData*)imageData;
- (void)liveScanner:(KSCLiveScanner*)scanner didNotRecognizeImage:(NSData*)imageData;

- (void)liveScanner:(KSCLiveScanner*)scanner recognizedImage:(NSData*)imageData atLocation:(CLLocation*)location withResponse:(KSCQueryResponse*)response;
- (void)liveScanner:(KSCLiveScanner*)scanner recognizedBarcode:(NSString*)text atLocation:(CLLocation*)location;
- (void)liveScanner:(KSCLiveScanner*)scanner capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location;

- (void)liveScannerShouldClose:(KSCLiveScanner*)scanner;

@end
