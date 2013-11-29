//
//  LAConnect/LAConnectManager.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LASession.h"
#import "LAMeasure.h"
#import "Airlift.h"


extern NSString *const ConnectManagerDidUpdateState;
extern NSString *const ConnectManagerDidFinishSessionWithMeasure;
extern NSString *const ConnectManagerDidFinishSessionWithDeviceID;
extern NSString *const ConnectManagerDidFinishSessionWithError;
extern NSString *const ConnectManagerDidUpdateBatteryLevel;
extern NSString *const ConnectManagerDidUpdateCountdown;
extern NSString *const ConnectManagerDidUpdatePressure;


typedef enum {
	LAConnectManagerStateOff,
	LAConnectManagerStateReady,
	LAConnectManagerStateMeasure,
	LAConnectManagerStateRespite
} LAConnectManagerState;


@interface LAConnectManager : NSObject <AirListenerDelegate, LASesionDelegate>

@property (strong) AirListener *airListener;
@property (readonly) LAConnectManagerState state;
@property (strong) LASession *session;
@property (strong) LAMeasure *measure;

@property float alcoholToPromilleCoefficient;
@property float calibrationCoefficient;

+ (LAConnectManager *)sharedManager;

- (void)turnOn;
- (void)turnOff;
- (void)startMeasure;

@end
