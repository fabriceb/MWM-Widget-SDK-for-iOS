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

// Error code for BLE status
#define DISCONNECTEDUNKNOWN 201
#define DISCONNECTEDBYUSER 202
#define DISCONNECTEDBY8882 203
#define DISCONNECTEDBYBLEPOWER 204
#define DISCONNECTEDBYBLENOTIF 205
#define DISCONNECTEDBY8880 206

// Error code for MWMApp
#define MWMAPP_INVALID_WIDGET_DATA 401
#define MWMAPP_REGISTER_DUPLICATED 402
#define MWMAPP_UNREGISTER_FAILED_NOT_EXISTED 403
#define MWMAPP_UNREGISTER_FAILED_INUSE 404
#define MWMAPP_REGISTER_MWM_NOT_INSTALLED 405
#define MWMAPP_UPDATE_NOT_EXISTED 406

@protocol MWMAppManagerDelegate <NSObject>

@required

/*!
 *  @method mwmAppMgrDidEnableMetaWatchService
 *
 *  @discussion Invoked when MetaWatch is ready to be used.
 *
 */
- (void) mwmAppMgrDidEnableMetaWatchService;

/*!
 *  @method mwmAppMgrDidDisableMetaWatchService
 *
 *  @discussion Invoked when MetaWatch is disconnected.
 *
 */
- (void) mwmAppMgrDidDisableMetaWatchService;

/*!
 *  @method mwmAppMgrRequestedWidgetTypeIDs:
 *
 *  @discussion MWMApp should implement this method to return all registered widget type IDs.
 *
 */
- (NSArray*) mwmAppMgrRequestedWidgetTypeIDs;

/*!
 *  @method mwmAppMgrDidReceiveWidgetInfoResponse:forWidgetType:
 *  @param widgetIDsArray The widget instance IDs/sync IDs for the specific widget type.
 *  @param widgetTypeID The widget type ID related to the callback.
 *
 *  @discussion This methods will be invoked upon updateWidgetsInfo.
 *
 */
- (void) mwmAppMgrDidReceiveWidgetInfoResponse:(NSArray*)widgetIDsArray forWidgetType:(NSString*)widgetTypeID;

/*!
 *  @method mwmAppMgrRegisteredWidgetType:withError:
 *  @param widgetTypeID The widget type ID related to the callback.
 *  @param error Error domain is MWMApp, error code refers to header.
 *
 *  @discussion This methods will be invoked when MWMApp finsihed a registration operation.
 *
 */
- (void) mwmAppMgrRegisteredWidgetType:(NSString*)widgetTypeID withError:(NSError*)error;

- (void) mwmAppMgrUpdatedWidgetType:(NSString*)widgetTypeID withError:(NSError*)error;

/*!
 *  @method mwmAppMgrUnregisteredWidgetType:withError:
 *  @param widgetTypeID The widget type ID related to the callback.
 *  @param error Error domain is MWMApp, error code refers to header.
 *
 *  @discussion This methods will be invoked when MWMApp finsihed a unregistration operation.
 *
 */
- (void) mwmAppMgrUnregisteredWidgetType:(NSString*)widgetTypeID withError:(NSError*)error;

/*!
 *  @method mwmAppMgrRestoredSyncID:withWidgetType:andLayoutType:
 *  @param widgetTypeID The widget type ID related to the callback.
 *  @param syncID also refers to widget instance ID, a valid sync ID is ranged from 16 to 254. MWMApp should use this as the identifier of each widget instance. Same widget type may have different sync IDs if singleton has to set to NO.
 *  @param layoutType a,b,c,d
 *
 *  @discussion This methods will be invoked when a widget instance is created, meaning either a new widget instance is created or previous widget instance is recreated.
 *
 */
- (void) mwmAppMgrRestoredSyncID:(NSUInteger)syncID withWidgetType:(NSString*)widgetTypeID andLayoutType:(NSString*)layoutType;

/*!
 *  @method mwmAppMgrRemovedSyncID:
 *  @param syncID The widget instanc ID or sync ID.
 *
 *  @discussion This methods will be invoked when a widget has been deleted from watch by user. MWMApp can delete all preferences and data sources of this widget instance upon receiving this callback.
 *
 */
- (void) mwmAppMgrRemovedSyncID:(NSUInteger)syncID;

/*!
 *  @method mwmAppMgrDeallocedSyncID:
 *  @param syncID The widget instanc ID or sync ID.
 *
 *  @discussion This methods will be invoked when MetaWatch Manager disconnected with MetaWatch, meaning user deso not need any updates for widgets. MWMApp should dealloc the widget data source and save widget perferences for next restore.
 *
 */
- (void) mwmAppMgrDeallocedSyncID:(NSUInteger)syncID;

@optional

/*!
 *  @method widgetDataSource:receiveHeartBeat:
 *  @param syncID Not in use
 *
 *  @discussion This methods will be invoked per minute. MWMApp can do peridical update here. Of course if your app can wake up more frequent than this interval, you are also free to send updates to MetaWatch.
 *
 */
- (void) widgetDataSource:(NSUInteger)syncID receiveHeartBeat:(NSTimeInterval)timeStamp;

@end

@interface MWMAppManager : NSObject

@property (nonatomic, weak) id<MWMAppManagerDelegate> delegate;

@property (nonatomic, readonly) BOOL watchConnected;

/*!
 *  @method countOfBleMsg
 *
 *  @discussion Return the current BLE messages in the queue.
 *
 */
- (NSUInteger) countOfBleMsg;

/*!
 *  @method sharedAppManager
 *
 *  @discussion This method has to be invoked in applications:didFinishLaunchingWithOptions:
 *
 */
+ (MWMAppManager *) sharedAppManager;

/*!
 *  @method handleURL:fromAPP:withAnnotation:
 *
 *  @discussion This method has to be invoked within
 *  application:openURL:sourceApplication:annotation:
 *  so url whose scheme starts with mwmapp can be passed to MWMAppManager.
 *
 */
- (void) handleURL:(NSURL*)url fromAPP:(NSString*)appIdentifier withAnnotation:(id)annotation;

/*!
 *  @method enableMetaWatchService
 *
 *  @discussion This method will enable MetaWatch Service or pair another
 *  watch. You only need to invoke this method once until you invoke disableMetaWatchService.
 *
 */
- (void) enableMetaWatchService;

/*!
 *  @method disableMetaWatchService
 *
 *  @discussion This method will disable MetaWatch Service and un-pair the watch.
 *
 */
- (void) disableMetaWatchService;

/*!
 *  @method registerNewWidgetType:withView:
 *
 *  @discussion
 *
 */
- (void) registerNewWidgetType:(NSDictionary*)widgetDataDict withView:(UIView*)fromView;

/*!
 *  @method unregisterWidgetType:
 *
 *  @discussion
 *
 */
- (void) unregisterWidgetType:(NSString*)widgetTypeID;

/*!
 *  @method updateWidgetsInfo
 *
 *  @discussion Request widget information manually if needed.
 *
 */
- (void) updateWidgetsInfo;

/*!
 *  @method writeIdleWdiget:withDataArray:fromLine:untilLine:
 *
 *  @discussion
 *
 */
- (void) writeIdleWdiget:(NSUInteger)syncID withDataArray:(NSArray*)dataArray fromLine:(NSUInteger)startLineNum untilLine:(NSUInteger)endLineNum;

/*!
 *  @method bitmapDataForCGImage:
 *
 *  @discussion
 *
 */
+ (NSData*) bitmapDataForCGImage:(CGImageRef)inImage;

@end

