//
//  SCMBeaconLookupOperation.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 12/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMBeaconLookupOperation.h"
#import "SCMSDKConfig.h"

@interface SCMBeaconLookupOperation ()

@property (nonatomic, strong, readwrite) CLBeacon *beacon;
@property (nonatomic, strong, readonly) NSURLRequest *request;
@property (nonatomic, strong, readwrite) SCMQueryResponse *queryResponse;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation SCMBeaconLookupOperation

#pragma mark - Properties

@synthesize request = _request;

- (NSURLRequest *)request
{
    if (!_request) {
        _request = [[NSMutableURLRequest alloc] initWithURL:self.lookupURL];
    }
    
    return _request;
}

#pragma mark - Initializer

- (id)initWithBeacon:(CLBeacon *)beacon
{
    if (self = [super init]) {
        self.beacon = beacon;
    }
    return self;
}

#pragma mark - Operation implementation

- (void)operationDidFinishWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error
{
    if (error) {
        self.error = error;
    } else {
        [self parseResponse:response withData:data];
    }
}

- (void)parseResponse:(NSURLResponse *)response withData:(NSData *)data
{
    if (data) {
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:NULL];
        SCMQueryResponse *response = [[SCMQueryResponse alloc] initWithDictionary:responseDictionary];
        
        if (response.hasCurrentMetadata) {
            self.queryResponse = response;
        } else {
            self.error = [NSError errorWithDomain:kSCMQueryResponseErrorDomain
                                             code:kSCMQueryResponseNoMatchingMetadata
                                         userInfo:nil];
        }
    }
}

#pragma mark - Helpers

- (NSURL *)lookupURL
{
    NSString *lookupURLString = [NSString stringWithFormat:@"http://%@/beacons?uuid=%@&major=%@&minor=%@",
                                 [[SCMSDKConfig sharedConfig] itemServerAddress],
                                 self.beacon.proximityUUID.UUIDString,
                                 self.beacon.major,
                                 self.beacon.minor];
    return [NSURL URLWithString:lookupURLString];
}

@end
