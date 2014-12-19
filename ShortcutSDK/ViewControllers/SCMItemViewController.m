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

@interface SCMItemViewController () <UIWebViewDelegate>

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

- (NSURLRequest *)initialRequest
{
    if (!_initialRequest && self.itemUUID) {
        NSString *urlString = [NSString stringWithFormat:@"http://%@/app/#/results/%@", [SCMSDKConfig sharedConfig].itemServerAddress, self.itemUUID];
        if (self.imageSHA1) {
            urlString = [urlString stringByAppendingFormat:@"_%@", self.imageSHA1];
        }
        _initialRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    }
    return _initialRequest;
}

- (instancetype)initWithItemUUID:(NSString *)itemUUID
{
    return [self initWithItemUUID:itemUUID imageSHA1:nil];
}

- (instancetype)initWithItemUUID:(NSString *)itemUUID imageSHA1:(NSString *)imageSHA1
{
    self = [self init];
    if (self) {
        self.itemUUID  = itemUUID;
        self.imageSHA1 = imageSHA1;
    }
    return self;
}

- (instancetype)init
{
    // Load view classes referenced in xib-file. TODO: is there another way??
    // => the alternative is to force all apps using the SDK to use the -ObjC
    // linker flag, see https://developers.facebook.com/docs/ios/troubleshooting#unrecognizedselector
    [SCMStatusView class];
    
    return [super initWithNibName:@"SCMItemViewController" bundle:[SCMSDKConfig SDKBundle]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"SCMItemViewController: custom nib ignored. Use init to instantiate an instance");
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    self.webView.hidden = YES;
    
    if (self.initialRequest) {
        [self.webView loadRequest:self.initialRequest];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Toolbar and Status

- (IBAction)toolbarButtonClicked:(UIBarButtonItem *)sender
{
    if ([sender isEqual:self.toolbarBackButton]) {
        [self.webView goBack];
    } else if ([sender isEqual:self.toolbarForwardButton]) {
        [self.webView goForward];
    } else if ([sender isEqual:self.toolbarOpenInSafariButton]) {
        [[UIApplication sharedApplication] openURL:self.webView.request.URL];
    }
}

- (void)updateToolbar
{
    // If the web view is not empty or displaying an internal page, then show the toolbar
    // and adjust the web view height.
    if (!self.webView.request ||
        [self.webView.request.URL.absoluteString isEqualToString:@""] ||
        [self.webView.request.URL.host isEqualToString:[SCMSDKConfig sharedConfig].itemServerAddress]) {
        self.toolbar.hidden = YES;
        self.webViewBottomConstraint.constant = 0;
    } else {
        self.toolbar.hidden = NO;
        self.webViewBottomConstraint.constant = self.toolbar.frame.size.height;
    }
        
    self.toolbarBackButton.enabled = [self.webView canGoBack];
    self.toolbarForwardButton.enabled = [self.webView canGoForward];
}

- (void)updateStatusView
{
    [self.statusView setStatusTitle:[SCMLocalization translationFor:@"LoadingTitle" withDefaultValue:@"Loading…"]
                           subtitle:nil
              showActivityIndicator:YES];
    
    self.statusView.hidden = ![self.webView isLoading];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"]) {
        return YES;
    } else if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
        DebugLog(@"webView cannot load request with url %@", request.URL.absoluteString);
        return NO;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    [self updateStatusView];
    [self updateToolbar];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    self.webView.hidden = NO;
    [self updateStatusView];
    [self updateToolbar];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.statusView.hidden = YES;
    DebugLog(@"webView didFailLoadWithError: %@", [error localizedDescription]);
}


@end
