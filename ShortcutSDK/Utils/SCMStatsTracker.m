//
//  SCMStatsTracker.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 27/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMStatsTracker.h"
#import "SCMHTTPOperation.h"
#import "SCMSDKConfig.h"

@interface SCMStatsTracker ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation SCMStatsTracker

#pragma mark - Properties

- (NSOperationQueue *)operationQueue
{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}

#pragma mark - Public

- (void)trackEvent:(NSString *)eventType withItemUUID:(NSUUID *)itemUUID
{
    if (!eventType || !itemUUID) {
        NSLog(@"stats tracking: must provide event type and item uuid!");
        return;
    }
    
    NSDictionary *bodyData      = @{@"event_type" : eventType, @"item_uuid" : itemUUID.UUIDString};
    NSURLRequest *request       = [self buildRequestWithBodyData:bodyData];
    SCMHTTPOperation *operation = [[SCMHTTPOperation alloc] initWithRequest:request];
        
    [self.operationQueue addOperation:operation];
}

#pragma mark - Private

- (NSURLRequest *)buildRequestWithBodyData:(NSDictionary *)content
{
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingPrettyPrinted error:NULL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.trackingURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:bodyData];
    
    return request;
}

- (NSURL *)trackingURL
{
    NSString *trackingURLString = [NSString stringWithFormat:@"http://%@/api/v2/statistics",
                                   [SCMSDKConfig sharedConfig].itemServerAddress];
    return [NSURL URLWithString:trackingURLString];
}

@end
