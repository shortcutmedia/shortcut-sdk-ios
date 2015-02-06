//
//  SCMCustomUserAgentProtocol.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 05/02/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMCustomUserAgentProtocol.h"
#import "SCMSDKConfig.h"

NSString* kSCMUserAgentModifiedFlag = @"SCMUserAgentModified";

@interface SCMCustomUserAgentProtocol ()  <NSURLConnectionDelegate>

@property (strong, nonatomic) NSURLConnection *connection;

@end

@implementation SCMCustomUserAgentProtocol

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    id alreadyHandled = [NSURLProtocol propertyForKey:kSCMUserAgentModifiedFlag inRequest:request];
    if (!alreadyHandled) {
        return [self isShortcutServiceRequest:request];
    } else {
        return NO;
    }
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *modifiedRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kSCMUserAgentModifiedFlag inRequest:modifiedRequest];
    
    [self customizeUserAgentForRequest: modifiedRequest];
    
    self.connection = [NSURLConnection connectionWithRequest:modifiedRequest delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
}


#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:redirectResponse];
    }
    return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}

#pragma mark - Internal

+ (BOOL)isShortcutServiceRequest:(NSURLRequest *)request
{
    NSString *scheme = request.URL.scheme;
    
    NSString *fullHost;
    if (!request.URL.port || [request.URL.port isEqualToNumber:@80]) {
        fullHost = request.URL.host;
    } else {
        fullHost = [NSString stringWithFormat:@"%@:%@", request.URL.host, request.URL.port];
    }
    
    return (([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) && [fullHost isEqualToString:[[SCMSDKConfig sharedConfig] itemServerAddress]]);
}

- (void)customizeUserAgentForRequest:(NSMutableURLRequest *)request
{
    NSString *existingUserAgent   = [request valueForHTTPHeaderField:@"User-Agent"];
    NSString *SDKUserAgentPart    = [NSString stringWithFormat:@"ShortcutSDK/%d", SDK_BUILD_NUMBER];
    NSString *customizedUserAgent = [NSString stringWithFormat:@"%@ %@", existingUserAgent, SDKUserAgentPart];
    
    [request setValue:customizedUserAgent forHTTPHeaderField:@"User-Agent"];
}

@end
