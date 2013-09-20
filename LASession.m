//
//  LAConnect/LASession.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LASession.h"
#import "LASessionEvent.h"

#define minAcceptablePressure 3.0
#define maxAcceptablePressure 6.0
#define initialPressureCheckTime 3.0
#define finishTime 7.0

#define battery_level_info_byte_start_index 4
#define battery_level_bits_count 4
#define device_id_bits_count 20
#define device_id_high_bits_index 16
#define device_id_middle_byte_index 8
#define device_id_low_byte_index 0
#define device_id_high_bits_count 4

#define byte_length    8
#define word8_length   8
#define word32_length 32

NSString *const ConnectManagerDidRecieveSessionEvent = @"ConnectManagerDidRecieveSessionEvent";


@interface LASession ()
@property (strong) NSTimer *everySecondTimer;
@property (strong) NSTimer *initialPressureCheckTimer;
@property (strong) NSTimer *finishTimer;
@property (strong) NSDate *startTime;

@property BIT_ARRAY *device_id_bits;
@property BOOL deviceIDGotHighBits;
@property BOOL deviceIDGotMiddleByte;
@property BOOL deviceIDGotLowByte;
@property BOOL deviceIDIsIntegral;
@end


@implementation LASession


- (id)init {
	if ((self = [super init])) {
		NSLog(@"LASession init");
		
		_alcohol = 0;
		_pressure = 0;
		_duration = 0;
		_deviceID = 0;
		_batteryLevel = 0;
		
		_device_id_bits = bit_array_create(device_id_bits_count);
	}
	return self;
}


- (void)dealloc {
	NSLog(@"LASession dealloc");
	bit_array_free(_device_id_bits);
}


- (void)start {
	NSLog(@"LASession start");
	
	[self scheduleTimers];
	self.startTime = [NSDate date];
	
	[self.delegate sessionDidStart];
}


- (void)stop {
	NSLog(@"LASession stop");
	
	[self invalidateTimers];
}


- (void)updateWithMessage:(LAMessage *)message {
	
	_duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
	_pressure = message.pressure;
	_alcohol = message.alcohol;
	
	[self.delegate sessionDidUpdatePressureAndAlcohol];
	
	[self processInfoByte:message.infoByte withInfoByteType:message.infoByteType];
	
	
	// Check pressure
	
	BOOL pressureIsInAcceptableRange = (_pressure >= minAcceptablePressure) && (_pressure <= maxAcceptablePressure);
	
	if (!_pressureGotToAcceptableRange && pressureIsInAcceptableRange) {
		_pressureGotToAcceptableRange = YES;
		NSLog(@"LASession pressureGotToAcceptableRange");
	}
	
	if (_pressureGotToAcceptableRange && !pressureIsInAcceptableRange) {
		NSLog(@"Warning: LASession: Pressure goes out of acceptable range, here will be the error");
//		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeNotEnoughPressureToFinishMeasure userInfo:nil];
//		[self finishWithError:error];
		
		NSString *description = [NSString stringWithFormat:@"Error: %@ pressure", (_pressure < minAcceptablePressure) ? @"small" : @"high"];
		LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	}
}


- (void)everySecondTick {
	
	_duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
	[self.delegate sessionDidUpdateDuration];
}


- (void)initialPressureCheck {
	
	if (!_pressureGotToAcceptableRange) {
		NSLog(@"Warning: LASession: Pressure doesn't get to acceptable range in time (%f), here will be the error", _duration);
//		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeNotEnoughPressureToStartMeasure userInfo:nil];
//		[self finishWithError:error];
		
		NSString *description = [NSString stringWithFormat:@"Error: %@ pressure", (_pressure < minAcceptablePressure) ? @"small" : @"high"];
		LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	}
}


- (void)finish {
	
	[self invalidateTimers];
	
	LAMeasure *measure = [[LAMeasure alloc] initWithAlcohol:_alcohol date:[NSDate date]];
	[self.delegate sessionDidFinishWithMeasure:measure];
}


- (void)finishWithError:(LAError *)error {
	NSLog(@"LASession finishWithError: %@", [error localizedDescription]);
	
	[self invalidateTimers];
	[self.delegate sessionDidFinishWithError:error];
}


#pragma mark - Timers


- (void)scheduleTimers {
	
	self.everySecondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(everySecondTick) userInfo:nil repeats:YES];
	self.initialPressureCheckTimer = [NSTimer scheduledTimerWithTimeInterval:initialPressureCheckTime target:self selector:@selector(initialPressureCheck) userInfo:nil repeats:NO];
	self.finishTimer = [NSTimer scheduledTimerWithTimeInterval:finishTime target:self selector:@selector(finish) userInfo:nil repeats:NO];
}


- (void)invalidateTimers {
	
	[self.everySecondTimer invalidate];
	[self.initialPressureCheckTimer invalidate];
	[self.finishTimer invalidate];
	
	self.everySecondTimer = nil;
	self.initialPressureCheckTimer = nil;
	self.finishTimer = nil;
}


#pragma mark - Info Byte


- (void)processInfoByte:(BIT_ARRAY *)infoByte withInfoByteType:(LAMessageInfoByteType)infoByteType {
	if (_deviceIDIsIntegral) return;
	
	switch (infoByteType) {
			
		case LAMessageInfoByteTypeOne: {
			
			// battery level
			BIT_ARRAY *battery_level_bits = bit_array_create(word8_length);
			bit_array_copy(battery_level_bits, 0, infoByte, battery_level_info_byte_start_index, battery_level_bits_count);
			uint16_t batteryLevelInternalValue = bit_array_get_word8(battery_level_bits, 0);
			_batteryLevel = [self batteryLevelInternalValueToVolts:batteryLevelInternalValue];
			[self.delegate sessionDidRecieveBatteryLevel];
			bit_array_free(battery_level_bits);
			
			// device id high bits
			bit_array_copy(_device_id_bits, device_id_high_bits_index, infoByte, 0, device_id_high_bits_count);
			_deviceIDGotHighBits = YES;
			[self checkDeviceIDIntegrity];
			
			break;
		}
			
		case LAMessageInfoByteTypeTwo: {
			
			// device id middle byte
			bit_array_copy(_device_id_bits, device_id_middle_byte_index, infoByte, 0, byte_length);
			_deviceIDGotMiddleByte = YES;
			[self checkDeviceIDIntegrity];
			
			break;
		}
			
		case LAMessageInfoByteTypeThree: {
			
			// device id low byte
			bit_array_copy(_device_id_bits, device_id_low_byte_index, infoByte, 0, byte_length);
			_deviceIDGotLowByte = YES;
			[self checkDeviceIDIntegrity];
			
			break;
		}
			
		default:
			break;
	}
}


- (void)checkDeviceIDIntegrity {
	
	if (_deviceIDGotLowByte && _deviceIDGotLowByte && _deviceIDGotHighBits) {
		_deviceID = bit_array_get_word32(_device_id_bits, 0);
		_deviceIDIsIntegral = YES;
		[self.delegate sessionDidRecieveDeviceID];
	}
}


#pragma mark - Utilities


- (float)batteryLevelInternalValueToVolts:(uint16_t)batteryLevelInternalValue {
	
	float batteryLevelInVolts = 0.1 * batteryLevelInternalValue + 3.0;
	return batteryLevelInVolts;
}


@end
