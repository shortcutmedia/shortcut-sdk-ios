//
//  SCMItemViewController.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  The SCMItemViewController implements a simple item view.
 *
 *  @discussion
 *  The SCMItemViewController displays the result page for any given item stored in the image
 *  recognition service. You have to identify the item you want to display the result page for
 *  with its UUID.
 *
 *  This view controller basically just renders a UIWebView which loads the result page. The view
 *  controller instance is the delegate of the web view and the delegate methods are exposed in the
 *  public API; so if you want to customize the loading process you can subclass this class and hook
 *  into the web view delegate methods.
 *
 *  @see SCMQueryResultViewController for a subclass with a more convenient API.
 */
@interface SCMItemViewController : UIViewController

/**
 *  The web view instance that is used to render the result page.
 */
@property (strong, nonatomic) IBOutlet UIWebView *webView;


/// @name Creation

/**
 *  Returns a item view controller instance for the item with the given UUID.
 *
 *  @param itemUUID The UUID of the item to display.
 *
 *  @return A new item view controller instance.
 */
- (instancetype)initWithItemUUID:(NSString *)itemUUID;

/**
 *  Returns a item view controller instance for the item with the given UUID.
 *
 *  @param itemUUID The UUID of the item to display.
 *  @param imageSHA1 This parameter is not used at the moment.
 *
 *  @return A new item view controller instance.
 */
- (instancetype)initWithItemUUID:(NSString *)itemUUID imageSHA1:(NSString *)imageSHA1 NS_DESIGNATED_INITIALIZER;


#pragma mark - Protected

/// @name UIWebView delegate implementation

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see UIWebViewDelegate -webView:shouldStartLoadWithRequest:navigationType:
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see UIWebViewDelegate -webViewDidStartLoad:
 */
- (void)webViewDidStartLoad:(UIWebView *)webView;

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see UIWebViewDelegate -webViewDidFinishLoad:
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView;

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see UIWebViewDelegate -webView:didFailLoadWithError:
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;

@end
