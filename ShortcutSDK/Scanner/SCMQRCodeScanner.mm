//
//  SCMQRCodeScanner.m
//  LiveScanner
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMQRCodeScanner.h"
#import <QRCodeReader.h>
#import <TwoDDecoderResult.h>
#import <Decoder.h>


@interface SCMQRCodeScanner () <DecoderDelegate>

@property (nonatomic, retain, readwrite) Decoder *decoder;

@end


@implementation SCMQRCodeScanner

#pragma mark - ZXing

- (id)init {
    self = [super init];
    if (self != nil) {
        self.decoder = [[Decoder alloc] init];
        QRCodeReader *qrCodeReader = [[QRCodeReader alloc] init];
        self.decoder.readers = [NSSet setWithObject:qrCodeReader];
        self.decoder.delegate = self;
    }

    return self;
}

- (void)dealloc {
    self.decoder.delegate = nil;
    self.decoder = nil;
}

- (void)decodeImage:(CGImageRef)imageRef {
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    [self.decoder decodeImage:image];
}

#pragma mark - DecoderDelegate

- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)result {
    [self.delegate qrcodeScanner:self didRecognizeQRCode:result.text];
}

- (void)decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason {
    DebugLog(@"decoder failedToDecodeImage: %@", reason);
    [self.delegate qrcodeScanner:self didNotRecognizeQRCode:reason];
}

@end
