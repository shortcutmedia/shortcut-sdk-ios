//
//  SCMQueryResponseTest.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 26/01/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMTestCase.h"

#import <ShortcutSDK/SCMQueryResponse.h>

@interface SCMQueryResponseTest : SCMTestCase

@property (nonatomic, strong) NSDictionary *responseDictionary;

@end

@implementation SCMQueryResponseTest

- (void)setUp
{
    [super setUp];
    
    self.responseDictionary = @{
        @"query_id" : @"bdbc3b02c9564975b6535698d3988fc8",
        @"results" : @[
            @{
                @"title" : @"good result",
                @"recognitions" : @{@"id" : @"image.sha1:819f5e319d538fb971f5b3344506976ee18d1967"},
                @"metadata" : @[
                    @{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION], @"title" : @"first metadata title"}
                ]
            },
            @{
                @"title" : @"second good result",
                @"recognitions" : @{@"id" : @"image.sha1:7e994c8549e94c93b0316593be6804d8"},
                @"metadata" : @[
                    @{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION], @"title" : @"second metadata title 1"},
                    @{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION+1], @"title" : @"second metadata title 2"}
                ]
            },
            @{
                @"title" : @"wrong version",
                @"recognitions" : @{@"id" : @"image.sha1:393e109166fd4e2ba0eb28acdb9e98d8"},
                @"metadata" : @[
                    @{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION+1], @"title" : @"third metadata title"}
                ]
            },
            @{
                @"title" : @"no recognition",
                @"recognitions" : @{@"id" : @""},
                @"metadata" : @[
                    @{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION], @"title" : @"fourth metadata title"}
                ]
            }
        ]
    };
}

- (SCMQueryResponse *)queryResponse
{
    return [[SCMQueryResponse alloc] initWithDictionary:self.responseDictionary];
}

- (void)testQueryUUID_ReturnsNormalizedUUID
{
    NSString *expectedUUID = @"bdbc3b02-c956-4975-b653-5698d3988fc8";
    XCTAssertEqualObjects(self.queryResponse.queryUUID, expectedUUID);
}

- (void)testResults_ReturnsResultsWithRecognitionsAndMatchingMetadataVersion
{
    XCTAssertEqual(self.queryResponse.results.count, 2);
    
    id object1 = [self.queryResponse.results objectAtIndex:0];
    XCTAssertEqualObjects([object1 class], [SCMQueryResult class]);
    SCMQueryResult *result1 = (SCMQueryResult*)object1;
    XCTAssertEqualObjects(result1.title, @"good result");
    
    id object2 = [self.queryResponse.results objectAtIndex:1];
    XCTAssertEqualObjects([object2 class], [SCMQueryResult class]);
    SCMQueryResult *result2 = (SCMQueryResult*)object2;
    XCTAssertEqualObjects(result2.title, @"second good result");
}

@end
