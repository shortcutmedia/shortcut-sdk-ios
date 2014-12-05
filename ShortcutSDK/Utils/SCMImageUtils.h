//
//  SCMImageUtils.h
//  Shortcut
//
//  Created by David Wisti on 12/6/11.
//  Copyright (c) 2011 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface SCMImageUtils : NSObject

+ (NSData*)scaledImageDataWithImage:(CGImageRef)sourceImage orientation:(NSInteger)imageOrientation maxSize:(CGFloat)maximumImageSize compression:(CGFloat)compressionQuality zoomFactor:(CGFloat)zoomFactor;
+ (NSData*)scaledImageDataWithJPEGData:(NSData*)jpegData orientation:(NSInteger)imageOrientation maxSize:(CGFloat)maximumImageSize compression:(CGFloat)compressionQuality zoomFactor:(CGFloat)zoomFactor;
+ (CGImageRef)newScaledImageWithImage:(CGImageRef)sourceImage maxSize:(CGFloat)size zoomFactor:(CGFloat)zoomFactor;
+ (CGImageRef)newThumbnailFromImage:(CGImageRef)sourceImage withSize:(CGFloat)thumbnailSize;
+ (UIImage*)imageWithCompressedData:(NSData*)compressedData;
+ (UIImage*)thumbnailWithCompressedData:(NSData*)compressedData thumbnailSize:(CGFloat)size;
+ (UIImage*)imageFromURL:(NSURL*)imageURL;
+ (UIImage*)thumbnailFromURL:(NSURL*)imageURL maxSize:(CGFloat)maxSize;
+ (CGImageRef)newImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (NSData*)compressedImageDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer size:(CGSize)size compression:(CGFloat)compression;
+ (NSData*)JPEGDataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer compression:(CGFloat)compression;
+ (NSData*)scaledJPEGDataFromJPEGData:(NSData*)jpegData maxSize:(CGFloat)maxSize compression:(CGFloat)compression;
+ (CGImageRef)newScaledImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer size:(CGSize)size;
+ (NSData*)JPEGDataFromCGImage:(CGImageRef)sourceImage compression:(CGFloat)compression;
+ (NSData*)scaledImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer maxSize:(CGFloat)maxSize compression:(CGFloat)compression;

+ (CGImageRef)newImageForZXingFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+ (UIImage*)SDKBundleImageNamed:(NSString*)fileName;

@end
