//
//  SCMBarcodeScanner.m
//  LiveScanner
//
//  Created by David Wisti on 2/15/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMBarcodeScanner.h"
#import <QRCodeReader.h>
#import <TwoDDecoderResult.h>
#import <Decoder.h>


@interface SCMBarcodeScanner (/* Private */)

@property (nonatomic, retain, readwrite) Decoder *decoder;

@end


@implementation SCMBarcodeScanner

@synthesize delegate;
@synthesize decoder;

#pragma mark - ZXing

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.decoder = [[[Decoder alloc] init] autorelease];
		QRCodeReader *qrCodeReader = [[[QRCodeReader alloc] init] autorelease];
		decoder.readers = [NSSet setWithObject:qrCodeReader];
		decoder.delegate = self;
	}
	
	return self;
}

- (void)dealloc
{
	self.decoder.delegate = nil;
	[decoder release];
	[super dealloc];
}

- (void)decodeImage:(CGImageRef)imageRef
{
	UIImage *image = [UIImage imageWithCGImage:imageRef];
//	NSDate *startDecode = [NSDate date];
	[self.decoder decodeImage:image];
//	NSTimeInterval decodeTime = [[NSDate date] timeIntervalSinceDate:startDecode];
//	DebugLog(@"decodeImage: %f", decodeTime);
}

#pragma mark - DecoderDelegate

- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)result
{
	[self.delegate barcodeScanner:self didRecognize2DBarcode:result.text];
}

- (void)decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason
{
	DebugLog(@"decoder failedToDecodeImage: %@", reason);
    [self.delegate barcodeScanner:self didNotRecognize2DBarcode:reason];
}

@end
