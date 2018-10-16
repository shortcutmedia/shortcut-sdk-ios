//
//  KWSImageRequest.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/14/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KWSImageRequest : NSObject

@property (nonatomic, strong, readwrite) NSString *returnedMetadata;
@property (nonatomic, strong, readwrite) NSDictionary *clientData;

- (id)initWithURL:(NSURL *)requestURL imageData:(NSData *)data timeoutInterval:(NSTimeInterval)timeoutInterval;

- (NSMutableURLRequest *)signedRequestWithAccessKey:(NSString *)accessKey secretToken:(NSString *)secretToken;

@end
