//
//  SCMQueryResultTest.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 27/01/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMTestCase.h"

#import <ShortcutSDK/SCMQueryResult.h>

@interface SCMQueryResultTest : SCMTestCase

@property (nonatomic, strong) NSDictionary *resultDictionary;

@end

@implementation SCMQueryResultTest

- (void)setUp
{
    [super setUp];
    
    self.resultDictionary = @{
        @"metadata": @[
            @{
                @"version": [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION],
                @"uuid": @"d7a11dfa-a061-11e3-a7a3-c86000bc391a",
                @"title": @{
                    @"de": @"Test Item de",
                    @"en": @"Test Item en"
                },
                @"subtitle": @{
                    @"de": @"Tonga Test de",
                    @"en": @"Tonga Test en"
                },
                @"kind": @"Ad",
                @"thumbnail_url": @"http://tonga-production.s3.amazonaws.com/uploads/81/f5/thumbnail_819f5e319d538fb971f5b3344506976ee18d1967-f418779b.jpg",
                @"response": @{
                    @"target": @"web",
                    @"content": @"http://example.com"
                }
            }
        ],
        @"recognitions": @[
            @{
                @"id": @"image.sha1:819f5e319d538fb971f5b3344506976ee18d1967",
                @"score": @1.5763
            }
        ],
        @"score": @1.4652,
        @"title": @"Test Item, Tonga Test"
    };
}

- (SCMQueryResult *)queryResult
{
    return [[SCMQueryResult alloc] initWithDictionary:self.resultDictionary];
}

- (void)testUUID_ReturnsNormalizedUUID
{
    NSString *expectedUUID = @"d7a11dfa-a061-11e3-a7a3-c86000bc391a";
    XCTAssertEqualObjects(self.queryResult.uuid, expectedUUID);
}

- (void)testImageSHA1_ReturnsSHA1
{
    NSString *expectedSHA1 = @"819f5e319d538fb971f5b3344506976ee18d1967";
    XCTAssertEqualObjects(self.queryResult.imageSHA1, expectedSHA1);
}

- (void)testTitle_ReturnsLocalizedTitle
{
    // precondition:
    XCTAssertEqualObjects(@"en", [[NSLocale preferredLanguages] firstObject]);
    
    NSString *expectedTitle = @"Test Item en";
    XCTAssertEqualObjects(self.queryResult.title, expectedTitle);
}

- (void)testTitle_ReturnsGlobalTitleIfLocalizationsAreNotAvailable
{
    // precondition:
    XCTAssertEqualObjects(@"en", [[NSLocale preferredLanguages] firstObject]);
    
    NSMutableDictionary *mutableResultDictionary = [self.resultDictionary mutableCopy];
    [mutableResultDictionary setValue:@[@{@"version" : @"1"}] forKey:@"metadata"];
    self.resultDictionary = mutableResultDictionary;
    
    NSString *expectedTitle = @"Test Item, Tonga Test";
    XCTAssertEqualObjects(self.queryResult.title, expectedTitle);
}

- (void)testSubtitle_ReturnsLocalizedSubtitle
{
    // precondition:
    XCTAssertEqualObjects(@"en", [[NSLocale preferredLanguages] firstObject]);
    
    NSString *expectedSubtitle = @"Tonga Test en";
    XCTAssertEqualObjects(self.queryResult.subtitle, expectedSubtitle);
}

- (void)testSubtitle_ReturnsNilIfLocalizationsAreNotAvailable
{
    // precondition:
    XCTAssertEqualObjects(@"en", [[NSLocale preferredLanguages] firstObject]);
    
    NSMutableDictionary *mutableResultDictionary = [self.resultDictionary mutableCopy];
    [mutableResultDictionary setValue:@[@{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION]}] forKey:@"metadata"];
    self.resultDictionary = mutableResultDictionary;
    
    XCTAssertNil(self.queryResult.subtitle);
}

- (void)testScore_ReturnsRecognitionScore
{
    NSNumber *expectedScore = @1.5763;
    XCTAssertEqualObjects(self.queryResult.score, expectedScore);
}

- (void)testMediumType_ReturnsMediumType
{
    NSString *expectedType = @"Ad";
    XCTAssertEqualObjects(self.queryResult.mediumType, expectedType);
}

- (void)testResponseTarget_ReturnsTarget
{
    NSString *expectedTarget = @"web";
    XCTAssertEqualObjects(self.queryResult.responseTarget, expectedTarget);
}

- (void)testResponseTarget_ReturnsNilIfNotDefined
{
    NSMutableDictionary *mutableResultDictionary = [self.resultDictionary mutableCopy];
    [mutableResultDictionary setValue:@[@{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION]}] forKey:@"metadata"];
    self.resultDictionary = mutableResultDictionary;
    
    XCTAssertNil(self.queryResult.responseTarget);
}

- (void)testResponseContent_ReturnsContent
{
    NSString *expectedContent = @"http://example.com";
    XCTAssertEqualObjects(self.queryResult.responseContent, expectedContent);
}

- (void)testResponseContent_ReturnsNilIfNotDefined
{
    NSMutableDictionary *mutableResultDictionary = [self.resultDictionary mutableCopy];
    [mutableResultDictionary setValue:@[@{@"version" : [NSString stringWithFormat:@"%d", QUERY_API_METADATA_VERSION]}] forKey:@"metadata"];
    self.resultDictionary = mutableResultDictionary;
    
    XCTAssertNil(self.queryResult.responseContent);
}

- (void)testThumbnailURL_ReturnsThumbnail
{
    NSString *expectedURL = @"http://tonga-production.s3.amazonaws.com/uploads/81/f5/thumbnail_819f5e319d538fb971f5b3344506976ee18d1967-f418779b.jpg";
    XCTAssertEqualObjects(self.queryResult.thumbnailURL, expectedURL);
}

@end
