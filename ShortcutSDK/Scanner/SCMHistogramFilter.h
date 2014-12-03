//
//  SCMHistogramFilter.h
//  Shortcut
//
//  Created by David Wisti on 3/1/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface SCMHistogramFilter : NSObject

@property (nonatomic, assign, readwrite) double histogramThreshold;
@property (nonatomic, assign, readonly) NSTimeInterval timeIntervalToCalculateHistogram;
@property (nonatomic, assign, readonly) double distanceFromPreviousHistogram;

// Tests the image against the last histogram that was different to see if it is the same.
- (BOOL)isSampleBufferHistogramSimilar:(CMSampleBufferRef)sampleBuffer;

// Resets the state of the filter to remove previous histogram data, etc.
- (void)reset;

@end
