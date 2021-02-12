#import "BeaconBroadcast.h"

@interface BeaconBroadcast()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) NSMutableArray *services;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) void (^resolve)(NSNumber* status);
@property (nonatomic, strong) void (^reject)(NSError *error);
@end

@implementation BeaconBroadcast

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(startSharedAdvertisingBeaconWithString:(NSDictionary*)args)
{
    [[BeaconBroadcast sharedInstance] _startAdvertisingBeaconWithString: args];
}

RCT_EXPORT_METHOD(stopSharedAdvertisingBeacon)
{
    [[BeaconBroadcast sharedInstance] _stopAdvertisingBeacon];
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(isStarted)
{
    return @([[BeaconBroadcast sharedInstance] _isStarted]);
}

RCT_EXPORT_METHOD(checkTransmissionSupported:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [[BeaconBroadcast sharedInstance] _checkTransmissionSupported: resolve rejecter: reject];
}

#pragma mark - Common
+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;

    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;

    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });

    // returns the same object each time
    return _sharedObject;
}

- (void)_startAdvertisingBeaconWithString:(NSDictionary *)args
{
    NSLog(@"Turning on advertising.");

    NSString *uuid = [args objectForKey:@"uuid"];
    NSNumber *major = [args objectForKey:@"major"];
    NSNumber *minor = [args objectForKey:@"minor"];
    NSString *identifier = [args objectForKey:@"identifier"];
    NSArray *services = [args objectForKey:@"services"];

    if (!self.peripheralManager)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options: @{CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
    [self createBeaconRegionWithString:uuid major:major minor:minor identifier:identifier];
    [self createServices:services];
    [self turnOnAdvertising];
}

- (void)_stopAdvertisingBeacon
{
   if ([self.peripheralManager isAdvertising]) {
        [self.peripheralManager stopAdvertising];
    }

   NSLog(@"Turned off advertising.");
}

- (BOOL)_isStarted {
    if (!self.peripheralManager) return false;
    return [self.peripheralManager isAdvertising];
}

- (void)_checkTransmissionSupported:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    if (!self.peripheralManager) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options: @{CBPeripheralManagerOptionShowPowerAlertKey: @NO}];
        _resolve = resolve;
    } else {
        resolve(@(self.peripheralManager.state != CBPeripheralManagerStateUnknown &&
                self.peripheralManager.state != CBPeripheralManagerStateUnsupported));
    }
}

- (void)createBeaconRegionWithString:(NSString *)uuid major:(int)major minor:(int)minor identifier:(NSString *)identifier
{
//    if (self.beaconRegion)
//        return;

    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)createServices:(NSArray *)services
{
    [self.services removeAllObjects];
    
    for (NSDictionary* serviceElement in services) {
        NSString *serviceUUIDString = [serviceElement objectForKey:@"uuid"];
        CBUUID* serviceUUID = [CBUUID UUIDWithString:serviceUUIDString];
        CBMutableService* service = [[CBMutableService alloc] initWithType:serviceUUID primary:true];

        NSMutableArray* characteristicsForService = [[NSMutableArray alloc] init];
        NSArray *characteristics = [serviceElement objectForKey:@"characteristics"];
        for (NSDictionary* characteristicElement in characteristics) {
            NSString *characteristicUUIDString = [characteristicElement objectForKey:@"uuid"];
            CBUUID* characteristicUUID = [CBUUID UUIDWithString:characteristicUUIDString];
            
            NSString* characteristicValue = [characteristicElement objectForKey:@"value"];
            NSData* valueData = [characteristicValue dataUsingEncoding:NSUTF8StringEncoding];
            CBMutableCharacteristic* characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyRead value:valueData permissions:CBAttributePermissionsReadable];
            [characteristicsForService addObject:characteristic];
        }
        service.characteristics = characteristicsForService;
        [self.services addObject:service];
        [self.peripheralManager addService:service];
    }
}


- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

#pragma mark - Beacon advertising

- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        return;
    }

    time_t t;
    srand((unsigned) time(&t));

    UInt16 major = [self.beaconRegion.major unsignedShortValue];
    UInt16 minor = [self.beaconRegion.minor unsignedShortValue];
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                major: major
                                                                minor: minor
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [beaconPeripheralData setValue:self.beaconRegion.identifier forKey:CBAdvertisementDataLocalNameKey];
    
    NSMutableArray* servicesUUIDs = [[NSMutableArray alloc] init];
    for (CBMutableService* service in self.services) {
        [servicesUUIDs addObject:service.UUID];
    }
    [beaconPeripheralData setValue:servicesUUIDs forKey:CBAdvertisementDataServiceUUIDsKey];
    
    NSLog(@"Turning on advertising for region: %@ and services: %@", region, self.services);
    [self.peripheralManager startAdvertising:beaconPeripheralData];
}

#pragma mark - Beacon advertising delegate methods
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    if (error) {
        NSLog(@"Couldn't turn on advertising: %@", error);
        return;
    }
    
    if (peripheralManager.isAdvertising) {
        NSLog(@"Turned on advertising.");
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (_resolve) {
        _resolve(@(peripheralManager.state != CBPeripheralManagerStateUnknown &&
                 peripheralManager.state != CBPeripheralManagerStateUnsupported));
        _resolve = nil;
    }
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        return;
    }
    NSLog(@"Peripheral manager is on.");
}
    
@end
