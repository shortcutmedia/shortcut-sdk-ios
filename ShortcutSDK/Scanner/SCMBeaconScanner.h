//
//  SCMBeaconScanner.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 11/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCMBeaconScannerDelegate.h"

/// TODO: documentation
@interface SCMBeaconScanner : NSObject

@property (nonatomic, unsafe_unretained, readwrite) id<SCMBeaconScannerDelegate> delegate;

- (void)start;

@end
