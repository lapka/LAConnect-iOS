//
//  LAConnect/LAConnectManager.h
//  Tailored at 2013 by Lapka, all rights reserved.
//

#import <Foundation/Foundation.h>
#import "LASession.h"
#import "LAMeasure.h"
#import "Airlift.h"


extern NSString *const ConnectManagerDidUpdateState;
extern NSString *const ConnectManagerDidFinishMeasureWithMeasure;
extern NSString *const ConnectManagerDidFinishMeasureWithError;


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

+ (LAConnectManager *)sharedManager;

- (void)turnOn;
- (void)turnOff;
- (void)startMeasure;

@end
