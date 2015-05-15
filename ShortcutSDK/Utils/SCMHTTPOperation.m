//
//  SCMHTTPOperation.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 12/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMHTTPOperation.h"

@interface SCMHTTPOperation ()

@property (strong, nonatomic) NSURLRequest *request;

@end

@implementation SCMHTTPOperation

- (id)initWithRequest:(NSURLRequest *)request
{
    if (self = [super init]) {
        self.request = request;
    }
    return self;
}

#pragma mark - Operation implementation

- (void)main
{
    if (!self.request) {
        return;
    }
    
    @autoreleasepool {
        NSURLResponse *response = nil;
        NSError *error          = nil;
        NSData *data            = nil;
        
        data = [NSURLConnection sendSynchronousRequest:self.request
                                     returningResponse:&response error:&error];
        
        if (error == nil && [response.class isSubclassOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode > 399) {
                error = [NSError errorWithDomain:kSCMHTTPOperationErrorDomain
                                            code:httpResponse.statusCode
                                        userInfo:nil];
            }
        }
        
        [self operationDidFinishWithResponse:response data:data error:error];
    }
}

- (void)operationDidFinishWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error
{
    
}

NSString *kSCMHTTPOperationErrorDomain = @"SCMHTTPOperationErrorDomain";

@end

