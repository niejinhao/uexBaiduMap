//
//  EUExBaiduMap.m
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/3.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "EUExBaiduMap.h"
#import <BaiduMapAPI_Map/BMKMapView.h>
#import "JSON.h"
#import "MapUtility.h"
#import "ACPointAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import "BaiduMapManager.h"
#import "CustomPaoPaoView.h"
#import "BusLineAnnotation.h"
#import "RouteAnnotation.h"
#import "SearchPlanObject.h"
#import "BusLineObjct.h"

@interface EUExBaiduMap()<BMKGeneralDelegate,BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,BMKSuggestionSearchDelegate,BMKPoiSearchDelegate,BMKBusLineSearchDelegate,BMKRouteSearchDelegate>

@property (nonatomic, retain) NSMutableDictionary * overlayDataDic;
@property (nonatomic, retain) NSMutableDictionary * overlayViewDic;
@property (nonatomic, retain) NSMutableDictionary * pointAnnotationDic;
@property (nonatomic, retain) NSMutableDictionary * pointAnnotationViewDic;
@property (nonatomic, retain) NSMutableDictionary * routePlanDic;

@property (nonatomic, retain) NSMutableArray * busPoiArray;

@property (nonatomic, retain) BMKMapManager * mapManager;
@property (nonatomic, retain) BMKMapView * currentMapView;
@property (nonatomic, retain) BMKLocationService * locationService;
@property (nonatomic, retain) BMKGeoCodeSearch * geoCodeSearch;
@property (nonatomic, retain) BMKSuggestionSearch * suggestionSearch;
@property (nonatomic, retain) BMKPoiSearch * POISearch;
@property (nonatomic, retain) BMKBusLineSearch * busLineSearch;
@property (nonatomic, retain) BMKRouteSearch * routeSearch;

@property (nonatomic, assign) int pageCapacity;
@property (nonatomic, assign) int currentIndex;
@property (nonatomic, assign) BOOL isUpdateLocationOnce;
@property (nonatomic, assign) BOOL didStartLocatingUser;
@property (nonatomic, assign) BOOL showCallOut;
@property (nonatomic, assign) BOOL didBusLineSearch;
@property (nonatomic, assign) BOOL isFirstTime;

@property (nonatomic, assign) CGPoint positionOfCompass;

@property (nonatomic, copy) NSString * searchCity;



@end

@implementation EUExBaiduMap

-(id)initWithBrwView:(EBrowserView *)eInBrwView {
    if (self = [super initWithBrwView:eInBrwView]) {
        _didStartLocatingUser = NO;
        _isUpdateLocationOnce = NO;
        _didBusLineSearch = NO;
        self.pageCapacity = 10;
        self.overlayDataDic = [NSMutableDictionary dictionary];
        self.overlayViewDic = [NSMutableDictionary dictionary];
        self.pointAnnotationDic = [NSMutableDictionary dictionary];
        self.routePlanDic = [NSMutableDictionary dictionary];
        self.pointAnnotationViewDic = [NSMutableDictionary dictionary];
        self.positionOfCompass = CGPointMake(10, 10);
        _showCallOut = NO;
    }
    return self;
}



//-(void)dealloc{
//    [super dealloc];
//}
//
//-(void)clean{
//    if (_locationService) {
//        _locationService.delegate = nil;
//        [_locationService release];
//    }
//    
//    [_routePlanDic removeAllObjects];
//    [_routePlanDic release];
//    
//    [_overlayViewDic removeAllObjects];
//    [_overlayViewDic release];
//    
//    [_overlayDataDic removeAllObjects];
//    [_overlayDataDic release];
//    
//    [_pointAnnotationDic removeAllObjects];
//    [_pointAnnotationDic release];
//    
//    [_pointAnnotationViewDic removeAllObjects];
//    [_pointAnnotationViewDic release];
//    
//    if (_busPoiArray) {
//        [_busPoiArray removeAllObjects];
//        [_busPoiArray release];
//    }
//    
//    if (_routeSearch) {
//        _routeSearch.delegate = nil;
//        [_routeSearch release];
//    }
//    if (_busLineSearch) {
//        _busLineSearch.delegate = nil;
//        [_busLineSearch release];
//    }
//    if (_POISearch) {
//        _POISearch.delegate = nil;
//        [_POISearch release];
//    }
//    if (_suggestionSearch) {
//        _suggestionSearch.delegate = nil;
//        [_suggestionSearch release];
//    }
//    if (_geoCodeSearch) {
//        _geoCodeSearch.delegate = nil;
//        [_geoCodeSearch release];
//    }
//    if (_currentMapView) {
//        [_currentMapView setDelegate:nil];
//        [_currentMapView viewWillDisappear];
//        [_currentMapView removeFromSuperview];
//        [_currentMapView release];
//        //解决百度地图手势，跟root view 手势冲突问题
//        //        [EUtility setRootViewGestureRecognizerEnabled:YES];
//        
//    }
//    if (_mapManager) {
//        [_mapManager stop];
//        [_mapManager release];
//    }
//}
-(void)clean{
    if (_locationService) {
        _locationService.delegate = nil;
    }
    
    [_routePlanDic removeAllObjects];
    [_overlayViewDic removeAllObjects];
    [_overlayDataDic removeAllObjects];
    [_pointAnnotationDic removeAllObjects];
    [_pointAnnotationViewDic removeAllObjects];
    
    if (_busPoiArray) {
        [_busPoiArray removeAllObjects];
    }
    
    if (_routeSearch) {
        _routeSearch.delegate = nil;
    }
    if (_busLineSearch) {
        _busLineSearch.delegate = nil;
    }
    if (_POISearch) {
        _POISearch.delegate = nil;
    }
    if (_suggestionSearch) {
        _suggestionSearch.delegate = nil;
    }
    if (_geoCodeSearch) {
        _geoCodeSearch.delegate = nil;
    }
    if (_currentMapView) {
        [_currentMapView setDelegate:nil];
        [_currentMapView viewWillDisappear];
        [_currentMapView removeFromSuperview];
        //解决百度地图手势，跟root view 手势冲突问题
//        [EUtility setRootViewGestureRecognizerEnabled:YES];

    }
    if (_mapManager) {
        [_mapManager stop];
    }
}


//*********************start*******************************************
-(BOOL)start{
    
    NSString * baiduMapKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"uexBaiduMapKey"];
    self.mapManager = [BaiduMapManager defaultManager];
    BOOL ret = [self.mapManager start:baiduMapKey generalDelegate:self];
    return ret;
    
}
//E_PERMISSIONCHECK_CONNECT_ERROR = -300,//链接服务器错误
//E_PERMISSIONCHECK_DATA_ERROR = -200,//服务返回数据异常
//E_PERMISSIONCHECK_OK = 0,	// 授权验证通过
//E_PERMISSIONCHECK_PARAM_ERROR = 2,	// 参数错误
//E_PERMISSIONCHECK_KEY_ERROR = 5,	//ak不存在
//E_PERMISSIONCHECK_SERVER_FORBIDEN = 101,	//该服务被禁用
//E_PERMISSIONCHECK_MCODE_ERROR = 102,	//mcode签名值不正确
//E_PERMISSIONCHECK_UID_KEY_ERROR = 231,	// 用户uid，ak不存在
//E_PERMISSIONCHECK_KEY_FORBIDEN= 232,	// 用户、ak被封禁
/**
 *返回网络错误
 *@param iError 错误号
 */
- (void)onGetNetworkState:(int)iError{
    if (iError == 0) {
        //
    } else {
        
        NSString * onString = [NSString stringWithFormat:@"{\"errorInfo\": \"%d\"}",iError];
        NSString * inCallbackName = @"uexBaiduMap.onSDKReceiverError";
        NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onString];
        [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    }
    
}

/**
 *返回授权验证错误
 *@param iError 错误号 : 为0时验证通过，具体参加BMKPermissionCheckResultCode
 */
- (void)onGetPermissionState:(int)iError{
    if (iError == 0) {
        [self jsSuccessWithName:@"uexBaiduMap.cbStart" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:iError];
    } else {
        NSString * onString = [NSString stringWithFormat:@"{\"errorInfo\": \"%d\"}",iError];
        NSString * inCallbackName = @"uexBaiduMap.onSDKReceiverError";
        NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onString];
        [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    }
}
//******************************基本功能************************************
//打开地图
-(void)open:(NSMutableArray *)inArguments{
    _isFirstTime = YES;
    if ([inArguments count] < 4) {
        
        return;
        
    }
    
    if (![self start]) {
        return;
    }
    
    
    //打开地图 设置中心点
    float x = [[inArguments objectAtIndex:0] floatValue];
    float y = [[inArguments objectAtIndex:1] floatValue];
    float w = [[inArguments objectAtIndex:2] floatValue];
    float h  = [[inArguments objectAtIndex:3] floatValue];
    
    if (!_currentMapView) {
        
        _currentMapView = [[BMKMapView alloc]initWithFrame:CGRectMake(x, y, w, h)];
        [self.currentMapView setDelegate:self];
        

        
        //解决百度地图手势，跟root view 手势冲突问题
//        [EUtility setRootViewGestureRecognizerEnabled:NO];
        
        [self.currentMapView viewWillAppear];
        [EUtility brwView:meBrwView addSubview:self.currentMapView];
        
    }
    
    if ([inArguments count] == 6) {
        
        double  longit = [[inArguments objectAtIndex:4] doubleValue];
        double  lat =  [[inArguments objectAtIndex:5] doubleValue];
        
        CLLocationCoordinate2D lC2D;
        lC2D.longitude = longit;
        lC2D.latitude = lat;
        [self.currentMapView setCenterCoordinate:lC2D animated:NO];
        
    }
}

//***************隐藏和显示百度地图************
-(void)hideMap:(NSMutableArray *)inArguments{
    [self.currentMapView setHidden:YES];
}

-(void)showMap:(NSMutableArray *)inArguments{
    [self.currentMapView setHidden:NO];
}

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView
{
    NSString * inCallbackName = @"uexBaiduMap.cbOpen";
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@();}",inCallbackName,inCallbackName];
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
}


//关闭地图
-(void)close:(NSMutableArray *)inArguments{
    
    if (_currentMapView) {
        [_currentMapView setDelegate:nil];
        [_currentMapView viewWillDisappear];
        [_currentMapView removeFromSuperview];
//        [_currentMapView release];
        _currentMapView = nil;
        //解决百度地图手势，跟root view 手势冲突问题
//        [EUtility setRootViewGestureRecognizerEnabled:YES];
        
    }
}

//设置地图的类型
//BMKMapTypeStandard   = 1,               ///< 标准地图
//BMKMapTypeSatellite  = 4,               ///< 卫星地图
-(void)setMapType:(NSMutableArray *)inArguments{
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    NSInteger mapType = [inArguments[0] integerValue];
    if (mapType == 1) {
         _currentMapView.mapType = BMKMapTypeStandard;
    }else if (mapType == 2){
        _currentMapView.mapType = BMKMapTypeSatellite;
    }

}
//设置是否开启实时交通
-(void)setTrafficEnabled:(NSMutableArray *)inArguments{
    @try {
        NSString * mapType = [inArguments objectAtIndex:0];
        if ([mapType intValue] == 0) {
            [_currentMapView setTrafficEnabled:NO];
        } else {
            [_currentMapView setTrafficEnabled:YES];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"setTrafficEnabled==>catch==>%@",[exception description]);
    }
    @finally {
        NSLog(@"setTrafficEnabled==>finally");
    }
}
/**
 *设定地图中心点坐标
 *@param coordinate 要设定的地图中心点坐标，用经纬度表示
 *@param animated 是否采用动画效果
 */
-(void)setCenter:(NSMutableArray *)inArguments{
    double  longit = [[inArguments objectAtIndex:0] doubleValue];
    double  lat =  [[inArguments objectAtIndex:1] doubleValue];
    BOOL  animate = NO;
    if (inArguments.count == 3) {
        animate = [[inArguments objectAtIndex:2] boolValue];
    }
    CLLocationCoordinate2D lC2D;
    lC2D.longitude = longit;
    lC2D.latitude = lat;
    [_currentMapView setCenterCoordinate:lC2D animated:animate];
}

//************************覆盖物功能******************************

-(void)addMarkersOverlay:(NSMutableArray *)inArguments{
    
    NSString * jsStr = [inArguments objectAtIndex:0];
    NSArray * jsArray = [jsStr JSONValue];
    for (NSDictionary * markDic in jsArray) {
        NSString * idStr = [markDic objectForKey:@"id"];
        double lon = [[markDic objectForKey:@"longitude"] doubleValue];
        double lat = [[markDic objectForKey:@"latitude"] doubleValue];
        NSString * iconPath = [markDic objectForKey:@"icon"];
        ACPointAnnotation *aPoint = [[ACPointAnnotation alloc] init];
        CLLocationCoordinate2D cc2d;
        cc2d.longitude = lon;
        cc2d.latitude = lat;
        aPoint.coordinate = cc2d;
        aPoint.pointId = idStr;
        if (iconPath && [iconPath length] > 0) {
            aPoint.iconUrl = [self absPath:iconPath];
        }
        [_currentMapView addAnnotation:aPoint];
        [self.pointAnnotationDic setObject:aPoint forKey:idStr];
//        [aPoint release];
    }
}

-(void)setMarkerOverlay:(NSMutableArray *)inArguments {
    if (!inArguments || [inArguments count] != 2) {
        return;
    }
    NSString * idStr = [inArguments objectAtIndex:0];
    ACPointAnnotation * oldPointAnnotation = [self.pointAnnotationDic objectForKey:idStr];
    if (!oldPointAnnotation) {
        return;
    }
    [self.currentMapView removeAnnotation:oldPointAnnotation];
    
    
    NSString * jsStr = [inArguments objectAtIndex:1];
    NSDictionary * markInfoDic = [jsStr JSONValue];
    NSDictionary * markInfo = [markInfoDic objectForKey:@"makerInfo"];
    if (markInfo) {
        CLLocationCoordinate2D cc2d = oldPointAnnotation.coordinate;
        
        if ([markInfo objectForKey:@"longitude"]) {
            double lon = [[markInfo objectForKey:@"longitude"] doubleValue];
            cc2d.longitude = lon;
            oldPointAnnotation.coordinate = cc2d;
        }
        if ([markInfo objectForKey:@"latitude"]) {
            double lat = [[markInfo objectForKey:@"latitude"] doubleValue];
            cc2d.latitude = lat;
            oldPointAnnotation.coordinate = cc2d;
        }
        NSString * iconPath = [markInfo objectForKey:@"icon"];
        if (iconPath && [iconPath length] > 0) {
            oldPointAnnotation.iconUrl = [self absPath:iconPath];
        }
        NSDictionary * bubble = [markInfo objectForKey:@"bubble"];
        if (bubble && [[bubble allKeys]count] > 0) {
            NSString * title= [bubble objectForKey:@"title"];
            if (title && [title length] > 0) {
                oldPointAnnotation.title = title;
            }
            NSString * imageUrl = [bubble objectForKey:@"bgImage"];
            if (imageUrl && [imageUrl length] > 0) {
                oldPointAnnotation.imageUrl = [self absPath:imageUrl];
            }
        }
        
    }

    [_currentMapView addAnnotation:oldPointAnnotation];
    
}

-(void)showBubble:(NSMutableArray *)inArguments {
    NSString * idStr = [inArguments objectAtIndex:0];
    ACPointAnnotation * pAnnotation = [self.pointAnnotationDic objectForKey:idStr];
    [_currentMapView selectAnnotation:pAnnotation animated:YES];
    for (ACPointAnnotation * pAnnotation in [self.pointAnnotationDic allValues]) {
        if ([pAnnotation.pointId isEqual:idStr]) {
            [_currentMapView selectAnnotation:pAnnotation animated:YES];
        } else {
            [_currentMapView deselectAnnotation:pAnnotation animated:YES];
        }
    }
}

-(void)hideBubble:(NSMutableArray *)inArguments {
    for (ACPointAnnotation * pAnnotation in [self.pointAnnotationDic allValues]) {
            [_currentMapView deselectAnnotation:pAnnotation animated:YES];
    }
}

-(void)removeMakersOverlay:(NSMutableArray *)inArguments {
    if(inArguments.count == 0){
        return;
    }
    NSArray *idArray = nil;
    id param = inArguments[0];
    if (!param) {
        return;
    }
    if ([param isKindOfClass:[NSArray class]]) {
        idArray = param;
    }
    if ([param isKindOfClass:[NSString class]]) {
        NSString * firstStr = [param stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
        idArray = [firstStr componentsSeparatedByString:@","];
    }
    if (!idArray) {
        return;
    }
    
    if ([idArray count] == 0) {
        [_currentMapView removeAnnotations:_currentMapView.annotations];
        [self.pointAnnotationDic removeAllObjects];
        return;
    }
    for (id aId in idArray) {
        NSString * identifier = nil;
        if ([aId isKindOfClass:[NSString class]]) {
            identifier = aId;
        }
        if ([aId isKindOfClass:[NSNumber class]]) {
            identifier = [aId stringValue];
        }
        if (!identifier) {
            continue;
        }
        identifier = [identifier stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"\""]];
        ACPointAnnotation * pAnnotation = [self.pointAnnotationDic objectForKey:identifier];
        [_currentMapView removeAnnotation:pAnnotation];
        [self.pointAnnotationDic removeObjectForKey:identifier];
    }
}

- (NSString*)getMyBundlePath1:(NSString *)filename
{
    NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"mapapi.bundle"];
    NSBundle * libBundle = [NSBundle bundleWithPath: path] ;
    if ( libBundle && filename ){
        NSString * s=[[libBundle resourcePath ] stringByAppendingPathComponent : filename];
        return s;
    }
    return nil ;
}

- (BMKAnnotationView*)getRouteAnnotationView:(BMKMapView *)mapview viewForAnnotation:(BusLineAnnotation*)routeAnnotation
{
    BMKAnnotationView* view = nil;
    switch (routeAnnotation.type) {
        case 0:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"start_node"];
            if (view == nil) {
                //                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_start.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_end.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 2:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"bus_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"bus_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"bus_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_bus.png"]];
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 3:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"rail_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"rail_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"rail_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_rail.png"]];
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 4:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_direction.png"]];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
            
        }
            break;
        default:
            break;
    }
    
    return view;
}

- (BMKAnnotationView*)getRouteAnnotationView1:(BMKMapView *)mapview viewForAnnotation:(RouteAnnotation*)routeAnnotation
{
    BMKAnnotationView* view = nil;
    switch (routeAnnotation.type) {
        case 0:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"start_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_start.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"end_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_end.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 2:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"bus_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"bus_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"bus_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_bus.png"]];
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 3:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"rail_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"rail_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"rail_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_rail.png"]];
                view.canShowCallout = TRUE;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 4:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"route_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"route_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_direction.png"]];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
            
        }
            break;
        case 5:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"waypoint_node"];
            if (view == nil) {
//                view = [[[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"waypoint_node"] autorelease];
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"waypoint_node"];
                view.canShowCallout = TRUE;
            } else {
                [view setNeedsDisplay];
            }
            
            UIImage* image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_waypoint.png"]];
            view.image = [image imageRotatedByDegrees:routeAnnotation.degree];
            view.annotation = routeAnnotation;
        }
            break;
        default:
            break;
    }
    
    return view;
}



- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        return [self getRouteAnnotationView1:mapView viewForAnnotation:(RouteAnnotation *)annotation];
    }
    if ([annotation isKindOfClass:[BusLineAnnotation class]]) {
        return [self getRouteAnnotationView:mapView viewForAnnotation:(BusLineAnnotation*)annotation];
    }
    if ([annotation isKindOfClass:[ACPointAnnotation class]]) {
        ACPointAnnotation * newAnnotation = (ACPointAnnotation *)annotation;
        
//        BMKPinAnnotationView * newAnnotationView = [[[BMKPinAnnotationView alloc] initWithAnnotation:newAnnotation reuseIdentifier:@"AppCanAnnotation"] autorelease];
        BMKPinAnnotationView * newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:newAnnotation reuseIdentifier:@"AppCanAnnotation"];
        if (newAnnotation.iconUrl) {
            if ([newAnnotation.iconUrl hasPrefix:@"http"]) {
                NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:newAnnotation.iconUrl]];
                newAnnotationView.image = [UIImage imageWithData:imageData];
            } else {
            newAnnotationView.image = [UIImage imageWithContentsOfFile:newAnnotation.iconUrl];
            }
        }else {
            // 设置颜色
            ((BMKPinAnnotationView*)newAnnotationView).pinColor = BMKPinAnnotationColorPurple;
        }
        if (newAnnotation.imageUrl) {
            
            UIImage * image = nil;
            if ([newAnnotation.imageUrl hasPrefix:@"http"]) {
                NSURL * url = [NSURL URLWithString: newAnnotation.imageUrl];
                image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
            } else {
                image = [UIImage imageWithContentsOfFile:newAnnotation.imageUrl];
            }
            
            UIImageView * imageV = [[UIImageView alloc]initWithImage:image];
            CustomPaoPaoView * customView = [[CustomPaoPaoView alloc]initWithFrame:imageV.frame];
            customView.backgroundColor = [UIColor redColor];
            customView.bgImageView.image = [UIImage imageWithContentsOfFile:newAnnotation.imageUrl];
            
            //宽度不变，根据字的多少计算label的高度
            CGSize size = [newAnnotation.title sizeWithFont:customView.title.font constrainedToSize:CGSizeMake(MAXFLOAT, imageV.frame.size.width) lineBreakMode:NSLineBreakByWordWrapping];
            //根据计算结果重新设置UILabel的尺寸
            [customView.title setFrame:CGRectMake(0, 0, size.width, size.height)];
            customView.title.center = customView.center;
        customView.title.text=newAnnotation.title;
            
            BMKActionPaopaoView * ppaoView = [[BMKActionPaopaoView alloc]initWithCustomView:customView];
            newAnnotationView.paopaoView = ppaoView;
            newAnnotationView.canShowCallout = YES;

        }
        
        // 从天上掉下效果
        ((BMKPinAnnotationView*)newAnnotationView).animatesDrop = NO;
        // 设置可拖拽
        ((BMKPinAnnotationView*)newAnnotationView).draggable = NO;
        [_pointAnnotationViewDic setObject:newAnnotationView forKey:newAnnotation.pointId];
        return newAnnotationView;
    }
    return nil;
}

/**
 *当选中一个annotation views时，调用此接口
 *@param mapView 地图View
 *@param views 选中的annotation views
 */
- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
    for (NSString * pointId in [_pointAnnotationViewDic allKeys]) {
        BMKAnnotationView * aView = [_pointAnnotationViewDic objectForKey:pointId];
        if ([aView isEqual:view]) {
            NSString * inCallbackName = @"uexBaiduMap.onMakerClickListner";
            NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,pointId];
            [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
            
            //onMarkerClickListener
            NSString *cbName = @"uexBaiduMap.onMarkerClickListener";
            NSString *cbSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",cbName,cbName,pointId];
            [EUtility brwView:self.meBrwView evaluateScript:cbSuccessStr];
            
        }
    }
    
}

//添加点覆盖物{"id":"d1","fillColor":"#111333","radius":20,"latitude":39.532,"longitude":116.222}
-(void)addDotOverlay:(NSMutableArray *)inArguments{
    NSString * jsonStr = [inArguments objectAtIndex:0];
    NSDictionary *dict = [jsonStr JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    if ([_overlayViewDic objectForKey:idStr]) {
        [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    //    [self.overlayDataDic setDictionary:dict];
    [self.overlayDataDic setObject:@"0" forKey:@"lineWidth"];
    [self.overlayDataDic setObject:@"#000000" forKey:@"strokeColor"];
    CLLocationCoordinate2D coor;
    coor.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    coor.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    float radius = [[dict objectForKey:@"radius"] floatValue];
    BMKCircle* circle = [BMKCircle circleWithCenterCoordinate:coor radius:radius];
    [_currentMapView addOverlay:circle];
}

//添加弧线覆盖物
-(void)addArcOverlay:(NSMutableArray *)inArguments{
    NSDictionary *dict = [[inArguments objectAtIndex:0] JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    if ([_overlayViewDic objectForKey:idStr]) {
        [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    //    [self.overlayDataDic setDictionary:dict];
    CLLocationCoordinate2D coords[3] = {0};
    coords[0].latitude = [[dict objectForKey:@"startLatitude"] doubleValue];
    coords[0].longitude = [[dict objectForKey:@"startLongitude"] doubleValue];
    coords[1].latitude = [[dict objectForKey:@"centerLatitude"] doubleValue];
    coords[1].longitude = [[dict objectForKey:@"centerLongitude"] doubleValue];
    coords[2].latitude = [[dict objectForKey:@"endLatitude"] doubleValue];
    coords[2].longitude = [[dict objectForKey:@"endLongitude"] doubleValue];
    BMKArcline * arcline = [BMKArcline arclineWithCoordinates:coords];
    [_currentMapView addOverlay:arcline];
}

//添加线型覆盖物
-(void)addPolylineOverlay:(NSMutableArray *)inArguments{
    //    typeOverLayerView = line;
    NSDictionary * dict = [[inArguments objectAtIndex:0] JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    if ([_overlayViewDic objectForKey:idStr]) {
        [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    NSArray * propertyArray = [dict objectForKey:@"property"];
    int caplity = (int)[propertyArray count];
    CLLocationCoordinate2D coords[999] = {0};
    for (int i = 0; i <[ propertyArray count]; i++) {
        coords[i].latitude = [[[propertyArray objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
        coords[i].longitude =  [[[propertyArray objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
    }
    BMKPolyline * polyline = [BMKPolyline polylineWithCoordinates:coords count:caplity];
    [_currentMapView addOverlay:polyline];
}

//添加圆型覆盖物
-(void)addCircleOverlay:(NSMutableArray *)inArguments{
    NSString * jsonStr = [inArguments objectAtIndex:0];
    NSDictionary *dict = [jsonStr JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    if ([_overlayViewDic objectForKey:idStr]) {
        [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    CLLocationCoordinate2D coor;
    coor.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    coor.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    float radius = [[dict objectForKey:@"radius"] floatValue];
    BMKCircle * circle = [BMKCircle circleWithCenterCoordinate:coor radius:radius];
    [_currentMapView addOverlay:circle];
}

//添加多边型覆盖物
-(void)addPolygonOverlay:(NSMutableArray *)inArguments{
    NSString * jsonStr =[inArguments objectAtIndex:0];
    NSDictionary * dict = [jsonStr JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    if ([_overlayViewDic objectForKey:idStr]) {
        [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    NSArray *propertyArray = [dict objectForKey:@"property"];
    NSLog(@"==propertyArray==%@",propertyArray);
    int caplity = (int)[propertyArray count];
    CLLocationCoordinate2D coords[100] = {0};
    for (int i = 0; i < [propertyArray count]; i  ++) {
        coords[i].latitude = [[[propertyArray objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
        coords[i].longitude = [[[propertyArray objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
    }
    BMKPolygon* polygon = [BMKPolygon polygonWithCoordinates:coords count:caplity];
    [_currentMapView addOverlay:polygon];
}

//添加addGroundOverLayer
-(void)addGroundOverlay:(NSMutableArray *)inArguments{
    NSString * jsonStr = [inArguments objectAtIndex:0];
    NSDictionary * dict = [jsonStr JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    if ([_overlayViewDic objectForKey:idStr]) {
        [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    NSArray * propertyArr = [dict objectForKey:@"property"];
    NSString * imageUrl = [dict objectForKey:@"imageUrl"];
    int type = 0;
    if ([dict objectForKey:@"type"]) {
        type = [[dict objectForKey:@"type"] intValue];
    }
    NSLog(@"==propertyDic==%@",propertyArr);
    if (type == 0) {
        NSDictionary * clLC1 = [propertyArr objectAtIndex:0];
        NSDictionary * clLC2 = [propertyArr objectAtIndex:1];
        
        CLLocationCoordinate2D LC_One = CLLocationCoordinate2DMake([[clLC1 objectForKey:@"latitude"] doubleValue], [[clLC1 objectForKey:@"longitude"] doubleValue]);
        CLLocationCoordinate2D LC_Two = CLLocationCoordinate2DMake([[clLC2 objectForKey:@"latitude"] doubleValue], [[clLC2 objectForKey:@"longitude"] doubleValue]);
        
        double latitude1 = [[clLC1 objectForKey:@"latitude"] doubleValue];
        double latitude2 = [[clLC2 objectForKey:@"latitude"] doubleValue];
        BMKCoordinateBounds bounds;
        if (latitude1 > latitude2) {
            bounds.northEast = LC_One;
            bounds.southWest = LC_Two;
        } else {
            bounds.northEast = LC_Two;
            bounds.southWest = LC_One;
        }
        
        imageUrl = [self absPath:imageUrl];
        UIImage * image = nil;
        if ([imageUrl hasPrefix:@"http"]) {
            NSURL *url = [NSURL URLWithString: imageUrl];
            image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
        } else {
            image = [UIImage imageWithContentsOfFile:imageUrl];
        }
        
        BMKGroundOverlay * groundOverlay = [BMKGroundOverlay groundOverlayWithBounds:bounds icon:image];
        [_currentMapView addOverlay:groundOverlay];
    }else if(type==1){
        //
    }
    
}
//添加文字覆盖物
- (void) addTextOverLay: (NSMutableArray *) inArguments {
    
}

//<method name="addText" />
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKArcline class]]){
//        BMKArclineView * arclineView = [[[BMKArclineView alloc] initWithOverlay:overlay] autorelease];
        BMKArclineView * arclineView = [[BMKArclineView alloc] initWithOverlay:overlay];
        NSString * colorStr=[self.overlayDataDic objectForKey:@"strokeColor"];
        arclineView.strokeColor = [MapUtility getColor:colorStr];
        arclineView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        NSString * idStr = [self.overlayDataDic objectForKey:@"id"];
        [_overlayViewDic setObject:overlay forKey:idStr];
        return arclineView;
    }
    if ([overlay isKindOfClass:[BMKCircle class]]){
//        BMKCircleView * circleView = [[[BMKCircleView alloc] initWithOverlay:overlay] autorelease];
        BMKCircleView * circleView = [[BMKCircleView alloc] initWithOverlay:overlay];
        if (self.overlayDataDic == nil) {
            return nil;
        }
        circleView.fillColor = [MapUtility getColor:[self.overlayDataDic objectForKey:@"fillColor"]] ;
        circleView.strokeColor = [MapUtility getColor:[self.overlayDataDic objectForKey:@"strokeColor"]] ;
        circleView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        NSString * idStr=[self.overlayDataDic objectForKey:@"id"];
        [_overlayViewDic setObject:overlay forKey:idStr];
        return circleView;
    }
    if ([overlay isKindOfClass:[BMKPolyline class]]){
        if (self.overlayDataDic == nil) {
            return nil;
        }
//        BMKPolylineView * polylineView = [[[BMKPolylineView alloc] initWithOverlay:overlay] autorelease];
        BMKPolylineView * polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        if ([self.overlayDataDic objectForKey:@"fillColor"]) {
            polylineView.fillColor = [MapUtility getColor:[self.overlayDataDic objectForKey:@"fillColor"]] ;
            ;
            polylineView.strokeColor =  [MapUtility getColor:[self.overlayDataDic objectForKey:@"fillColor"]] ;
        } else {
            polylineView.fillColor = [UIColor blueColor];
            ;
            polylineView.strokeColor =  [UIColor blueColor];
        }
        //[[MapUtility getColor:[self.overlayDataDic objectForKey:@"strokeColor"]] colorWithAlphaComponent:0.5];
        polylineView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        NSString * idStr = [self.overlayDataDic objectForKey:@"id"];
        if (idStr) {
            [_overlayViewDic setObject:overlay forKey:idStr];
        }
        
        return polylineView;
    }
    
    if ([overlay isKindOfClass:[BMKPolygon class]]){
//        BMKPolygonView * polygonView = [[[BMKPolygonView alloc] initWithOverlay:overlay] autorelease];
        BMKPolygonView * polygonView = [[BMKPolygonView alloc] initWithOverlay:overlay];
        if (self.overlayDataDic == nil) {
            return nil;
        }
        polygonView.fillColor = [MapUtility getColor:[self.overlayDataDic objectForKey:@"fillColor"]] ;
        ;
        polygonView.strokeColor =  [MapUtility getColor:[self.overlayDataDic objectForKey:@"strokeColor"]] ;
        polygonView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        NSString * idStr=[self.overlayDataDic objectForKey:@"id"];
        [_overlayViewDic setObject:overlay forKey:idStr];
        return polygonView;
    }
    if ([overlay isKindOfClass:[BMKGroundOverlay class]]){
//        BMKGroundOverlayView * groundView = [[[BMKGroundOverlayView alloc] initWithOverlay:overlay] autorelease];
        BMKGroundOverlayView * groundView = [[BMKGroundOverlayView alloc] initWithOverlay:overlay];
        //groundView.alpha=[[self.overlayDataDic objectForKey:@"transpancecy"] floatValue];
        NSString * idStr=[self.overlayDataDic objectForKey:@"id"];
        [_overlayViewDic setObject:overlay forKey:idStr];
        return groundView;
    }
    return nil;
}



//清除覆盖物
-(void)removeOverlay:(NSMutableArray *)inArguments{
    if (![inArguments isKindOfClass:[NSArray class]] || inArguments.count == 0) {
        if (_currentMapView) {
            NSArray * overlaysArray = [NSArray arrayWithArray:_currentMapView.overlays];
            [_currentMapView removeOverlays:overlaysArray];
            [_overlayViewDic removeAllObjects];
        }
    }
    if ([inArguments isKindOfClass:[NSArray class]] && inArguments.count > 0) {
        
        for (NSString * idStr in inArguments) {
            if ([_overlayViewDic objectForKey:idStr]) {
                [_currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
                [_overlayViewDic removeObjectForKey:idStr];
            }
            
        }
    }
}
//************************地图操作******************************
/// 地图比例尺级别，在手机上当前可使用的级别为3-19级
-(void)setZoomLevel:(NSMutableArray *)inArguments{
    NSLog(@"xrg-->uexBaiduMap-->setZoomLevel");
    float zoomLevel = [[inArguments objectAtIndex:0] floatValue];
    if (zoomLevel >=3 && zoomLevel <= 19) {
        _currentMapView.zoomLevel = zoomLevel;
    }
}
//地图旋转角度，在手机上当前可使用的范围为－180～180度
-(void)rotate:(NSMutableArray *)inArguments{
    NSLog(@"xrg-->uexBaiduMap-->rotate");
    float rotation = [[inArguments objectAtIndex:0] floatValue];
    _currentMapView.rotation = rotation;
}
//地图俯视角度，在手机上当前可使用的范围为－45～0度
-(void)overlook:(NSMutableArray *)inArguments{
    NSLog(@"xrg-->uexBaiduMap-->overlook");
    float overlooking = [[inArguments objectAtIndex:0] floatValue];
    _currentMapView.overlooking = overlooking;
}
//************************事件监听******************************

/**
 *当点击annotation view弹出的泡泡时，调用此接口
 *@param mapView 地图View
 *@param view 泡泡所属的annotation view
 */
- (void)mapView:(BMKMapView *)mapView annotationViewForBubble:(BMKAnnotationView *)view {
    for (NSString * pointId in [_pointAnnotationViewDic allKeys]) {
        BMKAnnotationView * aView = [_pointAnnotationViewDic objectForKey:pointId];
       
        if ([aView isEqual:view]) {
            NSString * inCallbackName = @"uexBaiduMap.onMakerBubbleClickListner";
            NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,pointId];
            [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
            
            //onMarkerBubbleClickListener
            NSString *cbName = @"uexBaiduMap.onMarkerBubbleClickListener";
            NSString *cbSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",cbName,cbName,pointId];
            [EUtility brwView:self.meBrwView evaluateScript:cbSuccessStr];
        }
    }
}
/**
 *地图区域改变完成后会调用此接口
 *@param mapview 地图View
 *@param animated 是否动画
 */
- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    
    if(_isFirstTime == NO) {
    NSString * inCallbackName = @"uexBaiduMap.onZoomLevelChangeListener";
    double latitude = mapView.centerCoordinate.latitude;
    double longitude = mapView.centerCoordinate.longitude;
    float zoomLevel = mapView.zoomLevel;
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%f\',\'%f\',\'%f\');}",inCallbackName,inCallbackName,zoomLevel,latitude,longitude];
        [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    }else {
        _isFirstTime = NO;
    }
}
/**
 *点中底图标注后会回调此接口
 *@param mapview 地图View
 *@param mapPoi 标注点信息
 */
- (void)mapView:(BMKMapView *)mapView onClickedMapPoi:(BMKMapPoi*)mapPoi
{
    NSLog(@"onClickedMapPoi-%@",mapPoi.text);
    //NSString* showmeg = [NSString stringWithFormat:@"您点击了底图标注:%@,\r\n当前经度:%f,当前纬度:%f,\r\nZoomLevel=%d;RotateAngle=%d;OverlookAngle=%d", mapPoi.text,mapPoi.pt.longitude,mapPoi.pt.latitude, (int)_currentMapView.zoomLevel,_currentMapView.rotation,_currentMapView.overlooking];
//    NSDictionary * showDic = [NSDictionary dictionaryWithObjectsAndKeys:mapPoi.text,@"mapPoiText",mapPoi.pt.longitude,@"longitude",mapPoi.pt.latitude,@"latitude",(int)_currentMapView.zoomLevel,@"zoomLevel",_currentMapView.rotation,@"rotation",_currentMapView.overlooking,@"overlooking", nil];
//    NSString * onClickedMapPoiStr = [showDic JSONValue];
//    NSString * inCallbackName = @"uexBaiduMap.onMakerClickListner";
//    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onClickedMapPoiStr];
//    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
//    [showDic release];
}
/**
 *点中底图空白处会回调此接口
 *@param mapview 地图View
 *@param coordinate 空白处坐标点的经纬度
 */
- (void)mapView:(BMKMapView *)mapView onClickedMapBlank:(CLLocationCoordinate2D)coordinate {
    NSString * onString = [NSString stringWithFormat:@"{\"longitude\": \"%f\",\"latitude\": \"%f\"}",coordinate.longitude,coordinate.latitude];
    NSString * inCallbackName = @"uexBaiduMap.onMapClickListener";
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onString];
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
}

/**
 *双击地图时会回调此接口
 *@param mapview 地图View
 *@param coordinate 返回双击处坐标点的经纬度
 */
- (void)mapview:(BMKMapView *)mapView onDoubleClick:(CLLocationCoordinate2D)coordinate
{
    NSString * onString = [NSString stringWithFormat:@"{\"longitude\": \"%f\",\"latitude\": \"%f\"}",coordinate.longitude,coordinate.latitude];
    NSString * inCallbackName = @"uexBaiduMap.onMapDoubleClickListener";
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onString];
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
}

/**
 *长按地图时会回调此接口
 *@param mapview 地图View
 *@param coordinate 返回长按事件坐标点的经纬度
 */
- (void)mapview:(BMKMapView *)mapView onLongClick:(CLLocationCoordinate2D)coordinate
{
    NSString * onString = [NSString stringWithFormat:@"{\"longitude\": \"%f\",\"latitude\": \"%f\"}",coordinate.longitude,coordinate.latitude];
    NSString * inCallbackName = @"uexBaiduMap.onMapLongClickListener";
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onString];
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    
}
//增加地图手势监听(返回值包括缩放等级和中心点坐标)
//onMapStatusChange


//地图区域发生变化的监听函数
//- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    NSString* showmeg = [NSString stringWithFormat:@"地图区域发生了变化(x=%d,y=%d,\r\nwidth=%d,height=%d).\r\nZoomLevel=%d;RotateAngle=%d;OverlookAngle=%d",(int)_currentMapView.visibleMapRect.origin.x,(int)_currentMapView.visibleMapRect.origin.y,(int)_currentMapView.visibleMapRect.size.width,(int)_currentMapView.visibleMapRect.size.height,(int)_currentMapView.zoomLevel,_currentMapView.rotation,_currentMapView.overlooking];
//    NSString * zoomLevel = [NSString stringWithFormat:@"%d",(int)_currentMapView.zoomLevel];
//    NSDictionary * showDic = [NSDictionary dictionaryWithObjectsAndKeys:zoomLevel,@"zoomLevel",_currentMapView.rotation,@"rotation",_currentMapView.overlooking,@"overlooking",(int)_currentMapView.visibleMapRect.origin.x,@"x",(int)_currentMapView.visibleMapRect.origin.y,@"y",(int)_currentMapView.visibleMapRect.size.width,@"width",(int)_currentMapView.visibleMapRect.size.height,@"height", nil];
//    NSString * onRegionDidChange = [showDic JSONValue];
//    NSString * inCallbackName = @"uexBaiduMap.onRegionDidChange";
//    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onRegionDidChange];
//    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
//    [showDic release];
//}
//************************UI控制******************************
///设定地图View能否支持用户多点缩放(双指)
-(void)setZoomEnable:(NSMutableArray *)inArguments{
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    BOOL enable = [inArguments[0] boolValue];
    [_currentMapView setZoomEnabled:enable];
}

///设定地图View能否支持用户缩放(双击或双指单击)
-(void)setZoomEnabledWithTap:(NSMutableArray *)inArguments{
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    BOOL enable = [inArguments[0] boolValue];
    [_currentMapView setZoomEnabledWithTap:enable];

}

///设定地图View能否支持用户移动地图
-(void)setScrollEnable:(NSMutableArray *)inArguments{
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    BOOL enable = [inArguments[0] boolValue];
    
    [_currentMapView setScrollEnabled:enable];
    
}
///设定地图View能否支持俯仰角
-(void)setOverlookEnable:(NSMutableArray *)inArguments{
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    BOOL enable = [inArguments[0] boolValue];
    [_currentMapView setOverlookEnabled:enable];

}
///设定地图View能否支持旋转
-(void)setRotateEnable:(NSMutableArray *)inArguments{
    
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    BOOL enable = [inArguments[0] boolValue];
    [_currentMapView setRotateEnabled:enable];
    

}
//放大地图
-(void)zoomIn:(NSMutableArray *)inArguments{
    NSLog(@"xrg-->uexBaiduMap-->zoomIn");
    if (_currentMapView) {
        [_currentMapView zoomIn];
    }
}

//缩小地图
-(void)zoomOut:(NSMutableArray *)inArguments{
    NSLog(@"xrg-->uexBaiduMap-->zoomOut");
    if (_currentMapView) {
        [_currentMapView zoomOut];
    }
}

-(void)zoomToSpan:(NSMutableArray *)inArguments{
    NSLog(@"xrg-->uexBaiduMap-->zoomToSpan");
    NSString * longitudeSpan = [inArguments objectAtIndex:0];
    NSString * latitudeSpan = [inArguments objectAtIndex:1];
    BMKCoordinateRegion region;
    region.center = _currentMapView.centerCoordinate;
    region.span.longitudeDelta = [longitudeSpan doubleValue];
    region.span.latitudeDelta = [latitudeSpan doubleValue];
    [_currentMapView setRegion:region animated:YES];
}

//将地图缩放到指定的矩形区域
-(void)zoomToBounds:(NSMutableArray *)inArguments{
    //
}
-(void)setCompassEnable:(NSMutableArray *)inArguments{
    
    BOOL isOpen = [[inArguments objectAtIndex:0] boolValue];
    
    if (isOpen) {
        
        [_currentMapView setCompassPosition:self.positionOfCompass];
        
    } else {
        
        self.positionOfCompass = _currentMapView.compassPosition;
        _currentMapView.compassPosition = CGPointMake(-50, -50);
        
    }
    
}


/// 指南针的位置，设定坐标以BMKMapView左上角为原点，向右向下增长
-(void)setCompassPosition:(NSMutableArray *) inArguments{
    
    float x = [[inArguments objectAtIndex:0] floatValue];
    float y = [[inArguments objectAtIndex:1] floatValue];
    [_currentMapView setCompassPosition:CGPointMake(x, y)];
}
/// 设定是否显式比例尺
-(void)showMapScaleBar:(NSMutableArray *)inArguments{
    
    if (!inArguments || inArguments.count == 0) {
        return;
    }
    BOOL enable = [inArguments[0] boolValue];
    [_currentMapView setShowMapScaleBar:enable];
}
-(void)setMapScaleBarPosition:(NSMutableArray *)inArguments{
    float x = [[inArguments objectAtIndex:0] floatValue];
    float y = [[inArguments objectAtIndex:1] floatValue];
    [_currentMapView setMapScaleBarPosition:CGPointMake(x, y)];
}
//************POI**************************

//setPoiPageCapacity设置搜索POI单页数据量
-(void)setPoiPageCapacity:(NSMutableArray *)inArguments{
    int pageCapacity = [[inArguments objectAtIndex:0] intValue];
    self.pageCapacity = pageCapacity;
}

-(void)getPoiPageCapacity:(NSMutableArray *)inArguments{
    [self jsSuccessWithName:@"uexBaiduMap.cbGetPoiPageCapacity" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:_pageCapacity];
}

//poiSearchInCity 城市范围内搜索
-(void)poiSearchInCity:(NSMutableArray *)inArguments{
    //city, key, pageIndex
    if ([inArguments count] < 1) {
        return;
    }
    
    NSString * json = [inArguments objectAtIndex:0];
    NSDictionary * jsDic = [json JSONValue];
    
    
    NSString * city = [jsDic objectForKey:@"city"];
    NSString * keyword = [jsDic objectForKey:@"searchKey"];
    int pageIndex = [[jsDic objectForKey:@"pageNum"] intValue];
    
    if (!_POISearch) {
        self.POISearch = [[BMKPoiSearch alloc]init];
        _POISearch.delegate = self;
    }
    
    BMKCitySearchOption * option = [[BMKCitySearchOption alloc]init];
    option.city = city;
    option.keyword = keyword;
    option.pageCapacity = _pageCapacity;
    option.pageIndex = pageIndex;
    
    BOOL flag = [_POISearch poiSearchInCity:option];
//    [option release];
    if(flag){
        NSLog(@"城市范围内搜索发送成功");
    }else{
        NSLog(@"城市范围内搜索发送失败");
    }
}
//poiSearchNearBy 周边搜索
-(void)poiNearbySearch:(NSMutableArray *)inArguments{
    //key, longitude, latitude,radius, pageIndex
    NSString * jsStr = [inArguments objectAtIndex:0];
    NSDictionary * jsDic = [jsStr JSONValue];
    
    NSString * keyword = [jsDic objectForKey:@"searchKey"];
    double longitude = [[jsDic objectForKey:@"longitude"] doubleValue];
    double latitude = [[jsDic objectForKey:@"latitude"] doubleValue];
    int radius = [[jsDic objectForKey:@"radius"] intValue];
    int pageIndex = [[jsDic objectForKey:@"pageNum"] intValue];
    if (!_POISearch) {
        self.POISearch = [[BMKPoiSearch alloc]init];
        _POISearch.delegate=self;
    }
    //发起检索
    BMKNearbySearchOption * option = [[BMKNearbySearchOption alloc]init];
    option.pageIndex = pageIndex;
    option.pageCapacity = _pageCapacity;
    option.location = CLLocationCoordinate2DMake(latitude, longitude);
    option.keyword = keyword;
    option.radius = radius;
    BOOL flag = [_POISearch poiSearchNearBy:option];
//    [option release];
    if (flag) {
        NSLog(@"周边检索发送成功");
    } else {
        NSLog(@"周边检索发送失败");
    }
}

//poiSearchInBounds 区域内搜索
-(void)poiBoundSearch:(NSMutableArray *)inArguments{
    //key， lbLongitude， lbLatitude， rtLongitude， rtLatitude， pageIndex
    
    NSString * json = [inArguments objectAtIndex:0];
    NSDictionary * jsDic = [json JSONValue];
    
    
    
    NSString * keyword = [jsDic objectForKey:@"searchKey"];
    int pageIndex = [[jsDic objectForKey:@"pageNum"] intValue];
    
    double lbLongitude = [[[jsDic objectForKey:@"southwest"] objectForKey:@"longitude"] doubleValue];
    double lbLatitude = [[[jsDic objectForKey:@"southwest"] objectForKey:@"latitude"] doubleValue];
    double rtLongitude = [[[jsDic objectForKey:@"northeast"] objectForKey:@"longitude"] doubleValue];
    double rtLatitude = [[[jsDic objectForKey:@"northeast"] objectForKey:@"latitude"] doubleValue];
    
    if (!_POISearch) {
        self.POISearch = [[BMKPoiSearch alloc]init];
        _POISearch.delegate = self;
    }
    
    //发起检索
    BMKBoundSearchOption * option = [[BMKBoundSearchOption alloc]init];
    option.leftBottom = CLLocationCoordinate2DMake(lbLatitude, lbLongitude);
    option.rightTop = CLLocationCoordinate2DMake(rtLatitude, rtLongitude);
    option.pageIndex = pageIndex;
    option.pageCapacity = _pageCapacity;
    option.keyword = keyword;
    
    BOOL flag = [_POISearch poiSearchInbounds:option];
//    [option release];
    if(flag) {
        NSLog(@"区域内搜索发送成功");
    } else {
        NSLog(@"区域内搜索发送失败");
    }
}

//实现PoiSearchDeleage处理回调结果


- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode;
{
    if (errorCode == BMK_SEARCH_NO_ERROR) {
        

        NSMutableDictionary * resultDic = [NSMutableDictionary dictionary];
        NSString * totalPoiNum = [NSString stringWithFormat:@"%d",poiResult.totalPoiNum];
        NSString * totalPageNum = [NSString stringWithFormat:@"%d",poiResult.pageNum];
        NSString * currentPageNum = [NSString stringWithFormat:@"%d",poiResult.currPoiNum];
        NSString * currentPageCapacity = [NSString stringWithFormat:@"%d",poiResult.pageIndex];
        NSMutableArray * poiInfoList = [NSMutableArray array];


        for (BMKPoiInfo * poiInfo in poiResult.poiInfoList) {
            NSString * epoitype = [NSString stringWithFormat:@"%d",poiInfo.epoitype];
            NSString * latitude = [NSString stringWithFormat:@"%f",poiInfo.pt.latitude];
            NSString * longitude = [NSString stringWithFormat:@"%f",poiInfo.pt.longitude];
            NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
            [tempDict setValue:poiInfo.uid forKey:@"uid"];
            [tempDict setValue:epoitype forKey:@"poiType"];
            [tempDict setValue:poiInfo.phone forKey:@"phoneNum"];
            [tempDict setValue:poiInfo.address forKey:@"address"];
            [tempDict setValue:poiInfo.name forKey:@"name"];
            [tempDict setValue:longitude forKey:@"longitude"];
            [tempDict setValue:latitude forKey:@"latitude"];
            [tempDict setValue:poiInfo.city forKey:@"city"];
            [tempDict setValue:poiInfo.postcode forKey:@"postCode"];
            
            [poiInfoList addObject:tempDict];

        }

        [resultDic setObject:totalPoiNum forKey:@"totalPoiNum"];
        [resultDic setObject:totalPageNum forKey:@"totalPageNum"];
        [resultDic setObject:currentPageNum forKey:@"currentPageNum"];
        [resultDic setObject:currentPageCapacity forKey:@"currentPageCapacity"];
        [resultDic setObject:poiInfoList forKey:@"poiInfo"];

        NSString * cbStr = [resultDic JSONFragment];


        NSString * inCallbackName = @"uexBaiduMap.cbPoiSearchResult";
        NSString * jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,cbStr];
        
        [self performSelector:@selector(delayCallBack:) withObject:jsSuccessStr afterDelay:1.0];
        
    } else if (errorCode == BMK_SEARCH_AMBIGUOUS_KEYWORD){
        NSLog(@"起始点有歧义");
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}

-(void)delayCallBack:(NSString *)cbStr {
    [EUtility brwView:self.meBrwView evaluateScript:cbStr];
}

//*****************线路规划**********************************
//busLineSearch公交线路搜索
-(void)busLineSearch:(NSMutableArray *)inArguments{
    if (![inArguments isKindOfClass:[NSMutableArray class]] || [inArguments count] < 1) {
        return;
    }
    
    BusLineObjct * tempBusLineObj = [_routePlanDic objectForKey:@"busLineObj"];
    if (tempBusLineObj) {
        [tempBusLineObj remove];
    }
    
    
    NSString * json = [inArguments objectAtIndex:0];
    NSDictionary * jsDic = [json JSONValue];
    
    [self.overlayDataDic setObject:@"busline" forKey:@"id"];
    NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];//[MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
    [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
    NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
    [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
    [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];
    
    BusLineObjct * busLineObj = [[BusLineObjct alloc]initWithuexObj:self andMapView:_currentMapView andJson:jsDic];
    [busLineObj doSearch];
    
    [_routePlanDic setObject:busLineObj forKey:@"busLineObj"];
    
    


}

-(void)removeBusLine:(NSMutableArray *)inArguments {
    BusLineObjct * busLineObj = [_routePlanDic objectForKey:@"busLineObj"];
    if (busLineObj) {
        [busLineObj remove];
    }
}




-(void)removeRoutePlan:(NSMutableArray *)inArguments {
    if ([inArguments count] < 1) {
        return;
    }
    
    
    
    NSString * idStr = [inArguments objectAtIndex:0];
    SearchPlanObject * spObj = [_routePlanDic objectForKey:idStr];
    if (spObj) {
        [spObj remove];
    }
}


-(void)searchRoutePlan:(NSMutableArray *)inArguments {
    NSString * jsString = [inArguments objectAtIndex:0];
    NSDictionary * dict = [jsString JSONValue];
    
    NSString * idStr = [dict objectForKey:@"id"];
    SearchPlanObject * spObjTemp = [_routePlanDic objectForKey:idStr];
    if (spObjTemp) {
        [spObjTemp remove];
    }
    
    [self.overlayDataDic setObject:@"Walking" forKey:@"id"];
    NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];//[MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
    [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
    NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
    [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
    [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];

    
    
    
    SearchPlanObject * spObj = [[SearchPlanObject alloc]initWithuexObj:self andMapView:_currentMapView andJson:dict];
    [spObj doSearch];
    
    
    [_routePlanDic setObject:spObj forKey:idStr];
    
    
}


//*****************地里编码**********************************
-(void)geocode:(NSMutableArray *)inArguments{
    if ([inArguments count] < 1) {
        return;
    }
    
    NSString * jsStr = [inArguments objectAtIndex:0];
    NSDictionary * jsDic = [jsStr JSONValue];
    
    NSString * city = [jsDic objectForKey:@"city"];
    NSString * address = [jsDic objectForKey:@"address"];
    
    if (!_geoCodeSearch) {
        self.geoCodeSearch = [[BMKGeoCodeSearch alloc]init];
        _geoCodeSearch.delegate = self;
    }
    BMKGeoCodeSearchOption * geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
    geoCodeSearchOption.city = city;
    geoCodeSearchOption.address = address;
    BOOL flag = [_geoCodeSearch geoCode:geoCodeSearchOption];
//    [geoCodeSearchOption release];
    if(flag) {
        //
    } else {
        [self onCallBack:@"uexBaiduMap.cbGeoCodeResult" andData:@"1"];
    }
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        CLLocationCoordinate2D clLC2D = result.location;
        NSString * jsStr = [NSString stringWithFormat:@"{\"longitude\":\" %f\",\"latitude\":\"%f\"}",clLC2D.longitude,clLC2D.latitude];
        [self performSelector:@selector(cbGeoCodeResult:) withObject:jsStr afterDelay:1.0];
        
        
    } else {
//        BMK_SEARCH_NO_ERROR =0,///<检索结果正常返回
//        BMK_SEARCH_AMBIGUOUS_KEYWORD,///<检索词有岐义
//        BMK_SEARCH_AMBIGUOUS_ROURE_ADDR,///<检索地址有岐义
//        BMK_SEARCH_NOT_SUPPORT_BUS,///<该城市不支持公交搜索
//        BMK_SEARCH_NOT_SUPPORT_BUS_2CITY,///<不支持跨城市公交
//        BMK_SEARCH_RESULT_NOT_FOUND,///<没有找到检索结果
        //        BMK_SEARCH_ST_EN_TOO_NEAR,///<起终点太近
        NSString * cbStr = [NSString stringWithFormat:@"%d",error];
        [self performSelector:@selector(cbGeoCodeResult:) withObject:cbStr afterDelay:1.0];
    }
}

-(void)cbGeoCodeResult:(NSString *)cbStr {
    [self onCallBack:@"uexBaiduMap.cbGeoCodeResult" andData:cbStr];
}



-(void)onCallBack:(NSString *)method andData:(NSString *)data{
    
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",method,method,data];
    
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    
}

-(void)reverseGeocode: (NSMutableArray *) inArguments {
    
    if ([inArguments count] < 1) {
        return;
    }
    
    NSString * jsStr = [inArguments objectAtIndex:0];
    NSDictionary * jsDic = [jsStr JSONValue];

    
    double longitude = [[jsDic objectForKey:@"longitude"] doubleValue];
    double latitude = [[jsDic objectForKey:@"latitude"] doubleValue];
    CLLocationCoordinate2D pt = (CLLocationCoordinate2D){0, 0};
    pt.longitude = longitude;
    pt.latitude = latitude;
    //    geoOrReverse=1;
    //发起反向地理编码检索
    if (!_geoCodeSearch) {
        self.geoCodeSearch = [[BMKGeoCodeSearch alloc]init];
        _geoCodeSearch.delegate = self;
    }
    BMKReverseGeoCodeOption * reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeoCodeSearchOption.reverseGeoPoint = pt;
    BOOL flag = [_geoCodeSearch reverseGeoCode:reverseGeoCodeSearchOption];
//    [reverseGeoCodeSearchOption release];
    if(flag) {
        NSLog(@"反geo检索发送成功");
    } else {
        NSLog(@"反geo检索发送失败");
        [self onCallBack:@"uexBaiduMap.cbReverseGeoCodeResult" andData:@"1"];
    }
}

//接收反向地理编码结果
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        NSString * address = result.address;
//        BMKAddressComponent * addressDetail = result.addressDetail;
//        NSString * streetNumber = addressDetail.streetNumber;
//        NSString * streetName = addressDetail.streetName;
//        NSString * district = addressDetail.district;
//        NSString * city = addressDetail.city;
//        NSString * province = addressDetail.province;
//        NSString * address = result.address;
//        CLLocationCoordinate2D location = result.location;
        NSString * jsStr= [NSString stringWithFormat:@"{\"address\":\"%@\"}",address];
        [self performSelector:@selector(cbReverseGeoCodeResult:) withObject:jsStr afterDelay:1.0];
    } else {
//        BMK_SEARCH_NO_ERROR =0,///<检索结果正常返回
//        BMK_SEARCH_AMBIGUOUS_KEYWORD,///<检索词有岐义
//        BMK_SEARCH_AMBIGUOUS_ROURE_ADDR,///<检索地址有岐义
//        BMK_SEARCH_NOT_SUPPORT_BUS,///<该城市不支持公交搜索
//        BMK_SEARCH_NOT_SUPPORT_BUS_2CITY,///<不支持跨城市公交
//        BMK_SEARCH_RESULT_NOT_FOUND,///<没有找到检索结果
//        BMK_SEARCH_ST_EN_TOO_NEAR,///<起终点太近
        NSString * cbStr = [NSString stringWithFormat:@"%d",error];
        [self performSelector:@selector(cbReverseGeoCodeResult:) withObject:cbStr afterDelay:1.0];
    }
}

-(void)cbReverseGeoCodeResult:(NSString *)cbStr {
    [self onCallBack:@"uexBaiduMap.cbReverseGeoCodeResult" andData:cbStr];
}

//******************计算工具*****************************

//计算两点之间距离
-(void)getDistance:(NSMutableArray*)inArguments{
    double lat1 = [[inArguments objectAtIndex:0] doubleValue];
    double lon1 = [[inArguments objectAtIndex:1] doubleValue];
    double lat2 = [[inArguments objectAtIndex:2] doubleValue];
    double lon2 = [[inArguments objectAtIndex:3] doubleValue];
    BMKMapPoint point1 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(lat1,lon1));
    BMKMapPoint point2 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(lat2,lon2));
    CLLocationDistance distance = BMKMetersBetweenMapPoints(point1,point2);
    NSString * distanceStr = [NSString stringWithFormat:@"%f",distance];
    [self jsSuccessWithName:@"uexBaiduMap.cbGetDistance" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:distanceStr];
}
//转换GPS坐标至百度坐标
- (void)getBaiduFromGPS:(NSMutableArray *)inArguments
{
    CLLocationCoordinate2D locationCoord;
    if ([inArguments count] == 2) {
        locationCoord.longitude = [[inArguments objectAtIndex:0] doubleValue];
        locationCoord.latitude = [[inArguments objectAtIndex:1] doubleValue];
    }
    NSLog(@"GPS坐标是:%f,%f",locationCoord.latitude,locationCoord.longitude);
    //BMK_COORDTYPE_GPS----->///GPS设备采集的原始GPS坐标
    NSDictionary * baidudict = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(locationCoord.latitude, locationCoord.longitude),BMK_COORDTYPE_GPS);
    CLLocationCoordinate2D lC2D = BMKCoorDictionaryDecode(baidudict);
    NSLog(@"百度坐标是:%f,%f",lC2D.latitude,lC2D.longitude);
    NSString * jsStr = [NSString stringWithFormat:@"if(uexBaiduMap.cbBaiduFromGPS!=null){uexBaiduMap.cbBaiduFromGoogle('%f','%f');}",lC2D.latitude,lC2D.longitude];
    [EUtility brwView:meBrwView evaluateScript:jsStr];
}

//转换 google地图、soso地图、aliyun地图、mapabc地图和amap地图所用坐标至百度坐标
- (void)getBaiduFromGoogle:(NSMutableArray *)inArguments
{
    CLLocationCoordinate2D locationCoord;
    if ([inArguments count]== 2) {
        locationCoord.longitude = [[inArguments objectAtIndex:0] doubleValue];
        locationCoord.latitude = [[inArguments objectAtIndex:1] doubleValue];
    }
    NSLog(@"google坐标是:%f,%f",locationCoord.latitude,locationCoord.longitude);
    NSDictionary * baidudict = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(locationCoord.latitude, locationCoord.longitude),BMK_COORDTYPE_COMMON);
    CLLocationCoordinate2D lC2D = BMKCoorDictionaryDecode(baidudict);
    NSLog(@"百度坐标是:%f,%f",lC2D.latitude,lC2D.longitude);
    NSString *jsstr = [NSString stringWithFormat:@"if(uexBaiduMap.cbBaiduFromGoogle!=null){uexBaiduMap.cbBaiduFromGoogle('%f','%f');}",lC2D.latitude,lC2D.longitude];
    [EUtility brwView:meBrwView evaluateScript:jsstr];
}
//******************定位*****************************
-(void)getCurrentLocation:(NSMutableArray *)inArguments{
    
    if (!self.locationService) {
        self.locationService = [[BMKLocationService alloc]init];
    }
    if (!_didStartLocatingUser) {
        self.locationService.delegate = self;
        [self.locationService startUserLocationService];
        _isUpdateLocationOnce = YES;
    } else {
        double longit = _locationService.userLocation.location.coordinate.longitude;
        double lat = _locationService.userLocation.location.coordinate.latitude;
        NSDate * timestamp = _locationService.userLocation.location.timestamp;
        NSString * timeStr = [NSString stringWithFormat:@"%.0f", [timestamp timeIntervalSince1970]];
        NSString * onReceiveLocation = [NSString stringWithFormat:@"{\"longitude\":\"%f\",\"latitude\":\"%f\",\"timeStamp\":\"%@\"}",longit,lat,timeStr];
        NSString *jsstr = [NSString stringWithFormat:@"if(uexBaiduMap.cbCurrentLocation!=null){uexBaiduMap.cbCurrentLocation('%@');}",onReceiveLocation];
        [EUtility brwView:meBrwView evaluateScript:jsstr];
    }
    
}

- (void)startLocation:(NSMutableArray *)inArguments {
    if (!self.locationService) {
        self.locationService = [[BMKLocationService alloc]init];
    }
    if (!_didStartLocatingUser) {
        self.locationService.delegate = self;
        [self.locationService startUserLocationService];
    }
    
}

- (void)stopLocation:(NSMutableArray *)inArguments {
    _currentMapView.showsUserLocation = NO;
    if (self.locationService) {
        self.locationService.delegate = nil;
        [self.locationService stopUserLocationService];
    }
}

//显示当前位置
-(void)setMyLocationEnable:(NSMutableArray *)inArguments{
    BOOL isShow = NO;
    if ([inArguments count] > 0) {
        isShow = [[inArguments objectAtIndex:0] boolValue];
    }
    
    if (!_didStartLocatingUser) {
        if (!self.locationService) {
            self.locationService = [[BMKLocationService alloc]init];
        }
        self.locationService.delegate = self;
        [self.locationService startUserLocationService];
    }
    if (isShow) {
        _currentMapView.showsUserLocation = YES;//显示定位图层
    } else {
        _currentMapView.showsUserLocation = NO;//显示定位图层
    }
    
}



/**
 *在将要启动定位时，会调用此函数
 */
- (void)willStartLocatingUser{
    _didStartLocatingUser = YES;
    [self jsSuccessWithName:@"uexBaiduMap.cbStartLocation" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
}

/**
 *在停止定位后，会调用此函数
 */
- (void)didStopLocatingUser{
    _didStartLocatingUser = NO;
    [self jsSuccessWithName:@"uexBaiduMap.cbStopLocation" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
}

//处理方向变更信息
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    [_currentMapView updateLocationData:userLocation];
}
/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    double longit = _locationService.userLocation.location.coordinate.longitude;
    double lat = _locationService.userLocation.location.coordinate.latitude;
    NSDate * timestamp = _locationService.userLocation.location.timestamp;
    NSString * timeStr = [NSString stringWithFormat:@"%.0f", [timestamp timeIntervalSince1970]];
    NSString * onReceiveLocation = [NSString stringWithFormat:@"{\"longitude\":\"%f\",\"latitude\":\"%f\",\"timeStamp\":\"%@\"}",longit,lat,timeStr];
    
    if (_isUpdateLocationOnce) {
        _isUpdateLocationOnce = NO;
        
        NSString *jsstr = [NSString stringWithFormat:@"if(uexBaiduMap.cbCurrentLocation!=null){uexBaiduMap.cbCurrentLocation('%@');}",onReceiveLocation];
        [EUtility brwView:meBrwView evaluateScript:jsstr];
        
        
        [self.locationService stopUserLocationService];
        return;
    }
    NSString *jsstr = [NSString stringWithFormat:@"if(uexBaiduMap.onReceiveLocation!=null){uexBaiduMap.onReceiveLocation('%@');}",onReceiveLocation];
    [EUtility brwView:meBrwView evaluateScript:jsstr];
    
    [_currentMapView updateLocationData:userLocation];
}
//处理位置坐标更新
//- (void)didUpdateUserLocation:(BMKUserLocation *)userLocation {
//    double longit = _locationService.userLocation.location.coordinate.longitude;
//    double lat = _locationService.userLocation.location.coordinate.latitude;
//    NSDate * timestamp = _locationService.userLocation.location.timestamp;
//    NSString * timeStr = [NSString stringWithFormat:@"%.0f", [timestamp timeIntervalSince1970]];
//    NSString * onReceiveLocation = [NSString stringWithFormat:@"{\"longitude\":\"%f\",\"latitude\":\"%f\",\"timeStamp\":\"%@\"}",longit,lat,timeStr];
//    
//    if (_isUpdateLocationOnce) {
//        _isUpdateLocationOnce = NO;
//        
//        NSString *jsstr = [NSString stringWithFormat:@"if(uexBaiduMap.cbCurrentLocation!=null){uexBaiduMap.cbCurrentLocation('%@');}",onReceiveLocation];
//        [EUtility brwView:meBrwView evaluateScript:jsstr];
//        
//        
//        [self.locationService stopUserLocationService];
//        return;
//    }
//    NSString *jsstr = [NSString stringWithFormat:@"if(uexBaiduMap.onReceiveLocation!=null){uexBaiduMap.onReceiveLocation('%@');}",onReceiveLocation];
//    [EUtility brwView:meBrwView evaluateScript:jsstr];
//    
//    [_currentMapView updateLocationData:userLocation];
//}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error{
    NSLog(@"xrg-->uexBaiduMap-->didFailToLocateUserWithError");
}

- (void)setUserTrackingMode:(NSMutableArray *)inArguments {
//    BMKUserTrackingModeNone = 0,             /// 普通定位模式
//    BMKUserTrackingModeFollow,               /// 定位跟随模式
//    BMKUserTrackingModeFollowWithHeading,    /// 定位罗盘模式
    int mode = 0;//
    if ([inArguments count] >= 1) {
        mode = [[inArguments objectAtIndex:0] intValue];
    }
    _currentMapView.showsUserLocation = NO;
    switch (mode) {
        case BMKUserTrackingModeFollow:
            _currentMapView.userTrackingMode = BMKUserTrackingModeFollow;
            break;
        case BMKUserTrackingModeFollowWithHeading:
            _currentMapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading;
            break;
        default:
            _currentMapView.userTrackingMode = BMKUserTrackingModeNone;
            break;
    }
    _currentMapView.showsUserLocation = YES;
}


@end
