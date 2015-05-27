//
//  SCMStatsTracker.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 27/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCMStatsTracker : NSObject

- (void)trackEvent:(NSString *)eventType withItemUUID:(NSUUID *)itemUUID;

@end
