//
//  SCMBeaconScanner.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 11/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMBeaconScanner.h"
#import <CoreLocation/CoreLocation.h>

NSString *kSCMShortcutRegionUUID = @"1978F86D-FA83-484B-9624-C360AC3BDB71";

@interface SCMBeaconScanner () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSMutableDictionary *rangedBeacons;
@property (strong, nonatomic) CLBeacon *selectedBeacon;

@end

@implementation SCMBeaconScanner

#pragma mark - Properties

- (NSMutableDictionary *)rangedBeacons
{
    if (!_rangedBeacons) {
        _rangedBeacons = [NSMutableDictionary dictionary];
    }
    return _rangedBeacons;
}

#pragma mark - Initializers

- (instancetype)init
{
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    
    return self;
}

#pragma mark - Public API

- (void)start
{
    if (!self.isAuthorized) {
        // TODO: check that NSLocationAlwaysUsageDescription is set in Info.plist
        [self.locationManager requestAlwaysAuthorization];
        return;
    }
    
    // cleanup: Remove all monitorings to clean out legacy monitorings.
    //          This is needed since monitored regions are persisted on a
    //          system level and we want to start from a fresh state whenever
    //          a new instance of SCMBeaconScanner is started.
    for (CLBeaconRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    [self.locationManager requestStateForRegion:self.regionToMonitor];
}

#pragma mark - Private methods

- (BOOL)isAuthorized
{
    return CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
}

- (CLRegion *)regionToMonitor
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kSCMShortcutRegionUUID];
    NSString *identifier = kSCMShortcutRegionUUID;
    return [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
}

- (void)selectBeacon
{
    // find the currently selected beacon
    CLBeacon *previouslySelectedBeacon;
    for (CLRegion *region in self.rangedBeacons) {
        for (CLBeacon *beacon in self.rangedBeacons[region]) {
            if ([beacon.proximityUUID isEqual:self.selectedBeacon.proximityUUID] &&
                [beacon.major isEqual:self.selectedBeacon.major] &&
                [beacon.minor isEqual:self.selectedBeacon.minor]) {
                previouslySelectedBeacon = beacon;
                break;
            }
        }
    }
    
    // find the closest beacon
    CLBeacon *closestBeacon;
    if (previouslySelectedBeacon.proximity != CLProximityUnknown) {
        closestBeacon = previouslySelectedBeacon;
    }
    for (CLRegion *region in self.rangedBeacons) {
        for (CLBeacon *beacon in self.rangedBeacons[region]) {
            if (beacon.proximity == CLProximityUnknown) {
                continue;
            }
            
            if (closestBeacon == nil || closestBeacon.proximity > beacon.proximity) {
                closestBeacon = beacon;
            }
        }
    }
    
    // select the closest beacon if it is closer than the previously selected one
    if (closestBeacon && (closestBeacon.proximity < previouslySelectedBeacon.proximity || previouslySelectedBeacon == nil)) {
        self.selectedBeacon = closestBeacon;
        DebugLog(@"LM did select beacon: %@/%@ (%ld)", closestBeacon.major, closestBeacon.minor, (long)closestBeacon.proximity);
        if ([self.delegate respondsToSelector:@selector(beaconScanner:didSelectBeacon:)]) {
            [self.delegate beaconScanner:self didSelectBeacon:self.selectedBeacon];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (self.isAuthorized) {
        [self.locationManager requestStateForRegion:self.regionToMonitor];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    DebugLog(@"LM did determine state of region %@: %ld", region.identifier, (long)state);
    
    if (![manager.monitoredRegions containsObject:region]) {
        DebugLog(@"LM starts monitoring region %@", region.identifier);
        [self.locationManager startMonitoringForRegion:region];
    }
    
    if (state == CLRegionStateInside) {
        [self locationManager:manager didEnterRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    DebugLog(@"LM did enter region %@", region.identifier);
    
    if ([region.class isSubclassOfClass:CLBeaconRegion.class]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        
        if (![self.rangedBeacons.allKeys containsObject:beaconRegion]) {
            [self.rangedBeacons setObject:@[] forKey:beaconRegion];
        }
        
        if (![manager.rangedRegions containsObject:beaconRegion]) {
            DebugLog(@"LM starts ranging region %@", beaconRegion.identifier);
            [manager startRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    DebugLog(@"LM did exit region %@", region.identifier);
    
    if ([region.class isSubclassOfClass:CLBeaconRegion.class]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        
        DebugLog(@"LM stops ranging region %@", beaconRegion.identifier);
        [manager stopRangingBeaconsInRegion:beaconRegion];
        
        [self.rangedBeacons removeObjectForKey:beaconRegion];
        [self selectBeacon];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{    
    [self.rangedBeacons setObject:beacons forKey:region];
    [self selectBeacon];
}

// TODO: expose this to delegate??
#pragma mark CLLocationManagerDelegate error handling

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DebugLog(@"LM error: %ld - %@", (long)error.code, error.debugDescription);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    DebugLog(@"LM did fail to monitor region %@: %ld - %@", region.identifier, (long)error.code, error.debugDescription);
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    DebugLog(@"LM did fail to range in region %@", region.identifier);
}

@end
