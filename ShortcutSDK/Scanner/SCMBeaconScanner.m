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

@property (strong, nonatomic) NSMutableDictionary *currentBeacons;
@property (strong, nonatomic, readwrite) CLBeacon *closestBeacon;

@property (strong, nonatomic) CBCentralManager *bluetoothMananger;

@end

@implementation SCMBeaconScanner

#pragma mark - Properties (internal)

- (NSMutableDictionary *)currentBeacons
{
    if (!_currentBeacons) {
        _currentBeacons = [NSMutableDictionary dictionary];
    }
    return _currentBeacons;
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

#pragma mark - Region and beacon access

- (NSArray *)monitoredRegions
{
    return [[self.locationManager monitoredRegions] allObjects];
}

- (NSArray *)enteredRegions
{
    return self.currentBeacons.allKeys;
}

- (NSArray *)rangedBeacons
{
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSArray *beacons in [self.currentBeacons allValues]) {
        [result addObjectsFromArray:beacons];
    }
    
    return result;
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
        NSLog(@"ShortcutSDK (SCMBeaconScanner): You must set NSLocationAlwaysUsageDescription in your app's Info.plist file for location services/beacon monitoring to work properly");
    }
    [self.locationManager requestAlwaysAuthorization];
}

#pragma mark - Beacon processing

- (void)processBeacons
{
    // find the currently closest beacon
    CLBeacon *previouslyClosestBeacon;
    for (CLRegion *region in self.currentBeacons) {
        for (CLBeacon *beacon in self.currentBeacons[region]) {
            if ([beacon.proximityUUID isEqual:self.closestBeacon.proximityUUID] &&
                [beacon.major isEqual:self.closestBeacon.major] &&
                [beacon.minor isEqual:self.closestBeacon.minor]) {
                previouslyClosestBeacon = beacon;
                break;
            }
        }
    }
    
    // find the new closest beacon
    CLBeacon *newClosestBeacon;
    if (previouslyClosestBeacon.proximity != CLProximityUnknown) {
        newClosestBeacon = previouslyClosestBeacon;
    }
    for (CLRegion *region in self.currentBeacons) {
        for (CLBeacon *beacon in self.currentBeacons[region]) {
            if (beacon.proximity == CLProximityUnknown) {
                continue;
            }
            
            if (newClosestBeacon == nil || newClosestBeacon.proximity > beacon.proximity) {
                newClosestBeacon = beacon;
            }
        }
    }
    
    // select the new closest beacon if it is closer than the previously closest one
    if (newClosestBeacon && (newClosestBeacon.proximity < previouslyClosestBeacon.proximity || previouslyClosestBeacon == nil)) {
        [self changeClosestBeacon:newClosestBeacon];
    }
    
    // select nil if there are no beacons in range
    if (self.currentBeacons.count == 0) {
        [self changeClosestBeacon:nil];
    }
}

- (void)changeClosestBeacon:(CLBeacon *)beacon
{
    DebugLog(@"LM did change closest beacon: %@/%@ (%ld)", beacon.major, beacon.minor, (long)beacon.proximity);
    
    self.closestBeacon = beacon;
    if ([self.delegate respondsToSelector:@selector(beaconScanner:closestBeaconChanged:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate beaconScanner:self closestBeaconChanged:self.closestBeacon];
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
        
        if (![self.currentBeacons.allKeys containsObject:beaconRegion]) {
            [self.currentBeacons setObject:@[] forKey:beaconRegion];
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
        
        [self.currentBeacons removeObjectForKey:beaconRegion];
        [self processBeacons];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    [self.currentBeacons setObject:beacons forKey:region];
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
