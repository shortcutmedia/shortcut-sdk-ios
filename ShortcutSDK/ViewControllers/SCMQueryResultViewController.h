//
//  SCMQueryResultViewController.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMItemViewController.h"
#import "SCMQueryResult.h"

/**
 *  The SCMQueryResultViewController implements a simple item view.
 *
 *  @discussion
 *  The SCMItemViewController displays the result page for any given item recognized by the image
 *  recognition service. You create a new view controller instance by passing an instance of an
 *  SCMQueryResult which you can obtain from e.g. an SCMScannerViewController.
 */
@interface SCMQueryResultViewController : SCMItemViewController

/// @name Creation

/**
 *  Returns a query result view controller instance for the given result.
 *
 *  @param queryResult The query result to display.
 *
 *  @return A new query result view controller instance.
 */
- (instancetype)initWithQueryResult:(SCMQueryResult *)queryResult NS_DESIGNATED_INITIALIZER;

@end
