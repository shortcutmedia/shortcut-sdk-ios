//
//  KSCQueryResultViewController.h
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCItemViewController.h"
#import "KSCQueryResult.h"

@interface KSCQueryResultViewController : KSCItemViewController

@property (strong, nonatomic) KSCQueryResult *queryResult;

- (instancetype)initWithQueryResult:(KSCQueryResult *)queryResult;

@end
