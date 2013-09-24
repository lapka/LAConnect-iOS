//
//  LAConnect/LASession.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LASession.h"
#import "LASessionEvent.h"

#define minAcceptablePressure 3.0
#define maxAcceptablePressure 6.0
#define initialPressureCheckTime 3.0
#define missedMessageDelay 0.3
#define finishTime 10.0

#define battery_level_info_byte_start_index 4
#define battery_level_bits_count 4
#define alcohol_bits_count 12
#define alcohol_part_bits_count 4

#define byte_length    8
#define word4_length   4
#define word8_length   8
#define word16_length 16
#define word32_length 32

NSString *const ConnectManagerDidRecieveSessionEvent = @"ConnectManagerDidRecieveSessionEvent";


@interface LASession ()
@property (strong) NSTimer *everySecondTimer;
@property (strong) NSTimer *initialPressureCheckTimer;
@property (strong) NSTimer *finishTimer;
@property (strong) NSTimer *missedMessageTimer;
@property (strong) NSDate *startTime;

@property BIT_ARRAY *alcohol_bits;
@property BOOL alcoholGotHighByte;
@property BOOL alcoholGotMiddleByte;
@property BOOL alcoholGotLowByte;
@property BOOL alcoholIsIntegral;
@end


@implementation LASession


- (id)init {
	if ((self = [super init])) {
		NSLog(@"LASession init");
		
		_alcohol = 0;
		_pressure = 0;
		_duration = 0;
		
		_alcohol_bits = bit_array_create(word16_length);
	}
	return self;
}


- (void)dealloc {
	NSLog(@"LASession dealloc");
	bit_array_free(_alcohol_bits);
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


- (void)updateWithPressure:(float)pressure {
	
	_duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
	
	_pressure = pressure;
	[self.delegate sessionDidUpdatePressure];
	
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
		
//		NSString *description = [NSString stringWithFormat:@"Error: %@ pressure", (_pressure < minAcceptablePressure) ? @"small" : @"high"];
//		LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
//		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	}
	
	[self restartMissedMessageTimer];
}


- (void)updateWithAlcoholPartValue:(uint8_t)alcoholPartValue forPartType:(LAAlcoholPartType)alcoholPartType {
	[self restartMissedMessageTimer];
	if (_alcoholIsIntegral) return;
	
	// convert part to bits
	BIT_ARRAY *alcohol_part_bits = bit_array_create(word8_length);
	bit_array_set_word8(alcohol_part_bits, 0, alcoholPartValue);
	
	// add part bits
	uint8_t alcohol_part_index = [self alcoholPartIndexByPartType:alcoholPartType];
	bit_array_copy(_alcohol_bits, alcohol_part_index, alcohol_part_bits, 0, alcohol_part_bits_count);
	bit_array_free(alcohol_part_bits);
	
	// check
	[self gotAlcoholPartWithType:alcoholPartType];
	[self checkAlcoholIntegrity];
}


- (uint8_t)alcoholPartIndexByPartType:(LAAlcoholPartType)partType {
	switch (partType) {
			
		case LAAlcoholPart_low:
			return 0;
			break;
			
		case LAAlcoholPart_middle:
			return 4;
			break;
			
		case LAAlcoholPart_high:
			return 8;
			break;
	}
}


- (void)gotAlcoholPartWithType:(LAAlcoholPartType)partType {
	switch (partType) {
			
		case LAAlcoholPart_high:
			_alcoholGotHighByte = YES;
			break;
			
		case LAAlcoholPart_middle:
			_alcoholGotMiddleByte = YES;
			break;
			
		case LAAlcoholPart_low:
			_alcoholGotLowByte = YES;
			break;
	}
}


- (void)checkAlcoholIntegrity {
	
	if (_alcoholGotLowByte && _alcoholGotLowByte && _alcoholGotHighByte) {
		_alcohol = bit_array_get_word16(_alcohol_bits, 0);
		_alcoholIsIntegral = YES;
		[self.delegate sessionDidUpdateAlcohol];
		[self finish];
	}
}


- (void)everySecondTick {
	
	_duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
}


- (void)initialPressureCheck {
	
	if (!_pressureGotToAcceptableRange) {
		NSLog(@"Warning: LASession: Pressure doesn't get to acceptable range in time (%f), here will be the error", _duration);
//		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeNotEnoughPressureToStartMeasure userInfo:nil];
//		[self finishWithError:error];
		
//		NSString *description = [NSString stringWithFormat:@"Error: %@ pressure", (_pressure < minAcceptablePressure) ? @"small" : @"high"];
//		LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
//		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
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
	[self.missedMessageTimer invalidate];
	
	self.everySecondTimer = nil;
	self.initialPressureCheckTimer = nil;
	self.finishTimer = nil;
	self.missedMessageTimer = nil;
}


#pragma mark - Missed Message Timer


- (void)restartMissedMessageTimer {
	
	[self.missedMessageTimer invalidate];
	self.missedMessageTimer = [NSTimer scheduledTimerWithTimeInterval:missedMessageDelay target:self selector:@selector(handleMissedMessage) userInfo:nil repeats:NO];
}


- (void)handleMissedMessage {
	
	LASessionEvent *event = [LASessionEvent eventWithDescription:@"Missed message" time:_duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	[self restartMissedMessageTimer];
}


@end
