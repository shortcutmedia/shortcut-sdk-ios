//
//  SCMBase64Utils.h
//  ShortcutSDK
//
//  Created by David Wisti on 3/14/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SCMBase64Utils : NSObject

+ (NSString*)encodeBase64WithData:(NSData*)objData;

@end
