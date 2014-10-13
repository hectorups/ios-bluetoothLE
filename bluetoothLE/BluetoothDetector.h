//
//  BluetoothLE.h
//  Dot iBeacon
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BluetoothDetectorDelegate <NSObject>

- (void)centralManagerStateDidChange:(CBCentralManagerState)state;
- (void)bluetoothDetectorDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI macAddress:(NSString *)macAddress;
- (void)bluetoothDetectorError:(NSError*)error;
@end



@interface BluetoothDetector : NSObject

+(BluetoothDetector*)instance;

@property (nonatomic, weak) NSObject<BluetoothDetectorDelegate> *delegate;
@property (readonly) BOOL isMonitoring;
@property (readonly) BOOL isSmiling;
@property (readonly) CBCentralManagerState state;

-(void)startMonitoring;
-(void)stopMonitoring;


-(void)smileToPeripheral:(CBPeripheral*)peripheral;


@end
