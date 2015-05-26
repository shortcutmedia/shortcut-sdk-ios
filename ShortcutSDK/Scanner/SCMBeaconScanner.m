//
//  SCMBeaconScanner.m
//  ShortcutSDK
//
//  Created by Severin Schoepke on 11/05/15.
//  Copyright (c) 2015 Shortcut Media AG. All rights reserved.
//

#import "SCMBeaconScanner.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NSString *kSCMShortcutRegionUUID = @"1978F86D-FA83-484B-9624-C360AC3BDB71";

@interface SCMBeaconScanner () <CLLocationManagerDelegate, CBCentralManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSArray *regionsToMonitor;

@property (strong, nonatomic) NSMutableDictionary *rangedBeacons;
@property (strong, nonatomic) CLBeacon *selectedBeacon;

@property (strong, nonatomic) CBCentralManager *bluetoothMananger;

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

- (NSArray *)regionsToMonitor
{
    if (!_regionsToMonitor) {
        _regionsToMonitor = @[self.shortcutRegion];
    }
    return _regionsToMonitor;
}
- (CLRegion *)shortcutRegion
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kSCMShortcutRegionUUID];
    NSString *identifier = kSCMShortcutRegionUUID;
    return [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
}

#pragma mark - Initializers

- (instancetype)init
{
    return [self initWithRegions:nil];
}

- (instancetype)initWithRegions:(NSArray *)regions
{
    if (self = [super init]) {
        self.regionsToMonitor = regions;
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        self.bluetoothMananger = [[CBCentralManager alloc] initWithDelegate:self
                                                                      queue:dispatch_get_main_queue()
                                                                    options:@{CBCentralManagerOptionShowPowerAlertKey : @(NO)}];
    }
    
    return self;
}

#pragma mark - Running

- (void)start
{
    if (!self.isAuthorizedForLocationServices) {
        [self requestAuthorization];
        return;
    }
    
    // cleanup: Remove all monitorings to clean out legacy monitorings.
    //          This is needed since monitored regions are persisted on a
    //          system level and we want to start from a fresh state whenever
    //          a new instance of SCMBeaconScanner is started.
    for (CLBeaconRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    for (CLBeaconRegion *region in self.regionsToMonitor) {
        [self.locationManager requestStateForRegion:region];
    }
}

- (void)stop
{
    for (CLBeaconRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    for (CLBeaconRegion *region in self.locationManager.rangedRegions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
}

#pragma mark - Status

- (BOOL)isRunning
{
    return self.isBluetoothOn && self.isRegionMonitoringOn;
}

- (BOOL)isBluetoothOn
{
    return self.bluetoothMananger.state == CBCentralManagerStatePoweredOn;
}

- (BOOL)isRegionMonitoringOn
{
    return self.locationManager.monitoredRegions.count > 0;
}

- (BOOL)isAuthorizedForLocationServices
{
    return CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
}

#pragma mark - Authorization

- (void)requestAuthorization
{
    if (![NSBundle.mainBundle objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]) {
        NSLog(@"ShortcutSDK You must set NSLocationAlwaysUsageDescription in your app's Info.plist file for location services/beacon monitoring to work properly");
    }
    [self.locationManager requestAlwaysAuthorization];
}

#pragma mark - Beacon processing

- (void)processBeacons
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
        [self selectBeacon:closestBeacon];
    }
    
    // select nil if there are no beacons in range
    if (self.rangedBeacons.count == 0) {
        [self selectBeacon:nil];
    }
}

- (void)selectBeacon:(CLBeacon *)beacon
{
    DebugLog(@"LM did select beacon: %@/%@ (%ld)", beacon.major, beacon.minor, (long)beacon.proximity);
    
    self.selectedBeacon = beacon;
    if ([self.delegate respondsToSelector:@selector(beaconScanner:didSelectBeacon:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate beaconScanner:self didSelectBeacon:self.selectedBeacon];
        });
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (self.isAuthorizedForLocationServices) {
        for (CLBeaconRegion *region in self.regionsToMonitor) {
            [self.locationManager requestStateForRegion:region];
        }
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
        [self processBeacons];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    [self.rangedBeacons setObject:beacons forKey:region];
    [self processBeacons];
}

#pragma mark CLLocationManagerDelegate error handling

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DebugLog(@"LM error: %ld - %@", (long)error.code, error.debugDescription);
    
    [self reportError:error];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    DebugLog(@"LM did fail to monitor region %@: %ld - %@", region.identifier, (long)error.code, error.debugDescription);
    
    [self reportError:error];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    DebugLog(@"LM did fail to range in region %@: %ld - %@", region.identifier, (long)error.code, error.debugDescription);
    
    [self reportError:error];
}

- (void)reportError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(beaconScanner:didEncounterError:)]) {
        [self.delegate beaconScanner:self didEncounterError:error];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Nothing to do but required by CBCentralManagerDelegate protocol
}

@end
