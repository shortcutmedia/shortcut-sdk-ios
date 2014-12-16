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
@property (nonatomic, strong, readwrite) NSData *clientData;

- (id)initWithURL:(NSURL *)requestURL imageData:(NSData *)data;
- (NSMutableURLRequest *)signedRequestWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey;

@end
