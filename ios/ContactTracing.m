#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE( ContactTracing, RCTEventEmitter )

/* Starts BLE broadcasts and scanning based on the defined protocol */
RCT_EXTERN_METHOD( start:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

/* Disables advertising and scanning */
RCT_EXTERN_METHOD( stop:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

/* Indicates whether exposure notifications are currently running for the requesting app */
RCT_EXTERN_METHOD( isEnabled:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

/* Gets TemporaryExposureKey history to be stored on the server ( after user is diagnosed ) */
RCT_EXTERN_METHOD( getTemporaryExposureKeyHistory:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

/* Provides a list of diagnosis key files for exposure checking ( from server ) */
RCT_EXTERN_METHOD( provideDiagnosisKeys:(NSArray *)keyFiles configuration:(NSDictionary *)configuration token:(NSString *)token resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

/* Gets a summary of the latest exposure calculation */
RCT_EXTERN_METHOD( getExposureSummary:(NSString *)token resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

/* Gets detailed information about exposures that have occurred */
RCT_EXTERN_METHOD( getExposureInformation:(NSString *)token resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject )

@end
