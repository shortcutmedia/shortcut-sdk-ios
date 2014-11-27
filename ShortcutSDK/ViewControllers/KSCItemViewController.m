//
//  KSCItemViewController.m
//  Shortcut
//
//  Created by Severin Schoepke on 24/11/14.
//  Copyright (c) 2014 kooaba AG. All rights reserved.
//

#import "KSCItemViewController.h"
#import "KSCSDKConfig.h"
#import "KSCStatusView.h"

@interface KSCItemViewController () <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet KSCStatusView *statusView;
@property (strong, nonatomic) NSString *itemUUID;
@property (strong, nonatomic) NSString *imageSHA1;
@property (strong, nonatomic, readonly) NSURLRequest *initialRequest;

@end


@implementation KSCItemViewController

@synthesize initialRequest = _initialRequest;

- (NSURLRequest *)initialRequest
{
    if (!_initialRequest && self.itemUUID) {
        NSString* urlString = [NSString stringWithFormat:@"http://%@/app/#/results/%@", [KSCSDKConfig sharedConfig].itemServerAddress, self.itemUUID];
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
    [KSCStatusView class];
    
    return [super initWithNibName:@"KSCItemViewController" bundle:[KSCSDKConfig SDKBundle]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"KSCItemViewController: custom nib ignored. Use init to instantiate an instance");
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    if (self.initialRequest) {
        [self.webView loadRequest:self.initialRequest];
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

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    [self.statusView setStatusTitle:NSLocalizedString(@"Loading…", nil) subtitle:nil showActivityIndicator:YES];
    self.statusView.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    self.statusView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.statusView.hidden = YES;
    DebugLog(@"webView didFailLoadWithError: %@", [error localizedDescription]);
}


@end
