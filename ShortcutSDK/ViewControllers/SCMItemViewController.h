//
//  SCMItemViewController.h
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

/**
 *  The SCMItemViewController implements a simple item view.
 *
 *  @discussion
 *  The SCMItemViewController displays the result page for any given item stored in the image
 *  recognition service. You have to identify the item you want to display the result page for
 *  with its UUID.
 *
 *  This view controller basically just renders a WKWebView which loads the result page. The view
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
@property (weak, nonatomic) IBOutlet WKWebView *webView;


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

/// @name WKNavigation delegate implementation

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:decidePolicyForNavigationAction:decisionHandler::
 */

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:didStartProvisionalNavigation:
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation;

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:didFinishNavigation:
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:didFailNavigation:withError:
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error;

@end
