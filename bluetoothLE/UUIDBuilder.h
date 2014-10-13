//
//  UUIDBuilder.h
//  Dot iBeacon
//


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface UUIDBuilder : NSObject

//
//+(NSString*)beaconAdvertisementCheck;
//
//+(CBUUID*)service;
+(CBUUID*)ledSequenceService;
+(CBUUID*)ledCharacteristic;

+(NSData*)smile;

@end
