//
//  KSCItemViewController.h
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KSCItemViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *webView;

- (instancetype)initWithItemUUID:(NSString *)itemUUID;
- (instancetype)initWithItemUUID:(NSString *)itemUUID imageSHA1:(NSString *)imageSHA1;


#pragma mark - Protected
- (void)webViewDidStartLoad:(UIWebView *)webView;
- (void)webViewDidFinishLoad:(UIWebView *)webView;
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;

@end
