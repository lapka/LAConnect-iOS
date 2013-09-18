//
//  LAConnect/LASession.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LASession.h"

#define minAcceptablePressure 128.0
#define maxAcceptablePressure 256.0
#define initialPressureCheckTime 3.0
#define finishTime 7.0


@interface LASession ()
@property (strong) NSTimer *everySecondTimer;
@property (strong) NSTimer *initialPressureCheckTimer;
@property (strong) NSTimer *finishTimer;
@property (strong) NSDate *startTime;
@end


@implementation LASession


- (id)initWithStartMessage:(LAStartMessage *)startMessage {
	if ((self = [super init])) {
		NSLog(@"LASession init with deviceID: %d", _deviceID);
		
		_deviceID = startMessage.deviceID;
		
		_alcohol = 0;
		_pressure = 0;
		_duration = 0;
		
		_pressureGotToAcceptableRange = NO;
	}
	return self;
}


- (void)start {
	NSLog(@"LASession start");
	
	[self scheduleTimers];
	self.startTime = [NSDate date];
}


- (void)stop {
	NSLog(@"LASession stop");
	
	[self invalidateTimers];
}


- (void)updateWithMeasureMessage:(LAMeasureMessage *)measureMessage {
	_pressure = measureMessage.pressure;
	_alcohol = measureMessage.alcohol;
	_duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
	
	[self.delegate sessionDidUpdatePressureAndAlcohol];
	
	
	// Check pressure
	
	BOOL pressureIsInAcceptableRange = (_pressure > minAcceptablePressure) && (_pressure < maxAcceptablePressure);
	
	if (!_pressureGotToAcceptableRange && pressureIsInAcceptableRange) {
		_pressureGotToAcceptableRange = YES;
		NSLog(@"LASession pressureGotToAcceptableRange");
	}
	
	if (_pressureGotToAcceptableRange && !pressureIsInAcceptableRange) {
		NSLog(@"Warning: LASession: Pressure goes out of acceptable range, here will be the error");
//		LAError *error = [[LAError alloc] initWithDomain:@"com.mylapka.bam" code:LAErrorCodeNotEnoughPressureToFinishMeasure userInfo:nil];
//		[self finishWithError:error];
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


@end
