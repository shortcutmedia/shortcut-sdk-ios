//
//  SCMBeaconHandler.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 18/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMBeaconHandler.h"
#import "SCMBeaconScanner.h"
#import "SCMBeaconLookupOperation.h"

@interface SCMBeaconHandler () <SCMBeaconScannerDelegate>

@property (strong, nonatomic) SCMBeaconScanner *beaconScanner;
@property (strong, nonatomic) NSOperationQueue *lookupQueue;

@end

@implementation SCMBeaconHandler

#pragma mark - Properties

- (SCMBeaconScanner *)beaconScanner
{
    if (!_beaconScanner) {
        SCMBeaconScanner *scanner = [[SCMBeaconScanner alloc] init];
        scanner.delegate = self;
        _beaconScanner = scanner;
    }
    return _beaconScanner;
}

- (NSOperationQueue *)lookupQueue
{
    if (!_lookupQueue) {
        _lookupQueue = [[NSOperationQueue alloc] init];
    }
    return _lookupQueue;
}

#pragma mark - Initializer

- (instancetype)initWithDelegate:(id<SCMBeaconHandlerDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - Public API

- (void)start
{
    [self requestNotificationAccess];
    [self resetNotifications];
    
    [self.beaconScanner start];
}

- (void)stop
{
    [self.beaconScanner stop];
}

- (void)handleNotification:(UILocalNotification *)notification
{
    SCMQueryResult *result = [self resultFromNotification:notification];
    if (result) {
        [self displayResult:result fromNotification:YES];
    }
    
    [self resetNotifications];
}

#pragma mark - SCMBeaconScannerDelegate

- (void)beaconScanner:(SCMBeaconScanner *)beaconScanner didSelectBeacon:(CLBeacon *)beacon
{
    if (beacon) {
        [self sendLookupOperationWithBeacon:beacon];
    } else {
        [self removeResultDisplay];
    }
}

#pragma mark - Beacon lookup

- (void)sendLookupOperationWithBeacon:(CLBeacon *)beacon
{
    SCMBeaconLookupOperation *operation = [[SCMBeaconLookupOperation alloc] initWithBeacon:beacon];
    // TODO: add timeout?
    //operation.responseTimeoutInterval = kMaximumServerResponseTime;
    
    UIBackgroundTaskIdentifier lookupTask = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:lookupTask];
    }];
    
    __weak SCMBeaconLookupOperation *completedOperation = operation;
    [operation setCompletionBlock:^{
        [self lookupOperationCompleted:completedOperation withBackgroundTask:lookupTask];
    }];
    
    [self.lookupQueue addOperation:operation];
}

- (void)lookupOperationCompleted:(SCMBeaconLookupOperation *)operation withBackgroundTask:(UIBackgroundTaskIdentifier)task
{
    if (!operation.error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleResponseOfLookupOperation:operation];
            [UIApplication.sharedApplication endBackgroundTask:task];
        });
    } else {
        // TODO: error handling/signalling?
        
        [UIApplication.sharedApplication endBackgroundTask:task];
    }
}

- (void)handleResponseOfLookupOperation:(SCMBeaconLookupOperation *)operation
{
    if (!operation.queryResult) {
        return;
    }
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        [self displayResult:operation.queryResult fromNotification:NO];
    } else {
        [self notifyOnceAboutResult:operation.queryResult];
    }
}

#pragma mark - Local notification handling

static NSString *kResultsWithNotificationKey = @"resultsWithNotification";
static NSString *kResultJSONKey = @"resultJSON";

- (void)requestNotificationAccess
{
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}

- (UILocalNotification *)notificationFromResult:(SCMQueryResult *)result
{

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody   = [NSString stringWithFormat:@"There is a beacon nearby with item %@", result.title];
    notification.alertAction = @"Show";
    notification.soundName   = UILocalNotificationDefaultSoundName;
    notification.userInfo    = @{kResultJSONKey : [result toJSONString]};
    
    return notification;
}

- (SCMQueryResult *)resultFromNotification:(UILocalNotification *)notification
{
    SCMQueryResult *result = nil;
    
    NSString *json = [notification.userInfo objectForKey:kResultJSONKey];
    if (json) {
        result = [[SCMQueryResult alloc] initWithJSONString:json];
    }
    
    return result;
}

- (BOOL)notificationExistsForResult:(SCMQueryResult *)result
{
    NSArray *alreadyHandledUUIDs = [NSUserDefaults.standardUserDefaults valueForKey:kResultsWithNotificationKey];
    return alreadyHandledUUIDs && [alreadyHandledUUIDs containsObject:result.uuid];
}

- (void)rememberNotificationForResult:(SCMQueryResult *)result
{
    NSArray *alreadyHandledUUIDs = [NSUserDefaults.standardUserDefaults valueForKey:kResultsWithNotificationKey];
    if (!alreadyHandledUUIDs) { alreadyHandledUUIDs = [NSArray array]; }
    
    alreadyHandledUUIDs = [alreadyHandledUUIDs arrayByAddingObject:result.uuid];
    
    [NSUserDefaults.standardUserDefaults setValue:alreadyHandledUUIDs forKey:kResultsWithNotificationKey];
}

- (void)resetNotifications
{
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kResultsWithNotificationKey];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

#pragma mark - Actions

- (void)displayResult:(SCMQueryResult *)result fromNotification:(BOOL)fromNotification
{
    if ([self.delegate respondsToSelector:@selector(beaconHandler:recognizedItem:fromNotification:)]) {
        [self.delegate beaconHandler:self recognizedItem:result fromNotification:fromNotification];
    }
}

- (void)notifyOnceAboutResult:(SCMQueryResult *)result
{
    if ([self notificationExistsForResult:result]) {
        return;
    } else {
        [self rememberNotificationForResult:result];
    }
    
    UILocalNotification *notification = [self notificationFromResult:result];
    
    if ([self.delegate respondsToSelector:@selector(beaconHandler:willPresentNotification:forItem:)]) {
        [self.delegate beaconHandler:self willPresentNotification:notification forItem:result];
    }
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber++;
}

- (void)removeResultDisplay
{
    if ([self.delegate respondsToSelector:@selector(beaconHandlerLostContactToItems:)]) {
        [self.delegate beaconHandlerLostContactToItems:self];
    }
}

@end
