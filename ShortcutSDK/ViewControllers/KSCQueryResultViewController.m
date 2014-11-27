//
//  KSCQueryResultViewController.m
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCQueryResultViewController.h"

@interface KSCQueryResultViewController ()

@end

@implementation KSCQueryResultViewController

- (instancetype)initWithQueryResult:(KSCQueryResult *)result
{
    self.queryResult = result;
    return [super initWithItemUUID:self.queryResult.uuid imageSHA1:self.queryResult.imageSHA1];
}

@end
