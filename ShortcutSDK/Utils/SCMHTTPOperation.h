//
//  SCMHTTPOperation.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 12/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  An SCMHTTPOperation performs a http request. This class is used only internally
 *  and meant to be subclassed...
 *
 *  TODO: make this usable directly?
 *
 *  @discussion
 *  This is a subclass of NSOperation. After you have initialized and configured
 *  an instance you must kick it off by either calling the SCMHTTPOperation -start
 *  method on it or by scheduling it in an operation queue.
 *  @see NSOperationQueue -addOperation:
 */
@interface SCMHTTPOperation : NSOperation

- (instancetype)initWithRequest:(NSURLRequest *)request;
- (void)operationDidFinishWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error;

/**
 *  Error domain for http errors.
 *
 *  @discussion
 *  Errors in this domain represent http errors. Their code corresponds to the http status code.
 */
extern NSString *kSCMHTTPOperationErrorDomain;

@end
