//
//  KSCHistogramFilter.m
//  Shortcut
//
//  Created by David Wisti on 3/1/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "KSCHistogramFilter.h"


static const size_t kNumHistogramChannels = 3;
static const size_t kNumHistogramBins = 64;
static const size_t kNumHistogramEntries = kNumHistogramChannels * kNumHistogramBins;
// static const size_t kHistogramChannelSize = kNumHistogramBins * sizeof(uint32_t);	// number of bytes per channel
static const size_t kHistogramBufferSize = kNumHistogramEntries * sizeof(uint32_t);
static const double kDefaultHistogramThreshold = 3000.0;

@interface KSCHistogramFilter (/* Private */)

@property (nonatomic, strong, readwrite) NSMutableData* histogramDataA;
@property (nonatomic, strong, readwrite) NSMutableData* histogramDataB;
@property (nonatomic, assign, readwrite) NSMutableData* previousHistogramData;
@property (nonatomic, assign, readwrite) NSMutableData* currentHistogramData;

@property (nonatomic, assign, readwrite) NSTimeInterval timeIntervalToCalculateHistogram;
@property (nonatomic, assign, readwrite) double distanceFromPreviousHistogram;

- (double)chiSquaredDistanceFromPreviousHistogram;
- (void)swapHistogramData;

@end

@implementation KSCHistogramFilter

@synthesize histogramThreshold;
@synthesize timeIntervalToCalculateHistogram;
@synthesize distanceFromPreviousHistogram;

@synthesize histogramDataA;
@synthesize histogramDataB;
@synthesize previousHistogramData;
@synthesize currentHistogramData;

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.histogramDataA = [[NSMutableData alloc] initWithLength:kHistogramBufferSize];
		self.histogramDataB = [[NSMutableData alloc] initWithLength:kHistogramBufferSize];
		self.currentHistogramData = self.histogramDataA;
		
		self.histogramThreshold = kDefaultHistogramThreshold;
	}
	
	return self;
}

- (void)reset
{
	self.previousHistogramData = nil;
	self.currentHistogramData = self.histogramDataA;
}

- (BOOL)isSampleBufferHistogramSimilar:(CMSampleBufferRef)sampleBuffer
{
	NSDate* startHistogram = [NSDate date];
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	// Lock the base address of the pixel buffer.
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	// Get the number of bytes per row for the pixel buffer.
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	
	// Get the pixel buffer height.
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	// Get the base address of the pixel buffer.
	void* baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	
	// Ensure we clear out any old histogram data
	bzero(self.currentHistogramData.mutableBytes, self.currentHistogramData.length);
	
	size_t maxIndex = (height * bytesPerRow);
	uint32_t* lastAddress = baseAddress + maxIndex;
	register uint32_t* histogram = self.currentHistogramData.mutableBytes;
	register uint32_t channelIndex = 0;
	register uint32_t value = 0;
	
	uint32_t increment = 4;
	for (uint32_t* pixel = baseAddress; pixel < lastAddress; pixel += increment)
	{
		// Put the value of the pixel into a local variable designated to be in a register
		// This provided a 2x performance improvement over the old code that used *pixel in
		// each of the index calculations.
		value = *pixel;
		
		channelIndex = (value & 0x000000FF) >> 2;
		histogram[channelIndex]++;
		
		channelIndex = ((value & 0x0000FF00) >> 10) + kNumHistogramBins;
		histogram[channelIndex]++;
		
		channelIndex = ((value & 0x00FF0000) >> 18) + (2 * kNumHistogramBins);
		histogram[channelIndex]++;
	}

	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

	self.distanceFromPreviousHistogram = [self chiSquaredDistanceFromPreviousHistogram];
	
	NSDate* endHistogram = [NSDate date];
	self.timeIntervalToCalculateHistogram = [endHistogram timeIntervalSinceDate:startHistogram];
	
	BOOL similar = YES;
	if (self.distanceFromPreviousHistogram > self.histogramThreshold)
	{
		// This image is sufficiently different than the last image
		similar = NO;
		
		// Swap histogram data buffers
		[self swapHistogramData];
	}
	
	return similar;
}


- (double)chiSquaredDistanceFromPreviousHistogram
{
	if (self.previousHistogramData == nil)
	{
		return CGFLOAT_MAX;
	}
	
	const uint32_t* histogram = (const uint32_t*)self.currentHistogramData.bytes;
	const uint32_t* previousHistogram = (const uint32_t*)previousHistogramData.bytes;
	
	double distance = 0.0;
	double previous = 0.0;
	double current = 0.0;
	double total = 0.0;
	double difference = 0.0;
	NSInteger numEntries = self.currentHistogramData.length / sizeof(uint32_t);
	
	for (NSInteger i = 0; i < numEntries; i++)
	{
		previous = (double)previousHistogram[i];
		current = (double)histogram[i];
		total = previous + current;
		difference = previous - current;
		if (total > 0.0)
		{
			distance += (difference * difference) / total;
		}
	}
	
	return distance;
}

- (void)swapHistogramData
{
	if (self.currentHistogramData == self.histogramDataA)
	{
		self.currentHistogramData = self.histogramDataB;
		self.previousHistogramData = self.histogramDataA;
	}
	else
	{
		self.currentHistogramData = self.histogramDataA;
		self.previousHistogramData = self.histogramDataB;
	}
}

@end
