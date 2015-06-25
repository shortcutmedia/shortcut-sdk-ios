//
//  SCMBeaconLookupOperationTest.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/06/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMTestCase.h"

#import <ShortcutSDK/SCMBeaconLookupOperation.h>
#import "SCMMockBeacon.h"
#import <ShortcutSDK/SCMSDKConfig.h>


@interface SCMBeaconLookupOperationTest : SCMTestCase

@property (strong, nonatomic) CLBeacon *beacon;

@end

@implementation SCMBeaconLookupOperationTest


- (SCMBeaconLookupOperation *)createLookupOperation
{
    return [[SCMBeaconLookupOperation alloc] initWithBeacon:self.beacon];
}

- (void)testMain_PopulatesQueryResultWhenLookupSucceeded
{
    self.beacon = [[SCMMockBeacon alloc] initInShortcutRegionWithMajor:@1
                                                                 minor:@1
                                                             proximity:CLProximityNear];
    
    SCMBeaconLookupOperation *operation = [self createLookupOperation];
    [operation main];
    
    XCTAssertNotNil(operation.queryResult);
    XCTAssertNil(operation.error);
}

- (void)testMain_DoesntPopulateQueryResultWhenLookupFailed
{
    self.beacon = [[SCMMockBeacon alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-0000000000000"]
                                                      major:@123
                                                      minor:@456
                                                  proximity:CLProximityNear];
    SCMBeaconLookupOperation *operation = [self createLookupOperation];
    [operation main];
    
    XCTAssertNil(operation.queryResult);
    
    XCTAssertNotNil(operation.error);
    XCTAssertEqual(operation.error.domain, kSCMHTTPOperationErrorDomain);
    XCTAssertEqual(operation.error.code, 404);
}

- (void)testMain_PopulatesErrorWhenErrorOccurs
{
    // cause an error by providing invalid token
    NSString *oldAccessKey = [SCMSDKConfig sharedConfig].accessKey;
    [SCMSDKConfig sharedConfig].accessKey = @"invalid";
    
    SCMBeaconLookupOperation *operation = [self createLookupOperation];
    [operation main];
    
    XCTAssertNil(operation.queryResult);
    XCTAssertNotNil(operation.error);
    
    [SCMSDKConfig sharedConfig].accessKey = oldAccessKey;
}

@end
