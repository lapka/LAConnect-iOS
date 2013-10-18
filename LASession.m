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
#define maxAcceptableMissedMessagesInARow 10
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
@property (strong) NSTimer *missedMessageTimer;
@property (strong) NSDate *startTime;
@property int missedMessagesInARow;

@end


@implementation LASession


- (id)init {
	if ((self = [super init])) {
		NSLog(@"LASession init");
		
		_alcohol = 0;
		_pressure = 0;
		_duration = 0;
		
		_missedMessagesInARow = 0;
	}
	return self;
}


- (void)dealloc {
	NSLog(@"LASession dealloc");
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
	
	[self updateDuration];
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_pressure = pressure;
	[self.delegate sessionDidUpdatePressure];
	
	// Check pressure
	
	BOOL pressureIsInAcceptableRange = (_pressure >= minAcceptablePressure) && (_pressure <= maxAcceptablePressure);
	
	if (!_pressureGotToAcceptableRange && pressureIsInAcceptableRange) {
		_pressureGotToAcceptableRange = YES;
	}
	
	if (_pressureGotToAcceptableRange && !pressureIsInAcceptableRange) {
//		NSLog(@"Warning: LASession: Pressure goes out of acceptable range, here will be the error");
//		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeNotEnoughPressureToFinishMeasure userInfo:nil];
//		[self finishWithError:error];
		
//		NSString *description = [NSString stringWithFormat:@"Error: %@ pressure", (_pressure < minAcceptablePressure) ? @"small" : @"high"];
//		LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
//		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	}
}


- (void)updateWithAlcohol:(float)alcohol {
	
	[self updateDuration];
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
		
	_alcohol = alcohol;
	[self.delegate sessionDidUpdateAlcohol];
	
	[self finishWithMeasure];
}


- (void)updateWithDeviceID:(int)deviceID {
	
	[self updateDuration];
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_deviceID = deviceID;
	[self.delegate sessionDidUpdateDeviceID];
	
	[self finishWithDeviceID];
}


- (void)updateWithShortDeviceID:(int)shortDeviceID {
	
	[self updateDuration];
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_shortDeviceID = shortDeviceID;
	[self.delegate sessionDidUpdateShortDeviceID];
}


- (void)updateWithBatteryLevel:(int)batteryLevel {
	
	[self updateDuration];
	[self restartMissedMessageTimer];
	_missedMessagesInARow = 0;
	
	_batteryLevel = batteryLevel;
	[self.delegate sessionDidUpdateBatteryLevel];
}


- (void)everySecondTick {
	[self updateDuration];
}


- (void)updateDuration {
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


- (void)finishWithMeasure {
	
	[self invalidateTimers];
	
	LAMeasure *measure = [[LAMeasure alloc] initWithAlcohol:_alcohol date:[NSDate date]];
	[self.delegate sessionDidFinishWithMeasure:measure];
}


- (void)finishWithDeviceID {
	
	[self invalidateTimers];
	[self.delegate sessionDidFinishWithDeviceID];
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
}


- (void)invalidateTimers {
	
	[self.everySecondTimer invalidate];
	[self.initialPressureCheckTimer invalidate];
	[self.missedMessageTimer invalidate];
	
	self.everySecondTimer = nil;
	self.initialPressureCheckTimer = nil;
	self.missedMessageTimer = nil;
}


#pragma mark - Missed Message Timer


- (void)restartMissedMessageTimer {
	
	[self.missedMessageTimer invalidate];
	self.missedMessageTimer = [NSTimer scheduledTimerWithTimeInterval:missedMessageDelay target:self selector:@selector(handleMissedMessage) userInfo:nil repeats:NO];
}


- (void)handleMissedMessage {
	
	[self updateDuration];
	[self restartMissedMessageTimer];
	_missedMessagesInARow++;
	
	NSString *description = [NSString stringWithFormat:@"Missed message (%d)", _missedMessagesInARow];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	if (_missedMessagesInARow > maxAcceptableMissedMessagesInARow) {
		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeMoreMissedMessagesThenAcceptable userInfo:nil];
		[self finishWithError:error];
	}
}


@end
