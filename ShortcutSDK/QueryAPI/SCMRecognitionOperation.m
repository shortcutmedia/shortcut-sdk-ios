//
//  SCMRecognitionRequest.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 14/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMRecognitionOperation.h"
#import "SCMSDKConfig.h"
#import "KWSImageRequest.h"
#import "SCMLocalization.h"

NSString *kSCMRecognitionOperationErrorDomain = @"SCMRecognitionOperationErrorDomain";
int kSCMRecognitionOperationNoMatchingMetadata = -1;


@interface SCMRecognitionOperation ()

@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, strong, readwrite) NSData *imageData;
@property (nonatomic, strong, readonly) NSDictionary *clientData;
@property (nonatomic, strong, readonly) NSURLRequest *request;
@property (nonatomic, strong, readwrite) SCMQueryResponse *queryResponse;
@property (nonatomic, strong, readwrite) NSError *error;
@property NSTimeInterval timeoutInterval;

@end

@implementation SCMRecognitionOperation

#pragma mark - Properties

@synthesize clientData = _clientData;

- (NSDictionary *)clientData
{
    if (!_clientData) {
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:2];
        [data setObject:[NSNumber numberWithInt: 10] forKey:@"max_num_results"];
        [data setObject: @"all" forKey:@"include_target_data"];
        _clientData = data;
    }
    
    return _clientData;
}

@synthesize request = _request;

- (NSURLRequest *)request
{
    if (!_request) {
        KWSImageRequest *imageRequest = [[KWSImageRequest alloc] initWithURL:self.queriesURL imageData:self.imageData timeoutInterval:self.timeoutInterval];
        imageRequest.returnedMetadata = @"details";
        
        if (self.clientData.count > 0) {
            DebugLog(@"clientData: %@", self.clientData);
            imageRequest.clientData = self.clientData;
        }
        
        NSMutableURLRequest *signedRequest = [imageRequest signedRequestWithAccessKey:[[SCMSDKConfig sharedConfig] accessKey]
                                                                            secretToken:[[SCMSDKConfig sharedConfig] secretToken]];
        [signedRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
        if (self.requestLanguage) {
            [signedRequest setValue:self.requestLanguage forHTTPHeaderField:@"Accept-Language"];
        }
        
        _request = signedRequest;
    }
    
    return _request;
}

- (id)initWithImageData:(NSData *)data location:(CLLocation *)queryLocation
{
    self = [super init];
    if (self != nil) {
        self.location = queryLocation;
        self.imageData = data;
        self.timeoutInterval = 15.0;
    }
    
    return self;
}

#pragma mark - Operation implementation

- (void)main
{
    @autoreleasepool {
        NSURLResponse *response = nil;
        NSError *connectionError = nil;
        NSData *data = nil;
        data = [NSURLConnection sendSynchronousRequest:self.request returningResponse:&response error:&connectionError];
        if (connectionError) {
            self.error = connectionError;
        } else {
            [self handleResponse:response withData:data];
        }
    }
}

- (void)handleResponse:(NSURLResponse *)response withData:(NSData *)data
{
    if (data) {
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:NULL];
        SCMQueryResponse *response = [[SCMQueryResponse alloc] initWithDictionary:responseDictionary];
        
        if (response.hasCurrentMetadata) {
            self.queryResponse = response;
        } else {
            self.error = [NSError errorWithDomain:kSCMRecognitionOperationErrorDomain
                                             code:kSCMRecognitionOperationNoMatchingMetadata
                                         userInfo:nil];
        }
    }
}

#pragma mark - Helpers

- (NSURL *)queriesURL
{
    NSString *queriesURLString = [NSString stringWithFormat:@"https://%@/v1/query", [[SCMSDKConfig sharedConfig] queryServerAddress]];
    return [NSURL URLWithString:queriesURLString];
}

- (NSString *)requestLanguage
{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if (!language) {
        language = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    }
    
    return language;
}

@end
