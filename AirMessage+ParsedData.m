//
//  AirMessage+ParsedData.m
//  BAM
//
//  Created by Sergey Filippov on 10/31/13.
//  Copyright (c) 2013 Lapka. All rights reserved.
//

#import "AirMessage+ParsedData.h"


@implementation AirMessage (ParsedData)


- (int)deviceID_part {
	
	return bit_array_get_word8(_data, 0);
}


- (int)pressure {
	
	BIT_ARRAY *pressure_bits = bit_array_create(4);
	bit_array_copy(pressure_bits, 0, _data, 20, 4);
	int pressure = bit_array_get_word16(pressure_bits, 0);
	bit_array_free(pressure_bits);
	
	return pressure;
}


- (int)alcohol {
	
	BIT_ARRAY *alcohol_bits = bit_array_create(12);
	bit_array_copy(alcohol_bits, 0, _data, 8, 12);
	int alcohol = bit_array_get_word16(alcohol_bits, 0);
	bit_array_free(alcohol_bits);
	
	return alcohol;
}


- (int)deviceID_v1 {
	
	BIT_ARRAY *device_id_bits = bit_array_create(22);
	bit_array_copy(device_id_bits, 0, _data, 2, 22);
	int deviceID = bit_array_get_word32(device_id_bits, 0);
	bit_array_free(device_id_bits);
	
	return deviceID;
}


- (int)batteryLevel {
	
	BIT_ARRAY *battery_bits = bit_array_create(2);
	bit_array_copy(battery_bits, 0, _data, 0, 2);
	int batteryLevel = bit_array_get_word8(battery_bits, 0);
	bit_array_free(battery_bits);
	
	return batteryLevel;
}


@end
