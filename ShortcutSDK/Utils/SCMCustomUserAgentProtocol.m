//
//  SCMCustomUserAgentProtocol.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 05/02/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMCustomUserAgentProtocol.h"
#import "SCMSDKConfig.h"

NSString *kSCMUserAgentModifiedFlag = @"SCMUserAgentModified";

@interface SCMCustomUserAgentProtocol () <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

@end

@implementation SCMCustomUserAgentProtocol

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    id alreadyHandled = [NSURLProtocol propertyForKey:kSCMUserAgentModifiedFlag inRequest:request];
    if (!alreadyHandled) {
        return [self isShortcutServiceRequest:request];
    } else {
        return NO;
    }
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *modifiedRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kSCMUserAgentModifiedFlag inRequest:modifiedRequest];

    [self customizeUserAgentForRequest:modifiedRequest];

    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                                                 delegate:self
                                                            delegateQueue:nil];
    self.dataTask = [defaultSession dataTaskWithRequest:modifiedRequest];
    [self.dataTask resume];
}

- (void)stopLoading {
    [self.dataTask cancel];
    self.dataTask = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler {
    if (redirectResponse) {
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:redirectResponse];
    }
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error != nil) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
    self.dataTask = nil;
}

#pragma mark - Internal

+ (BOOL)isShortcutServiceRequest:(NSURLRequest *)request {
    NSString *scheme = request.URL.scheme;

    NSString *fullHost;
    if (!request.URL.port || [request.URL.port isEqualToNumber:@80]) {
        fullHost = request.URL.host;
    } else {
        fullHost = [NSString stringWithFormat:@"%@:%@", request.URL.host, request.URL.port];
    }

    return (([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) && [fullHost isEqualToString:[SCMSDKConfig sharedConfig].itemServerAddress]);
}

- (void)customizeUserAgentForRequest:(NSMutableURLRequest *)request {
    NSString *existingUserAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    NSString *SDKUserAgentPart = [NSString stringWithFormat:@"ShortcutSDK/%d", SDK_BUILD_NUMBER];
    NSString *customizedUserAgent = [NSString stringWithFormat:@"%@ %@", existingUserAgent, SDKUserAgentPart];

    [request setValue:customizedUserAgent forHTTPHeaderField:@"User-Agent"];
}

@end
