//
//  SCMQueryResultViewController.h
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "SCMItemViewController.h"
#import "SCMQueryResult.h"

@interface SCMQueryResultViewController : SCMItemViewController

@property (strong, nonatomic) SCMQueryResult *queryResult;

- (instancetype)initWithQueryResult:(SCMQueryResult *)queryResult;

@end
