//
//  LAConnect/LAConnectManager.m
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import "LAConnectManager.h"
#import "LASessionEvent.h"
#import "Airlift.h"

#define respiteTime 5.0


NSString *const ConnectManagerDidUpdateState = @"ConnectManagerDidUpdateState";
NSString *const ConnectManagerDidFinishMeasureWithMeasure = @"ConnectManagerDidFinishMeasureWithMeasure";
NSString *const ConnectManagerDidFinishMeasureWithError = @"ConnectManagerDidFinishMeasureWithError";


@interface LAConnectManager ()
@property (strong) AirListener *airListener;
@property (strong) NSTimer *respiteTimer;
@property LAAlcoholPartType expectedAlcoholPartType;
@end




@implementation LAConnectManager


#pragma mark - Singleton


+ (LAConnectManager *)sharedManager {
	static dispatch_once_t once;
	static LAConnectManager *sharedManager;
    dispatch_once(&once, ^{
        sharedManager = [[LAConnectManager alloc] init];
    });
    return sharedManager;
}




#pragma mark - Init


- (id)init {
	if ((self = [super init])) {
		
		_airListener = [AirListener new];
		_airListener.delegate = self;
		
	}
	return self;
}




#pragma mark - State


- (BOOL)updateWithState:(LAConnectManagerState)toState {
	
	if (toState == _state) return YES;
	LAConnectManagerState fromState = _state;
	
	// off -> ready
	if (fromState == LAConnectManagerStateOff && toState == LAConnectManagerStateReady) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener startListen];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// ready -> off
	if (fromState == LAConnectManagerStateReady && toState == LAConnectManagerStateOff) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// ready -> measure pressure
	if (fromState == LAConnectManagerStateReady && toState == LAConnectManagerStateMeasurePressure) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		self.session = [LASession new];
		_session.delegate = self;
		[_session start];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure pressure -> measure alcohol
	if (fromState == LAConnectManagerStateMeasurePressure && toState == LAConnectManagerStateMeasureAlcohol) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		_expectedAlcoholPartType = LAAlcoholPart_high;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure alcohol -> respite
	if (fromState == LAConnectManagerStateMeasureAlcohol && toState == LAConnectManagerStateRespite) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		self.respiteTimer = [NSTimer scheduledTimerWithTimeInterval:respiteTime target:self selector:@selector(respiteFinish) userInfo:nil repeats:NO];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure pressure -> off
	if (fromState == LAConnectManagerStateMeasurePressure && toState == LAConnectManagerStateOff) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		[_session stop];
		self.session = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure alcohol -> off
	if (fromState == LAConnectManagerStateMeasureAlcohol && toState == LAConnectManagerStateOff) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		[_session stop];
		self.session = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	NSLog(@"Warning: LAConnectManager can't update state from '%@' to '%@'", [self stateToString:fromState], [self stateToString:toState]);
	return NO;
}


- (void)respiteFinish {
	if (!_state == LAConnectManagerStateRespite) return;
	NSLog(@"respiteFinish");

	[self.respiteTimer invalidate];
	self.respiteTimer = nil;
	
	_state = LAConnectManagerStateOff;
	NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
}




#pragma mark Public methods


- (void)turnOn {
	NSLog(@"LAConnectManager turnOn");
	[self updateWithState:LAConnectManagerStateReady];
}


- (void)turnOff {
	NSLog(@"LAConnectManager turnOff");
	[self updateWithState:LAConnectManagerStateOff];
}


- (void)startMeasure {
	NSLog(@"LAConnectManager startMeasure");
	[self updateWithState:LAConnectManagerStateMeasurePressure];
}




#pragma mark - LASessionDelegate


- (void)sessionDidStart {
	NSLog(@"LAConnectManager sessionDidStart");
	
	LASessionEvent *event = [LASessionEvent eventWithDescription:@"Session started" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdateDuration {
	printf("\nLAConnectManager sessionDidUpdateDuration: %0.1f\n", _session.duration);
	
//	LASessionEvent *event = [LASessionEvent eventWithDescription:@"Timer" time:_session.duration];
//	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdatePressure {
	printf("\nLAConnectManager sessionDidUpdatePressure: %.0f\n", [_session pressure]);
	
	NSString *description = [NSString stringWithFormat:@"Pressure: %.0f", _session.pressure];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidUpdateAlcohol {
	printf("\nLAConnectManager sessionDidUpdateAlcohol: %.0f\n", [_session alcohol]);
	
	NSString *description = [NSString stringWithFormat:@"Alcohol: %.0f", _session.alcohol];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidFinishWithMeasure:(LAMeasure *)measure {
	NSLog(@"LAConnectManager sessionDidFinishWithMeasure");
	
	LASessionEvent *event2 = [LASessionEvent eventWithDescription:@"Session finished\n--------------------------------\n" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event2];
	
	NSString *description = [NSString stringWithFormat:@"Your alcohol: %.0f", _session.alcohol];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	self.measure = measure;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishMeasureWithMeasure object:measure];
	[self updateWithState:LAConnectManagerStateRespite];
	
	self.session = nil;
}


- (void)sessionDidFinishWithError:(LAError *)error {
	NSLog(@"LAConnectManager sessionDidFinishWithError");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidFinishMeasureWithError object:error];
	[self updateWithState:LAConnectManagerStateRespite];
	self.session = nil;
}




#pragma mark - AirListenerDelegate


- (void)airListenerDidReceiveMessage:(AirMessage *)message {
	
	if (self.state == LAConnectManagerStateReady) {
		[self updateWithState:LAConnectManagerStateMeasurePressure];
	}
	
	if (self.state == LAConnectManagerStateMeasurePressure) {
		float pressure = message.value;
		[_session updateWithPressure:pressure];
	}
	
	if (self.state == LAConnectManagerStateMeasureAlcohol) {
		
		NSString *description = [NSString stringWithFormat:@"Alcohol part #%d: %d", _expectedAlcoholPartType, message.value];
		LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
		
		uint8_t alcoholPartValue = message.value;
		[_session updateWithAlcoholPartValue:alcoholPartValue forPartType:_expectedAlcoholPartType];
		_expectedAlcoholPartType = [self nextAlcoholPartTypeForPartType:_expectedAlcoholPartType];
	}
}


- (void)airListenerDidReceiveControlSignal:(AirMessage *)message {
	
	LASessionEvent *event = [LASessionEvent eventWithDescription:@"Control signal 1" time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
	
	if (self.state == LAConnectManagerStateMeasurePressure) {
		if (message.value == AirWordValue_ControlSignal_1) {
			[self updateWithState:LAConnectManagerStateMeasureAlcohol];
		}
	}
	
	if (self.state == LAConnectManagerStateMeasureAlcohol) {
		if (message.value == AirWordValue_ControlSignal_1) {
			_expectedAlcoholPartType = LAAlcoholPart_high;
		}
	}
}




#pragma mark - Utilities


- (NSString *)stateToString:(LAConnectManagerState)state {
	
	switch (state) {
		case LAConnectManagerStateOff:
			return @"off";
			break;
			
		case LAConnectManagerStateReady:
			return @"ready";
			break;
			
		case LAConnectManagerStateMeasurePressure:
			return @"measure pressure";
			break;
			
		case LAConnectManagerStateMeasureAlcohol:
			return @"measure alcohol";
			break;
			
		case LAConnectManagerStateRespite:
			return @"respite";
			break;
			
		default:
			break;
	}
}


- (LAAlcoholPartType)nextAlcoholPartTypeForPartType:(LAAlcoholPartType)partType {
	
	switch (partType) {
			
		case LAAlcoholPart_high:
			return LAAlcoholPart_middle;
			break;
			
		case LAAlcoholPart_middle:
			return LAAlcoholPart_low;
			break;
			
		case LAAlcoholPart_low:
			return LAAlcoholPart_high;
			break;
	}
}


@end
