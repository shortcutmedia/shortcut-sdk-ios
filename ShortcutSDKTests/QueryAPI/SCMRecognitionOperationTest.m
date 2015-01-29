//
//  SCMRecognitionOperationTest.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 27/01/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMTestCase.h"

#import <ShortcutSDK/SCMRecognitionOperation.h>
#import <ShortcutSDK/SCMSDKConfig.h>

@interface SCMRecognitionOperationTest : SCMTestCase

@property (strong, nonatomic) NSData *imageData;
@property (strong, nonatomic) CLLocation *location;

@end

@implementation SCMRecognitionOperationTest


- (SCMRecognitionOperation *)createRecognitionOperation
{
    return [[SCMRecognitionOperation alloc] initWithImageData:self.imageData location:self.location];
}

- (void)testMain_PopulatesQueryResponseWithResultsWhenImageWasRecognized
{
    self.imageData = [NSData dataWithContentsOfURL:[[SCMTestCase testBundle] URLForResource:@"recognizable_image" withExtension:@"jpg"]];
    
    SCMRecognitionOperation *operation = [self createRecognitionOperation];
    [operation main];
    
    XCTAssertNotNil(operation.queryResponse);
    XCTAssertGreaterThan(operation.queryResponse.results.count, 0);
    XCTAssertNil(operation.error);
}

- (void)testMain_DoesntPopulateQueryResponseWithResultsWhenImageWasNotRecognized
{
    self.imageData = [NSData dataWithContentsOfURL:[[SCMTestCase testBundle] URLForResource:@"unrecognizable_image" withExtension:@"jpg"]];
    
    SCMRecognitionOperation *operation = [self createRecognitionOperation];
    [operation main];
    
    XCTAssertNotNil(operation.queryResponse);
    XCTAssertEqual(operation.queryResponse.results.count, 0);
    XCTAssertNil(operation.error);
}

- (void)testMain_PopulatesErrorWhenErrorOccurs
{
    // cause an error by providing invalid token
    NSString *oldAccessKey = [SCMSDKConfig sharedConfig].accessKey;
    [SCMSDKConfig sharedConfig].accessKey = @"invalid";
    
    SCMRecognitionOperation *operation = [self createRecognitionOperation];
    [operation main];
    
    XCTAssertNil(operation.queryResponse);
    XCTAssertNotNil(operation.error);
    
    [SCMSDKConfig sharedConfig].accessKey = oldAccessKey;
}

@end
