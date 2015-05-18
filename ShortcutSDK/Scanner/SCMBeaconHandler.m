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
        [self displayResult:result];
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
    SCMQueryResult * result = [operation.queryResponse.results firstObject];
    if (!result) {
        return;
    }
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        [self displayResult:result];
    } else {
        [self notifyAboutResult:result];
    }
}

#pragma mark - Local notification handling

- (void)requestNotificationAccess
{
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}

- (void)notifyAboutResult:(SCMQueryResult *)result
{
    // keep an array of result uuids for which notifications were already triggered
    // in the user defaults and do not trigger notifications twice for the same result...
    NSArray *resultUUIDsWithNotification = [NSUserDefaults.standardUserDefaults valueForKey:@"resultUUIDsWithNotification"];
    if ([resultUUIDsWithNotification containsObject:result.uuid]) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setValue:[resultUUIDsWithNotification arrayByAddingObject:result.uuid] forKey:@"resultUUIDsWithNotification"];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody   = [NSString stringWithFormat:@"There is a beacon nearby with item %@", result.title];
    notification.alertAction = @"Show";
    notification.soundName   = UILocalNotificationDefaultSoundName;
    notification.userInfo    = @{@"resultJSON" : [result toJSONString]};
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber++;
}

- (SCMQueryResult *)resultFromNotification:(UILocalNotification *)notification
{
    SCMQueryResult *result = nil;
    
    NSString *json = [notification.userInfo objectForKey:@"resultJSON"];
    if (json) {
        result = [[SCMQueryResult alloc] initWithJSONString:json];
    }
    
    return result;
}

- (void)resetNotifications
{
    [NSUserDefaults.standardUserDefaults setValue:@[] forKey:@"resultUUIDsWithNotification"];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

#pragma mark - Delegate interation

- (void)displayResult:(SCMQueryResult *)result
{
    if ([self.delegate respondsToSelector:@selector(beaconHandler:recognizedItem:)]) {
        [self.delegate beaconHandler:self recognizedItem:result];
    }
}

- (void)removeResultDisplay
{
    if ([self.delegate respondsToSelector:@selector(beaconHandlerLostContactToItems:)]) {
        [self.delegate beaconHandlerLostContactToItems:self];
    }
}

@end
