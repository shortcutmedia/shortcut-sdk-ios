//
//  SCMQueryResultViewController.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMQueryResultViewController.h"

@interface SCMQueryResultViewController ()

@property (strong, nonatomic) SCMQueryResult *queryResult;

@end

@implementation SCMQueryResultViewController

- (instancetype)initWithQueryResult:(SCMQueryResult *)result
{
    self.queryResult = result;
    return [super initWithItemUUID:self.queryResult.uuid imageSHA1:self.queryResult.imageSHA1];
}

@end
