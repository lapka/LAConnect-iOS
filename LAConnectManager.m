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
		
		_airListener = [[AirListener alloc] initWithMarker:0xD391];
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
	
	// ready -> measure
	if (fromState == LAConnectManagerStateReady && toState == LAConnectManagerStateMeasure) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure -> respite
	if (fromState == LAConnectManagerStateMeasure && toState == LAConnectManagerStateRespite) {
		_state = toState;
		NSLog(@"LAConnectManager state: %@", [self stateToString:self.state]);
		
		[_airListener stopListen];
		self.respiteTimer = [NSTimer scheduledTimerWithTimeInterval:respiteTime target:self selector:@selector(respiteFinish) userInfo:nil repeats:NO];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidUpdateState object:nil];
		return YES;
	}
	
	// measure -> off
	if (fromState == LAConnectManagerStateMeasure && toState == LAConnectManagerStateOff) {
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
	[self updateWithState:LAConnectManagerStateMeasure];
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


- (void)sessionDidUpdatePressureAndAlcohol {
	printf("\nLAConnectManager sessionDidUpdatePressure: %.0f AndAlcohol: %.0f (duration %.2f)\n", [_session pressure], [_session alcohol], _session.duration);
	
	NSString *description = [NSString stringWithFormat:@"Alcohol: %.0f, Pressure: %.0f", _session.alcohol, _session.pressure];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidRecieveDeviceID {
	printf("\nLAConnectManager sessionDidRecieveDeviceID: %d\n", [_session deviceID]);
	
	NSString *description = [NSString stringWithFormat:@"Device ID: %df", _session.deviceID];
	LASessionEvent *event = [LASessionEvent eventWithDescription:description time:_session.duration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ConnectManagerDidRecieveSessionEvent object:event];
}


- (void)sessionDidRecieveBatteryLevel {
	printf("\nLAConnectManager sessionDidRecieveBatteryLevel: %0.1f\n", [_session batteryLevel]);
	
	NSString *description = [NSString stringWithFormat:@"Battery: %.1fV", _session.batteryLevel];
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


- (void)airListener:(AirListener *)airListener didReceiveMessage:(AirMessage *)airMessage {
	
	if (self.state == LAConnectManagerStateReady) {
		
		// refactor: update state should be after session creation (or in)
		[self updateWithState:LAConnectManagerStateMeasure];
		
		self.session = [LASession new];
		_session.delegate = self;
		[_session start];
		
		LAMessage *message = [[LAMessage alloc] initWithAirMessage:airMessage];
		[_session updateWithMessage:message];
	}
	
	if (self.state == LAConnectManagerStateMeasure) {
		
		LAMessage *message = [[LAMessage alloc] initWithAirMessage:airMessage];
		[_session updateWithMessage:message];
	}
}


- (void)airListenerDidLostMessage:(AirListener *)airListener {
	
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
			
		case LAConnectManagerStateMeasure:
			return @"measure";
			break;
			
		case LAConnectManagerStateRespite:
			return @"respite";
			break;
			
		default:
			break;
	}
}


@end
