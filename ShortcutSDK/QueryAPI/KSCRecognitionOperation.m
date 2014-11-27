//
//  KSCRecognitionRequest.m
//  Shortcut
//
//  Created by Severin Schoepke on 14/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCRecognitionOperation.h"
#import "KSCSDKConfig.h"
#import "KWSImageRequest.h"

@interface KSCRecognitionOperation ()

@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite) NSData* imageData;
@property (nonatomic, strong, readwrite) NSMutableURLRequest* request;
@property (nonatomic, readwrite) bool closeCamera;
@property (nonatomic, strong, readwrite) KSCQueryResponse* queryResponse;
@property (nonatomic, strong, readwrite) NSError* error;

@end

@implementation KSCRecognitionOperation

@synthesize location;
@synthesize imageData;
@synthesize request;
@synthesize queryResponse;
@synthesize error;

- (id)initWithImageData:(NSData*)data location:(CLLocation*)queryLocation
{
    self = [super init];
    if (self != nil)
    {
        self.location = queryLocation;
        self.imageData = data;
        self.closeCamera = false;
        
        NSString* queriesURLString = [NSString stringWithFormat:@"http://%@/v4/query", [[KSCSDKConfig sharedConfig] queryServerAddress]];
        NSURL* queriesURL = [NSURL URLWithString:queriesURLString];
        
        KWSImageRequest* imageRequest = [[KWSImageRequest alloc] initWithURL:queriesURL imageData:data];
        imageRequest.returnedMetadata = @"details";
        
        NSMutableDictionary* clientData = [NSMutableDictionary dictionaryWithCapacity:4];
        NSString* deviceUUID = [[KSCSDKConfig sharedConfig] clientID];
        if (deviceUUID != nil)
        {
            [clientData setObject:deviceUUID forKey:@"device_id"];
        }
        
        if (queryLocation != nil)
        {
            [clientData setObject:[NSNumber numberWithDouble:queryLocation.coordinate.latitude] forKey:@"latitude"];
            [clientData setObject:[NSNumber numberWithDouble:queryLocation.coordinate.longitude] forKey:@"longitude"];
        }
        
        NSString* bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        NSString* bundleShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString* bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString* appVersion = [NSString stringWithFormat:@"%@-%@/%@", bundleName, bundleShortVersion, bundleVersion];
        [clientData setObject:appVersion forKey:@"application_id"];
        
        if (clientData.count > 0)
        {
            DebugLog(@"clientData: %@", clientData);
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:clientData options:NSJSONWritingPrettyPrinted error:NULL];
            imageRequest.clientData = jsonData;
        }
        
        NSMutableURLRequest* signedRequest = [imageRequest signedRequestWithAccessKey:[[KSCSDKConfig sharedConfig] accessKey]
                                                                            secretKey:[[KSCSDKConfig sharedConfig] secretKey]];
        [signedRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
        
        [self addAcceptLanguageHeaderToRequest:signedRequest];
        
        self.request = signedRequest;
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
        self.queryResponse = [[KSCQueryResponse alloc] initWithDictionary:responseDictionary];

        // TODO: handle API version checking and reporting in a better way...
        bool isOutdated = false;
        bool hasNewer = false;
        
        for (KSCQueryResult* result in self.queryResponse.results)
        {
            bool test = false;
            bool newer = false;
            
            for (NSNumber *number in result.versions)
            {
                if (number.intValue == CURRENT_API_VERSION)
                    test = true;
                else if (number.intValue > CURRENT_API_VERSION)
                    newer = true;
            }
            if (newer) {
                if (!test) {
                    isOutdated = true;
                } else {
                    hasNewer = true;
                }
            }
        }
        
        UIAlertView *alert;
        
        if (isOutdated)
        {
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UpdateRequired", @"Displayed in alertview header for far outdated version") message:NSLocalizedString(@"UpdateRequiredBody", @"Displayed in alertview body for far outdated version") delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.closeCamera = true;
        }
        else if (hasNewer)
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"UpdateAvailable", @"Displayed in alertview header for outdated version") message:NSLocalizedString(@"UpdateAvailableBody", @"Displayed in alertview body for outdated version") delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        if (alert)
            dispatch_async(dispatch_get_main_queue(), ^{[alert show];});
    }
}

#pragma mark - Helpers

- (void)addAcceptLanguageHeaderToRequest:(NSMutableURLRequest*)mutableRequest
{
    NSString* language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if (!language) {
        language = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    }
    
    if (language.length > 0) {
        [mutableRequest setValue:language forHTTPHeaderField:@"Accept-Language"];
    }
}

@end
