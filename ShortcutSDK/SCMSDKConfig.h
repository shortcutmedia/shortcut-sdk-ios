//
//  SCMSDKConfig.h
//  Shortcut
//
//  Created by Severin Schoepke on 17/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  An SCMSDKConfig object wraps some global configuration options of the Shortcut SDK.
 *  
 *  @discussion
 *  It is implemented as a singleton: Use the SCMSDKConfig +sharedConfig method to get the
 *  singleton instance.
 */
@interface SCMSDKConfig : NSObject


/// @name Access keys

/**
 *  The access key that the SDK uses to connect to the image recognition service.
 *
 *  @discussion
 *  This is available from your account in the Shortcut Manager. You HAVE to specify
 *  this property, otherwise the image recognition will not work.
 */
@property (strong, nonatomic) NSString *accessKey;

/**
 *  The secret key that the SDK uses to connect to the image recognition service.
 *
 *  @discussion
 *  This is available from your account in the Shortcut Manager. You HAVE to specify
 *  this property, otherwise the image recognition will not work.
 */
@property (strong, nonatomic) NSString *secretKey;


/// @name Localization setup

/**
 *  The name of the strings table file where translations are looked up.
 *
 *  @discussion
 *  By default, this is set to @"Localizable". Change it if you have your
 *  translations in a different table file.
 *
 *  @see SCMSDKConfig -localizationTableBundle
 */
@property (strong, nonatomic) NSString *localizationTable;

/**
 *  The bundle that contains the strings table file where translations are looked up.
 *
 *  @discussion
 *  By default, this is set to the main bundle. Change it if you have your
 *  translation table file in a different bundle.
 *
 *  @see SCMSDKConfig -localizationTable
 */
@property (strong, nonatomic) NSBundle *localizationTableBundle;


/// @name Internal/Testing properties

/**
 *  The address of the image recognition server.
 *
 *  @discussion
 *  This returns the correct address of the image recognition server by default.
 *  
 *  @warning You do not change this normally, it is just available for testing purposes.
 */
@property (strong, nonatomic) NSString *queryServerAddress;

/**
 *  The address of the item server.
 *
 *  @discussion
 *  This returns the correct address of the item server by default.
 *
 *  @warning You do not change this normally, it is just available for testing purposes.
 */
@property (strong, nonatomic) NSString *itemServerAddress;

/**
 *  A unique string identifying the current user/device.
 *
 *  @discussion
 *  This value is used internally for some statistics. If you already have a user or
 *  device identifier then please assign it to this property.
 */
@property (strong, nonatomic) NSString *clientID;


/// @name Accessing the global instance

/**
 *  This class is a singleton. You cannot instantiate new instances.
 *  Use the SCMSDKConfig +sharedConfig method to get the singleton instance.
 */
- (instancetype)init __attribute__((unavailable("use SCMSDKConfig +sharedConfig")));

/**
 *  Returns the singleton instance.
 *
 *  @return The global config instance.
 */
+ (instancetype)sharedConfig;

+ (NSBundle *)SDKBundle;

@end
