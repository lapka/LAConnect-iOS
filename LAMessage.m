//
//  LAConnect/LAMessage.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAMessage.h"

#define info_bits_count 8
#define pressure_bits_count 10
#define alcohol_bits_count 12

#define info_bits_data_index 24
#define pressure_bits_data_index 20
#define alcohol_bits_data_index 8

#define word16_length 16


@implementation LAMessage


- (id)initWithAirMessage:(AirMessage *)airMessage {
	if ((self = [super init])) {
		
		BIT_ARRAY *data = [airMessage data];
		
		BIT_ARRAY* pressure_bits = bit_array_create(word16_length);
		BIT_ARRAY* alcohol_bits = bit_array_create(word16_length);
		
		bit_array_copy(pressure_bits, 0, data, pressure_bits_data_index, pressure_bits_count);
		bit_array_copy(alcohol_bits, 0, data, alcohol_bits_data_index, alcohol_bits_count);
		
		_pressure = bit_array_get_word16(pressure_bits, 0);
		_alcohol = bit_array_get_word16(alcohol_bits, 0);
		
		bit_array_free(pressure_bits);
		bit_array_free(alcohol_bits);
		
		
		// info byte
		
		if (airMessage.markerIsInverse) {
			_infoByteType = LAMessageInfoByteTypeOne;
		} else if (airMessage.markerIsReverse) {
			_infoByteType = LAMessageInfoByteTypeThree;
		} else {
			_infoByteType = LAMessageInfoByteTypeTwo;
		}
		
		_infoByte = bit_array_create(info_bits_count);
		bit_array_copy(_infoByte, 0, data, info_bits_data_index, info_bits_count);
		
	}
	return self;
}


- (void)dealloc {
	bit_array_free(_infoByte);
}


@end
