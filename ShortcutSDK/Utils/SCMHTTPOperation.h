//
//  SCMHTTPOperation.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 12/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCMHTTPOperation : NSOperation

- (instancetype)initWithRequest:(NSURLRequest *)request;
- (void)operationDidFinishWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error;

@end
