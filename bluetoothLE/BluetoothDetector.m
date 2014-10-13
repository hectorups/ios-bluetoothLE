//
//  BluetoothLE.m
//  Dot iBeacon
//

#import "BluetoothDetector.h"
#import "UUIDBuilder.h"


@interface BluetoothDetector() <CBCentralManagerDelegate, CBPeripheralDelegate>{
    CBCentralManager *_centralManager;
    BOOL _startMonitoring;
    BOOL _bluetoothIsReady;
    CBPeripheral *_targetBeacon;
}


@end

@implementation BluetoothDetector

- (id)init
{
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
//        [_centralManager requestAlwaysAuthorization];
        
        _startMonitoring = NO;
        _bluetoothIsReady = NO;
    }
    return self;
}

+ (BluetoothDetector *)instance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}


-(CBCentralManagerState)getState
{
    return _centralManager.state;
}

-(void)startMonitoring
{
    _startMonitoring = YES;
    [self startScan];
}

-(void)startScan
{
    if (_isMonitoring){
        return;
    }
    if (_bluetoothIsReady && _startMonitoring){
        _startMonitoring = NO;
        _isMonitoring = YES;
        NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO};
        [_centralManager scanForPeripheralsWithServices:@[[UUIDBuilder ledSequenceService]] options:options];
    }
}


-(void)stopMonitoring
{
    if (_bluetoothIsReady){
        _isMonitoring = NO;
        [_centralManager stopScan];
    }
}


#pragma mark - CBCentralManagerDelegate

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    _bluetoothIsReady = NO;
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            _bluetoothIsReady = YES;
            [self startScan];
            break;
        case CBCentralManagerStatePoweredOff:
//             [_centralManager ]
        default:
//        case CBCentralManagerStateUnknown:
//        case CBCentralManagerStateResetting:
//        case CBCentralManagerStateUnsupported:
//        case CBCentralManagerStateUnauthorized:
//        case CBCentralManagerStatePoweredOff:
            break;
    }
    if (_delegate) {
        [_delegate centralManagerStateDidChange:central.state];
    }
}

-(NSString*)macAddressFromManufacturerData:(NSString*)manufacturerData
{
    if ([manufacturerData length] < 17){
        return nil;
    }
    //manufacturerData = <7500ce65 bdc349b5 0894> --> ce:65:bd:c3:49:b5
    // remove whitespaces
    manufacturerData = [manufacturerData stringByReplacingOccurrencesOfString:@" " withString:@""]; // <7500ce65bdc349b50894>
    
    NSRange range = NSMakeRange(5, 12);
    NSString *addressString = [manufacturerData substringWithRange:range];  // ce65bdc349b5
    
    //split by char
    NSMutableArray *chars = [[NSMutableArray alloc] initWithCapacity:[addressString length]];
    for (int i=0; i < [addressString length]; i++) {
        NSString *ichar  = [NSString stringWithFormat:@"%C", [addressString characterAtIndex:i]];
        [chars addObject:ichar];
        if (i%2 == 1 && i < addressString.length-1){
            [chars addObject:@":"];
        }
    }
    
    return [chars componentsJoinedByString:@""];
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (_delegate) {
        NSData *manufacturerData = (NSData*)[advertisementData valueForKey:CBAdvertisementDataManufacturerDataKey];
        NSString *manufacturerString =  [NSString stringWithFormat:@"%@", manufacturerData];
        NSString *macAddress = [self macAddressFromManufacturerData:manufacturerString];
        [_delegate bluetoothDetectorDidDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI macAddress:macAddress];
    }
}

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:@[[UUIDBuilder ledSequenceService]]];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
     NSLog(@"disconnected");
    _targetBeacon = nil;
    _isSmiling = NO;
}



#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error){
        if (_delegate) {
            [_delegate bluetoothDetectorError:error];
        }
        return;
    }
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[UUIDBuilder ledCharacteristic]]  forService:service];
    }
}




// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error){
        if (_delegate) {
            [_delegate bluetoothDetectorError:error];
        }
        return;
    }
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[UUIDBuilder ledCharacteristic]]) {
            // If it is, subscribe to it
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}


// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error){
        if (_delegate) {
            [_delegate bluetoothDetectorError:error];
        }
        return;
    }
    if (characteristic.value != nil) {
        [self smileToDeviceWithCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic: %@", error);
    if (_delegate) {
        [_delegate bluetoothDetectorError:error];
    }
}

-(void)smileToPeripheral:(CBPeripheral*)peripheral
{
    _targetBeacon = peripheral;
    if (!_targetBeacon){
        return;
    }
    NSLog(@"do smile");
    _isSmiling = YES;
    _targetBeacon.delegate = self;
    [_centralManager connectPeripheral:_targetBeacon options:nil];
}


-(void)smileToDeviceWithCharacteristic:(CBCharacteristic*)characteristic
{
    if (characteristic && _targetBeacon){
        NSLog(@"write to device");
        [_targetBeacon writeValue:[UUIDBuilder smile] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        [_centralManager cancelPeripheralConnection:_targetBeacon];
        _isSmiling = NO;
        _targetBeacon = nil;
    }
}





@end
