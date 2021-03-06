//
//  SCMItemViewController.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 Shortcut Media AG. All rights reserved.
//

#import "SCMItemViewController.h"
#import "SCMSDKConfig.h"
#import "SCMStatusView.h"
#import "SCMLocalization.h"
#import "SCMCustomUserAgentProtocol.h"

@interface SCMItemViewController () <WKNavigationDelegate>

@property (strong, nonatomic, readwrite) IBOutlet WKWebView *webView;
@property (strong, nonatomic) IBOutlet SCMStatusView *statusView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *toolbarBackButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *toolbarForwardButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *toolbarOpenInSafariButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewBottomConstraint;

@property (strong, nonatomic) NSString *itemUUID;
@property (strong, nonatomic) NSString *imageSHA1;
@property (strong, nonatomic, readonly) NSURLRequest *initialRequest;

@end


@implementation SCMItemViewController

@synthesize initialRequest = _initialRequest;

- (instancetype)initWithItemUUID:(NSString *)itemUUID {
    return [self initWithItemUUID:itemUUID imageSHA1:nil];
}

- (instancetype)initWithItemUUID:(NSString *)itemUUID imageSHA1:(NSString *)imageSHA1 {
    [SCMStatusView class];
    self = [super initWithNibName:@"SCMItemViewController" bundle:[SCMSDKConfig SDKBundle]];
    if (self) {
        self.itemUUID = itemUUID;
        self.imageSHA1 = imageSHA1;
    }
    return self;
}

- (instancetype)init {
    // Load view classes referenced in xib-file. TODO: is there another way??
    // => the alternative is to force all apps using the SDK to use the -ObjC
    // linker flag, see https://developers.facebook.com/docs/ios/troubleshooting#unrecognizedselector
    [SCMStatusView class];

    return [super initWithNibName:@"SCMItemViewController" bundle:[SCMSDKConfig SDKBundle]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSLog(@"SCMItemViewController: custom nib ignored. Use init to instantiate an instance");
    return [self init];
}

- (NSURLRequest *)initialRequest {
    if (!_initialRequest && self.itemUUID) {
        NSString *urlString = [NSString stringWithFormat:@"http://%@/app/#/results/%@", [SCMSDKConfig sharedConfig].itemServerAddress, self.itemUUID];
        if (self.imageSHA1) {
            urlString = [urlString stringByAppendingFormat:@"_%@", self.imageSHA1];
        }
        _initialRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    }
    return _initialRequest;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView.navigationDelegate = self;
    self.webView.hidden = YES;

    [self registerUserAgentCustomization];

    if (self.initialRequest) {
        [self.webView loadRequest:self.initialRequest];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Position the web view below the status bar on iOS7 when not displayed in a
    // navigation controller
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        if (!self.navigationController) {
            self.webViewTopConstraint.constant = 20;
        }
    }
}

#pragma mark - Orientations

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Toolbar and Status

- (IBAction)toolbarButtonClicked:(UIBarButtonItem *)sender {
    if ([sender isEqual:self.toolbarBackButton]) {
        if ([self.webView isKindOfClass:[WKWebView class]] && [self.webView respondsToSelector:@selector(goBack)]) {
            [self.webView goBack];
        }
    } else if ([sender isEqual:self.toolbarForwardButton]) {
        [self.webView goForward];
    } else if ([sender isEqual:self.toolbarOpenInSafariButton]) {
        [[UIApplication sharedApplication] openURL:self.webView.URL
                                           options:@{}
                                 completionHandler:nil];
    }
}

- (void)updateToolbar {
    // If the web view is not empty or displaying an internal page, then show the toolbar
    // and adjust the web view height.
    if (!self.webView.URL ||
            [self.webView.URL.absoluteString isEqualToString:@""] ||
            [self.webView.URL.host isEqualToString:[SCMSDKConfig sharedConfig].itemServerAddress]) {
        self.toolbar.hidden = YES;
        self.webViewBottomConstraint.constant = 0;
    } else {
        self.toolbar.hidden = NO;
        self.webViewBottomConstraint.constant = self.toolbar.frame.size.height;
    }

    self.toolbarBackButton.enabled = self.webView.canGoBack;
    self.toolbarForwardButton.enabled = self.webView.canGoForward;
}

- (void)updateStatusView {
    [self.statusView setStatusTitle:[SCMLocalization translationFor:@"LoadingTitle" withDefaultValue:@"Loading…"]
                           subtitle:nil
              showActivityIndicator:YES];

    self.statusView.hidden = !self.webView.loading;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([navigationAction.request.URL.scheme isEqualToString:@"http"] || [navigationAction.request.URL.scheme isEqualToString:@"https"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL
                                           options:@{}
                                 completionHandler:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        DebugLog(@"webView cannot load request with url %@", navigationAction.request.URL.absoluteString);
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self updateStatusView];
    [self updateToolbar];

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.webView.hidden = NO;
    [self updateStatusView];
    [self updateToolbar];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.statusView.hidden = YES;
    DebugLog(@"webView didFailLoadWithError: %@", [error localizedDescription]);
}

#pragma mark - Helper

- (void)registerUserAgentCustomization {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSURLProtocol registerClass:[SCMCustomUserAgentProtocol class]];
    });
}

@end
