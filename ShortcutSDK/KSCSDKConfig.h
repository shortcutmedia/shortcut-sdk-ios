//
//  KSCSDKConfig.h
//  Shortcut
//
//  Created by Severin Schoepke on 17/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCSDKConfig : NSObject

@property (strong, nonatomic) NSString *accessKey;
@property (strong, nonatomic) NSString *secretKey;

@property (strong, nonatomic) NSString *queryServerAddress;
@property (strong, nonatomic) NSString *itemServerAddress;
@property (strong, nonatomic) NSString *clientID;

- (instancetype)init __attribute__((unavailable("use +sharedConfig")));
+ (instancetype)sharedConfig;

+ (NSBundle *)SDKBundle;

@end
