//
//  SCMLiveScannerDelegate.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/26/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SCMQueryResponse.h"

@class SCMLiveScanner;

@protocol SCMLiveScannerDelegate <NSObject>

- (void)liveScanner:(SCMLiveScanner *)scanner recognizingImage:(NSData *)imageData;
- (void)liveScanner:(SCMLiveScanner *)scanner didNotRecognizeImage:(NSData *)imageData;

- (void)liveScanner:(SCMLiveScanner *)scanner recognizedImage:(NSData *)imageData atLocation:(CLLocation *)location withResponse:(SCMQueryResponse *)response;
- (void)liveScanner:(SCMLiveScanner *)scanner recognizedQRCode:(NSString *)text atLocation:(CLLocation *)location;
- (void)liveScanner:(SCMLiveScanner *)scanner capturedSingleImageWhileOffline:(NSData *)imageData atLocation:(CLLocation *)location;

- (void)liveScannerShouldClose:(SCMLiveScanner *)scanner;

- (void)liveScanner:(SCMLiveScanner *)scanner didRequestPictureTakeWithCompletionHandler:(void (^)(NSData *data, NSError *error))completionHandler;

@end
