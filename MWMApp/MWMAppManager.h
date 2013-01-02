//
//  MWMAppManager.h
//  MWMApp
//
//  Created by Siqi Hao on 10/25/12.
//  Copyright (c) 2012 MetaWatch Oy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define WIDGETSIZE 48

// Macro for disconnect error code:
#define DISCONNECTEDUNKNOWN 201
#define DISCONNECTEDBYUSER 202
#define DISCONNECTEDBY8882 203
#define DISCONNECTEDBYBLEPOWER 204
#define DISCONNECTEDBYBLENOTIF 205
#define DISCONNECTEDBY8880 206

#define MWMAPP_INVALID_WIDGET_DATA 401
#define MWMAPP_REGISTER_DUPLICATED 402
#define MWMAPP_UNREGISTER_FAILED_NOT_EXISTED 403
#define MWMAPP_UNREGISTER_FAILED_INUSE 404



@protocol MWMAppManagerDelegate <NSObject>

- (void) mwmAppMgrDidEnableMetaWatchService;
- (void) mwmAppMgrDidDisableMetaWatchService;

- (NSArray*) mwmAppMgrRequestedWidgetTypeIDs;

- (void) mwmAppMgrRegisteredWidgetType:(NSString*)widgetTypeID withError:(NSError*)error;
- (void) mwmAppMgrUnregisteredWidgetType:(NSString*)widgetTypeID withError:(NSError*)error;

- (void) mwmAppMgrRestoredSyncID:(NSUInteger)syncID withWidgetType:(NSString*)widgetTypeID andLayoutType:(NSString*)layoutType;
- (void) mwmAppMgrRemovedSyncID:(NSUInteger)syncID;
- (void) mwmAppMgrDeallocedSyncID:(NSUInteger)syncID;
- (void) mwmAppMgrDidReceiveWidgetInfoResponse:(NSArray*)widgetIDsArray forWidgetType:(NSString*)widgetTypeID;

@optional

- (void) widgetDataSource:(NSUInteger)syncID receiveHeartBeat:(NSTimeInterval)timeStamp;

@end

@interface MWMAppManager : NSObject

@property (nonatomic, weak) id<MWMAppManagerDelegate> delegate;

- (void) handleURL:(NSURL*)url fromAPP:(NSString*)appIdentifier withAnnotation:(id)annotation;

+ (MWMAppManager *) sharedAppManager;

// Pair and unpair with Meta Watch
//- (void) requestMetaWatchIdentityAndConnect:(BOOL)connect;
//- (void) removeMetaWatchIdentity;

// Connect and disconnect with Meta Watch
- (void) enableMetaWatchService;
- (void) disableMetaWatchService;

// Register and unregister a widget with MetaWatch Manager
- (void) responseToPingOfWidgetTypeID:(NSString*)widgetTypeID;
- (void) registerNewWidgetType:(NSDictionary*)widgetDataDict;
- (void) unregisterWidgetType:(NSString*)widgetTypeID;

// Should be invoked everytime connected to watch once registered any widget type
- (void) updateWidgetsInfo;

// Write widget bitmap data
- (void) writeIdleWdiget:(NSUInteger)syncID withDataArray:(NSArray*)dataArray fromLine:(NSUInteger)startLineNum untilLine:(NSUInteger)endLineNum;

+ (NSData*) bitmapDataForCGImage:(CGImageRef)inImage;

@end

