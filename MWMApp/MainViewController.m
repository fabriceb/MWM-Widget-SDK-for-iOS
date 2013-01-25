//
//  MainViewController.m
//  MWMApp
//
//  Created by Siqi Hao on 10/25/12.
//  Copyright (c) 2012 MetaWatch Oy. All rights reserved.
//

#import "MainViewController.h"

#import "MWMAppManager.h"
#define kUPDATE_INTERVAL_SECONDS 3600 //14400 // 4 HOURS

@interface MainViewController () <MWMAppManagerDelegate>

@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UILabel *appnameLabel;

@property (nonatomic, strong) UIImage *previewImg;
@property (nonatomic, strong) NSMutableDictionary *widgetData;
@property (nonatomic) BOOL widgetShouldSendData;
@property (nonatomic) NSTimeInterval updatedTimestamp;

- (IBAction) enableMMBtnPressed:(id)sender;
- (IBAction) disableMMBtnPressed:(id)sender;
- (IBAction) registerExampleWidget:(id)sender;
- (IBAction) unregisterExampleWidget;

@end

#ifdef mwmapp2
static NSString *kWidgetTypeID = @"w_20000002";
#else
static NSString *kWidgetTypeID = @"w_20000001";
#endif

@implementation MainViewController

@synthesize statusLabel, previewImg, widgetData, widgetShouldSendData, appnameLabel, updatedTimestamp;

- (void) mwmAppMgrRestoredSyncID:(NSUInteger)syncID withWidgetType:(NSString*)widgetTypeID andLayoutType:(NSString*)layoutType {
    
    if (widgetTypeID.length == 0 || layoutType.length == 0) {
        // an existing widget restored
        NSLog(@"an existing widget restored:%d", syncID);
        widgetTypeID = [[widgetData objectForKey:[NSString stringWithFormat:@"%d", syncID]] objectAtIndex:0];
        layoutType = [[widgetData objectForKey:[NSString stringWithFormat:@"%d", syncID]] objectAtIndex:1];
        if (widgetTypeID.length == 0 || layoutType.length == 0) {
            // unknown widget, ask user to remove it from MWM and add again.
            NSLog(@"nothing here");
            return;
        }
    } else if ([kWidgetTypeID isEqualToString:widgetTypeID]) {
        // a new widget is created, save new widget info
        NSLog(@"a new widget is created, save new widget info");
        [widgetData setObject:@[widgetTypeID, layoutType] forKey:[NSString stringWithFormat:@"%d", syncID]];
        [self saveDataToDisk];
    } else {
        return;
    }
    
    //NSLog(@"%@", [widgetData description]);
    
    widgetShouldSendData = YES;
    
    [self sendBitmapDataWithSyncID:[NSString stringWithFormat:@"%d", syncID]];
}

- (void) sendBitmapDataWithSyncID:(NSString*)syncID {
    if (widgetShouldSendData == NO) {
        return;
    }
    
    if (syncID.length == 0) {
        for (NSString *syncIDString in widgetData.allKeys) {
            [self updateWidgetInstance:syncIDString];
        }
    } else {
        [self updateWidgetInstance:syncID];
    }
    
    updatedTimestamp = [NSDate timeIntervalSinceReferenceDate];
}

- (void) updateWidgetInstance:(NSString*)syncIDString {
    if ([[widgetData allKeys] containsObject:syncIDString] == NO) {
        return;
    }
    
    NSString *layoutType = [[widgetData objectForKey:syncIDString] objectAtIndex:1];
    NSUInteger syncID = [syncIDString integerValue];
    
    CGSize size  = [self getSizeFromLayoutType:layoutType];
    
    UIFont *font = [UIFont fontWithName:@"MetaWatch Small caps 8pt" size:8];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
    
    CGContextSetFillColorWithColor(ctx, [[UIColor blackColor]CGColor]);
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    [df setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    NSString *appName = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
    NSString *errorText = [NSString stringWithFormat:@"%@\nUspdated:\n%@", appName, [df stringFromDate:[NSDate date]]];
    
    CGSize idealSize = [errorText sizeWithFont:font constrainedToSize:size lineBreakMode:NSTextAlignmentCenter];
    
    [errorText drawInRect:CGRectMake((size.width - idealSize.width)*0.5, (size.height-idealSize.height)*0.5, idealSize.width, idealSize.height) withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
    
    previewImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [[MWMAppManager sharedAppManager] writeIdleWdiget:syncID withDataArray:[self generateBitmapDataArray] fromLine:0 untilLine:48*4];
}

#pragma mark - MWMAppManagerDelegate

- (void) mwmAppMgrRemovedSyncID:(NSUInteger)syncID {
    [widgetData removeObjectForKey:[NSString stringWithFormat:@"%d", syncID]];
    //NSLog(@"%@", [widgetData description]);
    [self saveDataToDisk];
}

- (void) mwmAppMgrDeallocedSyncID:(NSUInteger)syncID {
    // Often invoked when watch disconnected.
    // You can destory your widget instance but save widget data for next restore.
    widgetShouldSendData = NO;
}

- (void) widgetDataSource:(NSUInteger)syncID receiveHeartBeat:(NSTimeInterval)timeStamp {
    if (widgetShouldSendData == YES) {
        // Do regular update, maybe you need to update your widget hourly?
        // You should only update your widget when your widget is valid and restored.
        // Sync ID is not in used atm.
        if (timeStamp - updatedTimestamp >= kUPDATE_INTERVAL_SECONDS) {
            [self sendBitmapDataWithSyncID:nil];
        }
        NSLog(@"Widget receive heartbeat");
    }
}

- (void) mwmAppMgrDidReceiveWidgetInfoResponse:(NSArray *)widgetIDsArray forWidgetType:(NSString *)widgetTypeID {
    if ([widgetTypeID isEqualToString:kWidgetTypeID]) {
        if (widgetIDsArray.count == 1 && [[widgetIDsArray objectAtIndex:0] isEqualToString:@"255"]) {
            [widgetData removeAllObjects];
        } else {
            NSMutableArray *keysToRemove =[[widgetData allKeys] mutableCopy];
            [keysToRemove removeObjectsInArray:widgetIDsArray];
            [widgetData removeObjectsForKeys:keysToRemove];
        }
        
        //NSLog(@"%@", [widgetData description]);
        [self saveDataToDisk];
        
        for (NSString *syncID in widgetData) {
            [self mwmAppMgrRestoredSyncID:[syncID integerValue] withWidgetType:nil andLayoutType:nil];
        }
    }
}

- (void) mwmAppMgrDidDisableMetaWatchService {
    statusLabel.text = @"MetaWatch Service Disabled";
    widgetShouldSendData = NO;
}

- (void) mwmAppMgrDidEnableMetaWatchService {
    statusLabel.text = @"MetaWatch Service Enabled";
}

- (void) mwmAppMgrRegisteredWidgetType:(NSString *)widgetTypeID withError:(NSError *)error {
    if (error == nil) {
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:@"Widget registered" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else if (error.code == MWMAPP_REGISTER_DUPLICATED) {
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:@"Widget already registered." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else if (error.code == MWMAPP_INVALID_WIDGET_DATA) {
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:@"Invalid widget data format" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else if (error.code == MWMAPP_REGISTER_MWM_NOT_INSTALLED) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"MetaWatch Manager not installed. Please download from App Store." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:@"Unknown error. Report a bug if you see this." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void) mwmAppMgrUnregisteredWidgetType:(NSString*)widgetTypeID withError:(NSError *)error {
    if (error == nil) {
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:[NSString stringWithFormat:@"%@ unregistered", widgetTypeID] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else if (error.code == MWMAPP_UNREGISTER_FAILED_NOT_EXISTED) {
        // MWMAPP_UNREGISTER_FAILED
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:[NSString stringWithFormat:@"%@ does not exist", widgetTypeID] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else if (error.code == MWMAPP_UNREGISTER_FAILED_INUSE) {
        // MWMAPP_UNREGISTER_FAILED
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:[NSString stringWithFormat:@"%@ is in use. Please remove it first", widgetTypeID] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"MWMApp" message:@"Unknown error. Report a bug if you see this." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (NSArray*) mwmAppMgrRequestedWidgetTypeIDs {
    return @[kWidgetTypeID];
}

#pragma mark - IBActions

- (IBAction) enableMMBtnPressed:(id)sender {
    [[MWMAppManager sharedAppManager] enableMetaWatchService];
}

- (IBAction) disableMMBtnPressed:(id)sender {
    [[MWMAppManager sharedAppManager] disableMetaWatchService];
    
}

- (IBAction) registerExampleWidget:(id)sender {
    NSMutableDictionary *widgetDataDict = [NSMutableDictionary dictionary];
    
    // Indicate this is a register widget action
    [widgetDataDict setObject:@"registerWidgetType" forKey:@"action"];
    
    // Sandard for all widgets
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    [widgetDataDict setObject:appName forKey:@"widgetAppName"];
    [widgetDataDict setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"widgetAppID"];
    
    // Put your widget type ID here.
    [widgetDataDict setObject:kWidgetTypeID forKey:@"widgetID"];
    
    #ifdef mwmapp2
    // a: one square widget
    // b: horizental widget
    // c: vertical widget
    // d: full screen widget
    [widgetDataDict setObject:@[@"a", @"b", @"c", @"d"] forKey:@"supportedLayouts"];
    
    // widget name
    [widgetDataDict setObject:@"ChromeWidget" forKey:@"widgetName"];
    
    // Has to be 76*76 PNG!
    [widgetDataDict setObject:UIImagePNGRepresentation([UIImage imageNamed:@"mwmapp2"]) forKey:@"widgetIcon"];
    
    // If you only supports one instance per widget type, put YES here. Singleton widget is more stable and easy to implement.
    [widgetDataDict setObject:[NSNumber numberWithBool:NO] forKey:@"singleton"];
    
    #else
    [widgetDataDict setObject:@[@"a", @"b"] forKey:@"supportedLayouts"];
    [widgetDataDict setObject:@"HomeWidget" forKey:@"widgetName"];
    [widgetDataDict setObject:UIImagePNGRepresentation([UIImage imageNamed:@"mwmapp1"]) forKey:@"widgetIcon"];
    [widgetDataDict setObject:[NSNumber numberWithBool:YES] forKey:@"singleton"];
    #endif
    
    //NSLog(@"%@", [widgetDataDict description]);
    
    [[MWMAppManager sharedAppManager] registerNewWidgetType:widgetDataDict withView:self.view];
    return;
}

- (IBAction) unregisterExampleWidget {
    [[MWMAppManager sharedAppManager] unregisterWidgetType:kWidgetTypeID];
}

#pragma mark - VC Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [MWMAppManager sharedAppManager].delegate = self;
    widgetShouldSendData = NO;
    [self loadDataFromDisk];
    appnameLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Presistence
- (void) loadDataFromDisk {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"mwmappdata.bin"];

    NSDictionary * rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    self.widgetData = [rootObject valueForKey:@"widgetdata"];
    
    if (widgetData == nil) {
        widgetData = [NSMutableDictionary dictionary];
    }
}

- (void) saveDataToDisk
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"mwmappdata.bin"];
    
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    
    [rootObject setValue:widgetData forKey:@"widgetdata"];
    [NSKeyedArchiver archiveRootObject: rootObject toFile: path];
}

#pragma mark - Helpers
- (CGSize) getSizeFromLayoutType:(NSString*)type {
    if ([type isEqualToString:@"a"]) {
        return CGSizeMake(WIDGETSIZE, WIDGETSIZE);
    } else if ([type isEqualToString:@"b"]) {
        return CGSizeMake(2*WIDGETSIZE, WIDGETSIZE);
    } else if ([type isEqualToString:@"c"]) {
        return CGSizeMake(WIDGETSIZE, 2*WIDGETSIZE);
    } else if ([type isEqualToString:@"d"]) {
        return CGSizeMake(2*WIDGETSIZE, 2*WIDGETSIZE);
    }
    return CGSizeZero;
}

- (NSArray*) generateBitmapDataArray {
    CGRect frame1 = CGRectMake(0, 0, WIDGETSIZE, WIDGETSIZE);
    CGRect frame2 = CGRectMake(WIDGETSIZE, 0, WIDGETSIZE, WIDGETSIZE);
    CGRect frame3 = CGRectMake(0, WIDGETSIZE, WIDGETSIZE, WIDGETSIZE);
    CGRect frame4 = CGRectMake(WIDGETSIZE, WIDGETSIZE, WIDGETSIZE, WIDGETSIZE);
    
    CGImageRef imgRef = NULL;
    if (previewImg == nil) {
        return [NSMutableArray array];
    } else {
        imgRef = previewImg.CGImage;
        CGImageRetain(imgRef);
    }
    
    CGImageRef imageRef1 = CGImageCreateWithImageInRect(imgRef, frame1);
    CGImageRef imageRef2 = CGImageCreateWithImageInRect(imgRef, frame2);
    CGImageRef imageRef3 = CGImageCreateWithImageInRect(imgRef, frame3);
    CGImageRef imageRef4 = CGImageCreateWithImageInRect(imgRef, frame4);
    
    NSData *data1 = [MWMAppManager bitmapDataForCGImage:imageRef1];
    NSData *data2 = [MWMAppManager bitmapDataForCGImage:imageRef2];
    NSData *data3 = [MWMAppManager bitmapDataForCGImage:imageRef3];
    NSData *data4 = [MWMAppManager bitmapDataForCGImage:imageRef4];
    
    CGImageRelease(imgRef);
    
    NSMutableArray *returnArray = [NSMutableArray array];
    if (data1.length > 1) {
        [returnArray addObject:data1];
    }
    if (data2.length > 1) {
        [returnArray addObject:data2];
    }
    if (data3.length > 1) {
        [returnArray addObject:data3];
    }
    if (data4.length > 1) {
        [returnArray addObject:data4];
    }
    
    //ALog(@"%@", [returnArray description]);
    
    return returnArray;
}

@end
