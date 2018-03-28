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

/// @name Creation

NS_ASSUME_NONNULL_BEGIN
@property (strong, nonatomic, readonly) IBOutlet WKWebView *webView;
NS_ASSUME_NONNULL_END

/**
 *  Returns a item view controller instance for the item with the given UUID.
 *
 *  @param itemUUID The UUID of the item to display.
 *
 *  @return A new item view controller instance.
 */
NS_ASSUME_NONNULL_BEGIN
- (instancetype)initWithItemUUID:(NSString *)itemUUID;
NS_ASSUME_NONNULL_END

/**
 *  Returns a item view controller instance for the item with the given UUID.
 *
 *  @param itemUUID The UUID of the item to display.
 *  @param imageSHA1 This parameter is not used at the moment.
 *
 *  @return A new item view controller instance.
 */
NS_ASSUME_NONNULL_BEGIN
- (instancetype)initWithItemUUID:(NSString *)itemUUID imageSHA1:(NSString *_Nullable)imageSHA1;
NS_ASSUME_NONNULL_END

#pragma mark - Protected

/// @name WKNavigation delegate implementation

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:decidePolicyForNavigationAction:decisionHandler::
 */

NS_ASSUME_NONNULL_BEGIN
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
NS_ASSUME_NONNULL_END

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:didStartProvisionalNavigation:
 */
NS_ASSUME_NONNULL_BEGIN
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation;
NS_ASSUME_NONNULL_END

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:didFinishNavigation:
 */

NS_ASSUME_NONNULL_BEGIN
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
NS_ASSUME_NONNULL_END

/**
 *  You can override this method in a subclass to customize loading behavior.
 *
 *  @see WKNavigationDelegate -webView:didFailNavigation:withError:
 */
NS_ASSUME_NONNULL_BEGIN
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error;
NS_ASSUME_NONNULL_END

@end
