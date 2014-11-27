//
//  KSCImageUtils.m
//  Shortcut
//
//  Created by David Wisti on 12/6/11.
//  Copyright (c) 2011 kooaba AG. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "KSCImageUtils.h"
#import "UIImage+ImageOrientation.h"


@implementation KSCImageUtils

+ (NSData*)scaledImageDataWithImage:(CGImageRef)sourceImage orientation:(NSInteger)imageOrientation maxSize:(CGFloat)maximumImageSize compression:(CGFloat)compressionQuality zoomFactor:(CGFloat)zoomFactor
{
	NSMutableData* imageData = nil;
	
	if (sourceImage != NULL)
	{
//		DebugLog(@"source image %ld, %ld", CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage));
//		NSDate* startScale = [NSDate date];
		CGImageRef scaledImage = [self newScaledImageWithImage:sourceImage maxSize:maximumImageSize zoomFactor:zoomFactor];
//		DebugLog(@"scaled image created %ld, %ld", CGImageGetWidth(scaledImage), CGImageGetHeight(scaledImage));
		
		// NSDate* startCompress = [NSDate date];
		imageData = [[NSMutableData alloc] init];
		CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
		if (imageDestination != NULL)
		{
//			DebugLog(@"compressing image with quality %f", compressionQuality);
			NSMutableDictionary* imageProperties = [NSMutableDictionary dictionaryWithCapacity:2];
			[imageProperties setObject:[NSNumber numberWithInteger:imageOrientation] forKey:(NSString*)kCGImagePropertyOrientation];
			[imageProperties setObject:[NSNumber numberWithFloat:compressionQuality] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];
			
			CGImageDestinationAddImage(imageDestination, scaledImage, (__bridge CFDictionaryRef)imageProperties);
			BOOL succeeded = CGImageDestinationFinalize(imageDestination);
			if (succeeded == NO)
			{
				imageData = nil;
			}
			
			CFRelease(imageDestination);
		}
		
		CGImageRelease(scaledImage);
		// NSDate* endScale = [NSDate date];
		// DebugLog(@"scaledImageDataWithImage: %f (compress %f)", [endScale timeIntervalSinceDate:startScale], [endScale timeIntervalSinceDate:startCompress]);
	}
	
	return imageData;
}

+ (NSData*)scaledImageDataWithJPEGData:(NSData*)jpegData orientation:(NSInteger)imageOrientation maxSize:(CGFloat)maximumImageSize compression:(CGFloat)compressionQuality zoomFactor:(CGFloat)zoomFactor
{
	NSMutableData* imageData = nil;
	
	CGDataProviderRef jpegDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)jpegData);
	if (jpegDataProvider != NULL)
	{
		CGImageRef sourceImage = CGImageCreateWithJPEGDataProvider(jpegDataProvider, NULL, YES, kCGRenderingIntentDefault);
		
		if (sourceImage != NULL)
		{
//			DebugLog(@"source image created %ld, %ld", CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage));
			CGImageRef scaledImage = [self newScaledImageWithImage:sourceImage maxSize:maximumImageSize zoomFactor:zoomFactor];
//			DebugLog(@"scaled image created %ld, %ld", CGImageGetWidth(scaledImage), CGImageGetHeight(scaledImage));
			
			imageData = [NSMutableData data];
			CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
			if (imageDestination != NULL)
			{
				DebugLog(@"compressing image with quality %f, orientation %ld", compressionQuality, (long)imageOrientation);
				NSMutableDictionary* imageProperties = [NSMutableDictionary dictionaryWithCapacity:2];
				[imageProperties setObject:[NSNumber numberWithInteger:imageOrientation] forKey:(NSString*)kCGImagePropertyOrientation];
				[imageProperties setObject:[NSNumber numberWithFloat:compressionQuality] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];
				
				CGImageDestinationAddImage(imageDestination, scaledImage, (__bridge CFDictionaryRef)imageProperties);
				BOOL succeeded = CGImageDestinationFinalize(imageDestination);
				if (succeeded == NO)
				{
					imageData = nil;
				}
				
				CFRelease(imageDestination);
			}
			
			CGImageRelease(sourceImage);
			CGImageRelease(scaledImage);
		}
		
		CGDataProviderRelease(jpegDataProvider);
	}
	
	return [NSData dataWithData:imageData];
}

+ (CGImageRef)newScaledImageWithImage:(CGImageRef)sourceImage maxSize:(CGFloat)size zoomFactor:(CGFloat)zoomFactor
{
	static const CGFloat kWhite[4] = {0.0f, 0.0f, 0.0f, 1.0f};
	
	size_t width  = CGImageGetWidth(sourceImage);
	size_t height = CGImageGetHeight(sourceImage);
	
	if (zoomFactor == 1.0 && width <= size && height <= size)
	{
		// The image does not need scaling, return the original with a +1 retain count so that this method
		// always returns an object with a +1 retain count.
//		DebugLog(@"image (%ld, %ld) does not need scaling (%f)", width, height, size);
		return CGImageRetain(sourceImage);
	}
	
	CGImageRef scaledImage = NULL;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGColorRef white = CGColorCreate(space, kWhite);
	
	CGFloat x = 0.0;
	CGFloat y = 0.0;
	if (height > width)
	{
		// tall image
		width = (size / height) * width;
		height = size;
	}
	else
	{
		// wide image
		height = (size / width) * height;
		width = size;
	}
	
	// Save the dimensions of the image, since we may need to adjust the width/height of the drawing rectangle for zooming.
	CGFloat imageWidth = (CGFloat)width;
	CGFloat imageHeight = (CGFloat)height;
	
	if (zoomFactor > 1.0)
	{
		// The image needs to be zoomed, adjust the rectangle used for drawing accordingly
		width = width * zoomFactor;
		height = height * zoomFactor;
		
		// Center the larger image rectangle over the context rectangle
		x = -((width - imageWidth) / 2.0);
		y = -((height - imageHeight) / 2.0);
	}
	
	CGRect r = CGRectMake(x, y, width, height);
	
	// Create the context that's thumbnailSize x thumbnailSize.
	
	CGContextRef context = CGBitmapContextCreate(NULL, imageWidth, imageHeight, 8, 0, space, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	if (context != NULL)
	{
		// Make sure anything we don't cover comes out white. There's a possibility 
		// that we're dealing with a transparent PNG.
		
		CGContextSetFillColorWithColor(context, white);
		CGContextFillRect(context, CGRectMake(0.0f, 0.0f, imageWidth, imageHeight));
		
		// Draw the source image and get then create the thumbnail from the 
		// context. 
		
		CGContextDrawImage(context, r, sourceImage);
		
		scaledImage = CGBitmapContextCreateImage(context);
		CGContextRelease(context);
	}
	
	CGColorSpaceRelease(space);
	CGColorRelease(white);
	
	// Returns a CGImage with a +1 count
	return scaledImage;
}

+ (CGImageRef)newThumbnailFromImage:(CGImageRef)sourceImage withSize:(CGFloat)thumbnailSize
{
	static const CGFloat kWhite[4] = {0.0f, 0.0f, 0.0f, 1.0f};
	
	CGImageRef scaledImage = NULL;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGColorRef white = CGColorCreate(space, kWhite);
	
	// Calculate the drawing rectangle so that the image fills the entire 
	// thumbnail.  That is, for a tall image, we scale it so that the 
	// width matches thumbnailSize and the it's centered vertically.  
	// Similarly for a wide image.
	
	CGFloat x = 0.0;
	CGFloat y = 0.0;
	CGFloat width = CGImageGetWidth(sourceImage);
	CGFloat height = CGImageGetHeight(sourceImage);
	if (height > width)
	{
		// tall image
		height = (height / width) * thumbnailSize;
		width  = thumbnailSize;
		y = - ((height - thumbnailSize) / 2);
	}
	else
	{
		// wide image
		width  = (width / height) * thumbnailSize;
		height = thumbnailSize;
		x = - ((width - thumbnailSize) / 2);
	}
	
	CGRect r = CGRectMake(x, y, width, height);
	
	// Create the context that's thumbnailSize x thumbnailSize.
	
	CGContextRef context = CGBitmapContextCreate(NULL, thumbnailSize, thumbnailSize, 8, 0,
																							 space, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	if (context != NULL)
	{
		// Make sure anything we don't cover comes out white. There's a possibility 
		// that we're dealing with a transparent PNG.
		
		CGContextSetFillColorWithColor(context, white);
		CGContextFillRect(context, CGRectMake(0.0f, 0.0f, thumbnailSize, thumbnailSize));
		
		// Draw the source image and get then create the thumbnail from the 
		// context. 
		
		CGContextDrawImage(context, r, sourceImage);
		
		scaledImage = CGBitmapContextCreateImage(context);
		CGContextRelease(context);
	}
	
	CGColorSpaceRelease(space);
	CGColorRelease(white);

	// Returns a CGImage with a +1 count
	return scaledImage;
}

+ (UIImage*)imageWithCompressedData:(NSData*)compressedData
{
	UIImage* image = nil;
	CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)compressedData, NULL);
	if (imageSource != NULL)
	{
		CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
		NSNumber* orientation = [(__bridge NSDictionary*)imageProperties objectForKey:(NSString*)kCGImagePropertyOrientation];
		UIImageOrientation uiOrientation = [UIImage uiImageOrientationForCGImageOrientation:orientation];
		CFRelease(imageProperties);

		CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		if (cgImage != NULL)
		{
			image = [[UIImage alloc] initWithCGImage:cgImage scale:1.0 orientation:uiOrientation];
//			DebugLog(@"imageWithCompressedData: %f, %f (%d)", image.size.width, image.size.height, image.imageOrientation);
		}
		
		CGImageRelease(cgImage);
		CFRelease(imageSource);
	}
	
	return image;
}

+ (UIImage*)thumbnailWithCompressedData:(NSData*)compressedData thumbnailSize:(CGFloat)size
{
	UIImage* thumbnail = nil;
	
	CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)compressedData, NULL);
	if (imageSource != NULL)
	{
		CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
		NSNumber* orientation = [(__bridge NSDictionary*)imageProperties objectForKey:(NSString*)kCGImagePropertyOrientation];
		UIImageOrientation uiOrientation = [UIImage uiImageOrientationForCGImageOrientation:orientation];
		CFRelease(imageProperties);
//		DebugLog(@"image orientation in source (for thumbnail): %d", uiOrientation);
		
		CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		if (cgImage != NULL)
		{
			CGImageRef thumbnailImage = [self newThumbnailFromImage:cgImage withSize:size];
			if (thumbnailImage != NULL)
			{
				thumbnail = [[UIImage alloc] initWithCGImage:thumbnailImage scale:1.0 orientation:uiOrientation];
//				DebugLog(@"thumbnailWithCompressedData: %f, %f (%d)", thumbnail.size.width, thumbnail.size.height, thumbnail.imageOrientation);
				CGImageRelease(thumbnailImage);
			}
			
			CGImageRelease(cgImage);
		}
		
		CFRelease(imageSource);
	}

	return thumbnail;
}

+ (UIImage*)imageFromURL:(NSURL*)imageURL
{
	UIImage* image = nil;

	if (CGImageSourceCreateWithURL == NULL)
	{
		NSData* imageData = [NSData dataWithContentsOfURL:imageURL];
		if (imageData != nil)
		{
			image = [UIImage imageWithData:imageData];
		}
	}
	else
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, NULL);
		if (imageSource != NULL)
		{
			UIImageOrientation uiOrientation = UIImageOrientationUp;
			CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
			if (imageProperties != NULL)
			{
				NSNumber* orientation = [(__bridge NSDictionary*)imageProperties objectForKey:(NSString*)kCGImagePropertyOrientation];
				uiOrientation = [UIImage uiImageOrientationForCGImageOrientation:orientation];
//				DebugLog(@"imageFromURL:(%@)\n%@", imageURL, (NSDictionary*)imageProperties);
				CFRelease(imageProperties);
			}
			
			NSDictionary* imageSourceProps = [NSDictionary dictionaryWithObjectsAndKeys:(NSString*)kUTTypeJPEG, kCGImageSourceTypeIdentifierHint, nil];
			CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageSourceProps);
			if (cgImage != NULL)
			{
				//			DebugLog(@"imageFromURL orientation: %d", uiOrientation);
				image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:uiOrientation];
				//			DebugLog(@"imageFromURL (%f, %f) (%d)", image.size.width, image.size.height, image.imageOrientation);
				CFRelease(cgImage);
			}
			CFRelease(imageSource);
		}
	}

//	if (image != nil)
//	{
//		DebugLog(@"loaded image size %f, %f (%d)", image.size.width, image.size.height, image.imageOrientation);
//	}
	
	return image;
}

+ (UIImage*)thumbnailFromURL:(NSURL*)imageURL maxSize:(CGFloat)maxSize
{
	UIImage* image = nil;
	
	if (CGImageSourceCreateWithURL == NULL)
	{
		NSData* imageData = [NSData dataWithContentsOfURL:imageURL];
		if (imageData != nil)
		{
			UIImage* fullImage = [UIImage imageWithData:imageData];
			if (fullImage != nil)
			{
				CGImageRef thumbnailImage = [self newThumbnailFromImage:[fullImage CGImage] withSize:maxSize];
				image = [UIImage imageWithCGImage:thumbnailImage];
				CGImageRelease(thumbnailImage);
			}
		}
	}
	else
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, NULL);
		if (imageSource != NULL)
		{
			UIImageOrientation uiOrientation = UIImageOrientationUp;
			CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
			if (imageProperties != NULL)
			{
				NSNumber* orientation = [(__bridge NSDictionary*)imageProperties objectForKey:(NSString*)kCGImagePropertyOrientation];
				uiOrientation = [UIImage uiImageOrientationForCGImageOrientation:orientation];
//				DebugLog(@"thumbnailFromURL:(%@)\n%@", imageURL, (NSDictionary*)imageProperties);
				CFRelease(imageProperties);
			}
			
			NSDictionary* imageSourceProps = [NSDictionary dictionaryWithObjectsAndKeys:(NSString*)kUTTypeJPEG, kCGImageSourceTypeIdentifierHint, nil];
			CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageSourceProps);
			if (cgImage != NULL)
			{
				CGImageRef thumbnailImage = [self newThumbnailFromImage:cgImage withSize:maxSize];
				//			DebugLog(@"thumbnailFromURL orientation: %d", uiOrientation);
				image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:uiOrientation];
				//			DebugLog(@"thumbnailFromURL (%f, %f) (%d)", image.size.width, image.size.height, image.imageOrientation);
				CFRelease(cgImage);
				CGImageRelease(thumbnailImage);
			}
			CFRelease(imageSource);
		}
	}
	
//	if (image != nil)
//	{
//		DebugLog(@"loaded thumbnail size %f, %f (%d)", image.size.width, image.size.height, image.imageOrientation);
//	}
	
	return image;
}

+ (CGImageRef)newImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	// Lock the base address of the pixel buffer.
	CVPixelBufferLockBaseAddress(imageBuffer,0);
	
	// Get the number of bytes per row for the pixel buffer.
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	// Get the pixel buffer width and height.
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	// Create a device-dependent RGB color space.
	static CGColorSpaceRef colorSpace = NULL;
	if (colorSpace == NULL) 
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		if (colorSpace == NULL) 
		{
			// Handle the error appropriately.
			return nil;
		}
	}
	
	// Get the base address of the pixel buffer.
	void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	// Get the data size for contiguous planes of the pixel buffer.
	size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
	
	// Create a Quartz direct-access data provider that uses data we supply.
	CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
	
	// Create a bitmap image from data supplied by the data provider.
	CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow,
																		 colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
																		 dataProvider, NULL, true, kCGRenderingIntentDefault);
	CGDataProviderRelease(dataProvider);
	
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	return cgImage;
}

+ (CGImageRef)newImageForZXingFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */
    
    return newImage;
}

+ (NSData*)compressedImageDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer size:(CGSize)size compression:(CGFloat)compression
{
	// NSDate* startCompressImage = [NSDate date];
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	// Lock the base address of the pixel buffer.
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	// Get the number of bytes per row for the pixel buffer.
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	
	// Get the pixel buffer height.
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	// Get the base address of the pixel buffer.
	void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	
	vImage_Buffer sourceImageBuffer;
	sourceImageBuffer.data = baseAddress;
	sourceImageBuffer.width = width;
	sourceImageBuffer.height = height;
	sourceImageBuffer.rowBytes = bytesPerRow;
	
	size_t scaledImageSize = size.height * (size.width * sizeof(uint32_t));
	NSMutableData* scaledImageData = [[NSMutableData alloc] initWithLength:scaledImageSize];

	if (vImageScale_ARGB8888 != NULL && (width != size.width || height != size.height))
	{
		vImage_Buffer scaledImageBuffer;
		scaledImageBuffer.width = size.width;
		scaledImageBuffer.height = size.height;
		scaledImageBuffer.rowBytes = scaledImageBuffer.width * sizeof(uint32_t);
		scaledImageBuffer.data = scaledImageData.mutableBytes;
		
		vImage_Error scaleError = vImageScale_ARGB8888(&sourceImageBuffer, &scaledImageBuffer, NULL, 0);
		
		if (scaleError == 0)
		{
			sourceImageBuffer.data = scaledImageBuffer.data;
			sourceImageBuffer.width = scaledImageBuffer.width;
			sourceImageBuffer.height = scaledImageBuffer.height;
			sourceImageBuffer.rowBytes = scaledImageBuffer.rowBytes;
		}
	}
	
	CGImageRef imageRef = NULL;
	
	// Create a device-dependent RGB color space.
	static CGColorSpaceRef colorSpace = NULL;
	if (colorSpace == NULL) 
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	
	// We can't create the image without a color space.
	if (colorSpace != NULL) 
	{
		size_t bufferSize = sourceImageBuffer.rowBytes * sourceImageBuffer.height;
		
		// Create a Quartz direct-access data provider that uses data we supply.
		CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, sourceImageBuffer.data, bufferSize, NULL);
		
		// Create a bitmap image from data supplied by the data provider.
		imageRef = CGImageCreate(sourceImageBuffer.width, sourceImageBuffer.height, 8, 32, sourceImageBuffer.rowBytes,
														 colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
														 dataProvider, NULL, true, kCGRenderingIntentDefault);
		CGDataProviderRelease(dataProvider);
	}
	
	NSData* compressedImageData = nil;
	
	if (imageRef != NULL)
	{
		compressedImageData = [KSCImageUtils scaledImageDataWithImage:imageRef
																													 orientation:6
																															 maxSize:size.width 
																													 compression:compression 
																														zoomFactor:1.0];
		CGImageRelease(imageRef);
	}
	
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	// NSDate* endCompressImage = [NSDate date];
	// DebugLog(@"compressedImageDataFromSampleBuffer: %f", [endCompressImage timeIntervalSinceDate:startCompressImage]);

	return compressedImageData;
}

+ (CGImageRef)newScaledImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer size:(CGSize)size
{
	// NSDate* startScaleImage = [NSDate date];
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	// Lock the base address of the pixel buffer.
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	// Get the number of bytes per row for the pixel buffer.
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	
	// Get the pixel buffer height.
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	// Get the base address of the pixel buffer.
	void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	
	vImage_Buffer sourceImageBuffer;
	sourceImageBuffer.data = baseAddress;
	sourceImageBuffer.width = width;
	sourceImageBuffer.height = height;
	sourceImageBuffer.rowBytes = bytesPerRow;
	
	size_t scaledImageSize = size.height * (size.width * sizeof(uint32_t));
	NSMutableData* scaledImageData = [[NSMutableData alloc] initWithLength:scaledImageSize];
	
	if (vImageScale_ARGB8888 != NULL && (width != size.width || height != size.height))
	{
		vImage_Buffer scaledImageBuffer;
		scaledImageBuffer.width = size.width;
		scaledImageBuffer.height = size.height;
		scaledImageBuffer.rowBytes = scaledImageBuffer.width * sizeof(uint32_t);
		scaledImageBuffer.data = scaledImageData.mutableBytes;
		
		vImage_Error scaleError = vImageScale_ARGB8888(&sourceImageBuffer, &scaledImageBuffer, NULL, 0);
		
		if (scaleError == 0)
		{
			sourceImageBuffer.data = scaledImageBuffer.data;
			sourceImageBuffer.width = scaledImageBuffer.width;
			sourceImageBuffer.height = scaledImageBuffer.height;
			sourceImageBuffer.rowBytes = scaledImageBuffer.rowBytes;
		}
	}
	
	CGImageRef imageRef = NULL;
	
	// Create a device-dependent RGB color space.
	static CGColorSpaceRef colorSpace = NULL;
	if (colorSpace == NULL) 
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	
	// We can't create the image without a color space.
	if (colorSpace != NULL) 
	{
		size_t bufferSize = sourceImageBuffer.rowBytes * sourceImageBuffer.height;
		
		// Create a Quartz direct-access data provider that uses data we supply.
		CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, sourceImageBuffer.data, bufferSize, NULL);
		
		// Create a bitmap image from data supplied by the data provider.
		imageRef = CGImageCreate(sourceImageBuffer.width, sourceImageBuffer.height, 8, 32, sourceImageBuffer.rowBytes,
														 colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
														 dataProvider, NULL, true, kCGRenderingIntentDefault);
		CGDataProviderRelease(dataProvider);
	}
		
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	// NSDate* endScaleImage = [NSDate date];
	// DebugLog(@"vScaledImageFromSampleBuffer: %f", [endScaleImage timeIntervalSinceDate:startScaleImage]);
	
	return imageRef;
}

+ (NSData*)JPEGDataFromCGImage:(CGImageRef)sourceImage compression:(CGFloat)compression
{
	// NSDate* startCompressImage = [NSDate date];
	
	NSMutableData* compressedImageData = nil;
	
	if (sourceImage != NULL)
	{
		compressedImageData = [[NSMutableData alloc] init];
		
		CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)compressedImageData, kUTTypeJPEG, 1, NULL);
		if (imageDestination != NULL)
		{
			NSMutableDictionary* imageProperties = [NSMutableDictionary dictionaryWithCapacity:2];
			[imageProperties setObject:[NSNumber numberWithFloat:compression] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];
			
			CGImageDestinationAddImage(imageDestination, sourceImage, (__bridge CFDictionaryRef)imageProperties);
			BOOL succeeded = CGImageDestinationFinalize(imageDestination);
			if (succeeded == NO)
			{
				compressedImageData = nil;
			}
			
			CFRelease(imageDestination);
			// NSDate* endCompressImage = [NSDate date];
			
			// DebugLog(@"JPEGDataFromCGImage: %f", [endCompressImage timeIntervalSinceDate:startCompressImage]);
		}
	}
	
	return compressedImageData;
}

+ (NSData*)JPEGDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer compression:(CGFloat)compression
{
	// NSDate* startCompressImage = [NSDate date];
	
	NSMutableData* compressedImageData = nil;
	
	CGImageRef sourceImage = [self newImageFromSampleBuffer:sampleBuffer];
	if (sourceImage != NULL)
	{
		compressedImageData = [[NSMutableData alloc] init];

		CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)compressedImageData, kUTTypeJPEG, 1, NULL);
		if (imageDestination != NULL)
		{
			NSMutableDictionary* imageProperties = [NSMutableDictionary dictionaryWithCapacity:2];
			[imageProperties setObject:[NSNumber numberWithFloat:compression] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];
			
			CGImageDestinationAddImage(imageDestination, sourceImage, (__bridge CFDictionaryRef)imageProperties);
			BOOL succeeded = CGImageDestinationFinalize(imageDestination);
			if (succeeded == NO)
			{
				compressedImageData = nil;
			}
			
			CFRelease(imageDestination);
			// NSDate* endCompressImage = [NSDate date];
			
			// DebugLog(@"JPEGDataFromSampleBuffer: %f", [endCompressImage timeIntervalSinceDate:startCompressImage]);
		}
	}
	
	CGImageRelease(sourceImage);
	
	return compressedImageData;
}

+ (NSData*)scaledJPEGDataFromJPEGData:(NSData*)jpegData maxSize:(CGFloat)maxSize compression:(CGFloat)compression
{
	// NSDate* startScaleJPEGData = [NSDate date];
	
	NSMutableData* scaledImageData = [[NSMutableData alloc] init];
	CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)jpegData, NULL);
	if (imageSource != NULL)
	{
		NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:(id)kUTTypeJPEG, kCGImageSourceTypeIdentifierHint,
														 [NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways,
														 [NSNumber numberWithFloat:maxSize], kCGImageSourceThumbnailMaxPixelSize,
														 nil];
		CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);

		NSMutableDictionary* imageProperties = [NSMutableDictionary dictionaryWithCapacity:2];
		[imageProperties setObject:[NSNumber numberWithFloat:compression] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];

		CGImageDestinationRef scaledImageDest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)scaledImageData, kUTTypeJPEG, 1, NULL);
		if (scaledImageDest != NULL)
		{
			CGImageDestinationAddImage(scaledImageDest, thumbnail, (__bridge CFDictionaryRef)imageProperties);
			BOOL compressSucceeded = CGImageDestinationFinalize(scaledImageDest);
			if (compressSucceeded == NO)
			{
				scaledImageData = nil;
			}
			
			CFRelease(scaledImageDest);
		}
		
		CGImageRelease(thumbnail);
		CFRelease(imageSource);
	}
	
	// NSDate* endScaleJPEGData = [NSDate date];
	// DebugLog(@"scaledJPEGDataFromJPEGData: %f", [endScaleJPEGData timeIntervalSinceDate:startScaleJPEGData]);
	
	return scaledImageData;
}

+ (NSData*)scaledImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer maxSize:(CGFloat)maxSize compression:(CGFloat)compressionQuality
{
	// NSDate* startCompressImage = [NSDate date];

	CGImageRef sourceImage = [self newImageFromSampleBuffer:sampleBuffer];
	DebugLog(@"source image width/height: %ld, %ld", CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage));

	NSMutableData* imageData = nil;
	NSMutableData* compressedImageData = nil;

	if (sourceImage != NULL)
	{
		imageData = [[NSMutableData alloc] init];
		// NSDate* startImageDest = [NSDate date];
		CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
		if (imageDestination != NULL)
		{
			NSMutableDictionary* imageProperties = [NSMutableDictionary dictionaryWithCapacity:2];
			[imageProperties setObject:[NSNumber numberWithFloat:compressionQuality] forKey:(NSString*)kCGImageDestinationLossyCompressionQuality];
			
			CGImageDestinationAddImage(imageDestination, sourceImage, (__bridge CFDictionaryRef)imageProperties);
			BOOL succeeded = CGImageDestinationFinalize(imageDestination);
			if (succeeded == NO)
			{
				imageData = nil;
			}
			
			CFRelease(imageDestination);
			// NSDate* endImageDest = [NSDate date];
			
			CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
			if (imageSource != NULL)
			{
				NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:(id)kUTTypeJPEG, kCGImageSourceTypeIdentifierHint,
																 [NSNumber numberWithBool:YES], kCGImageSourceCreateThumbnailFromImageAlways,
																 [NSNumber numberWithFloat:maxSize], kCGImageSourceThumbnailMaxPixelSize,
																 nil];
				CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
				//			DebugLog(@"source: %ld,%ld thumbnail: %ld,%ld", CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage),
				//							 CGImageGetWidth(thumbnail), CGImageGetHeight(thumbnail));
				compressedImageData = [[NSMutableData alloc] init];
				CGImageDestinationRef compressedImageDest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)compressedImageData, kUTTypeJPEG, 1, NULL);
				if (compressedImageDest != NULL)
				{
					CGImageDestinationAddImage(compressedImageDest, thumbnail, (__bridge CFDictionaryRef)imageProperties);
					BOOL compressSucceeded = CGImageDestinationFinalize(compressedImageDest);
					if (compressSucceeded == NO)
					{
						compressedImageData = nil;
					}
					
					CFRelease(compressedImageDest);
				}
				
				CGImageRelease(thumbnail);
				CFRelease(imageSource);
			}
			
			// NSDate* endCompressImage = [NSDate date];
			// DebugLog(@"scaledImageDataFromSampleBuffer: %f (dest %f)", [endCompressImage timeIntervalSinceDate:startCompressImage],
							 // [endImageDest timeIntervalSinceDate:startImageDest]);
		}
	}
	
	CGImageRelease(sourceImage);
	
	return compressedImageData;
}

@end
