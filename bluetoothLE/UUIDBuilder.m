//
//  UUIDBuilder.m
//  Dot iBeacon
//


#import "UUIDBuilder.h"

@implementation UUIDBuilder

NSString *beaconUUIDPrototype = @"00000000-1324-019a-1a4a-031d69907fa9";
//NSString *bluetoothUUIDPrototype = @"00000000-0000-1000-8000-00805f9b34fb";
//NSString *beaconAdvertisementCheck = @"1106a97f90691d034a1a9a0124132315";


//+(NSString*)beaconAdvertisementCheck
//{
//    return beaconAdvertisementCheck;
//}
//
//
//+(CBUUID*)service
//{
//    return [UUIDBuilder buildUUIDWithBaseUUID: bluetoothUUIDPrototype shortUUID:@"2220"];
//}

+(CBUUID*)ledSequenceService
{
    return [UUIDBuilder buildUUIDWithBaseUUID: beaconUUIDPrototype shortUUID:@"1523"];
}

+(CBUUID*)ledCharacteristic
{
    return [UUIDBuilder buildUUIDWithBaseUUID: beaconUUIDPrototype shortUUID:@"1524"];
}


+(CBUUID*)buildUUIDWithBaseUUID:(NSString*)baseUUID shortUUID:(NSString*)shortUUID
{
    NSInteger length = [shortUUID length];
    NSInteger startIndex = [baseUUID rangeOfString:@"-"].location - length;
    NSRange range = NSMakeRange(startIndex, length);
    NSString *result = [baseUUID stringByReplacingCharactersInRange:range withString:shortUUID];
    
    return [CBUUID UUIDWithString:result];
}

+(NSData *)smile
{
    const unsigned char bytes[] = {0x00, 0x06};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    return data;
}



@end
