//
//  EUExBaiduMap.m
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/3.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "EUExBaiduMap.h"
#import <BaiduMapAPI_Map/BMKMapView.h>

#import "MapUtility.h"
#import "ACPointAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import "BaiduMapManager.h"
#import "CustomPaoPaoView.h"
#import "BusLineAnnotation.h"
#import "RouteAnnotation.h"
#import "SearchPlanObject.h"
#import "BusLineObjct.h"
#import "uexBaiduPOISearcher.h"
#import "uexBaiduGeoCodeSearcher.h"
#import "uexBaiduReverseGeocodeSearcher.h"
#import <AppCanKit/ACEXTScope.h>

@interface EUExBaiduMap()<BMKGeneralDelegate,BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,BMKSuggestionSearchDelegate,BMKBusLineSearchDelegate,BMKRouteSearchDelegate>

@property (nonatomic, strong) NSMutableDictionary * overlayDataDic;
@property (nonatomic, strong) NSMutableDictionary * overlayViewDic;
@property (nonatomic, strong) NSMutableDictionary * pointAnnotationDic;
@property (nonatomic, strong) NSMutableDictionary * pointAnnotationViewDic;
@property (nonatomic, strong) NSMutableDictionary * routePlanDic;

@property (nonatomic, strong) NSMutableArray * busPoiArray;

@property (nonatomic, strong) BMKMapManager * mapManager;
@property (nonatomic, strong) BMKMapView * currentMapView;

@property (nonatomic, strong) BMKLocationService * locationService;
/*
@property (nonatomic, strong) BMKGeoCodeSearch * geoCodeSearch;
@property (nonatomic, strong) BMKSuggestionSearch * suggestionSearch;
@property (nonatomic, strong) BMKBusLineSearch * busLineSearch;
@property (nonatomic, strong) BMKRouteSearch * routeSearch;
*/
@property (nonatomic, assign) int pageCapacity;
@property (nonatomic, assign) int currentIndex;
@property (nonatomic, assign) BOOL isUpdateLocationOnce;
@property (nonatomic, assign) BOOL didStartLocatingUser;
@property (nonatomic, assign) BOOL showCallOut;
@property (nonatomic, assign) BOOL didBusLineSearch;
@property (nonatomic, assign) BOOL isFirstTime;

@property (nonatomic, assign) CGPoint positionOfCompass;

@property (nonatomic, strong) NSString * searchCity;

@property (nonatomic,strong) NSMutableDictionary<NSString *,ACJSFunctionRef *> *tmpFuncDict;
@property (nonatomic,strong) NSMutableArray<id<uexBaiduMapSearcher>> *searchers;


@end


#define UEX_FALSE @(NO)
#define UEX_TRUE @(YES)

@implementation EUExBaiduMap

#pragma mark - Life Cycle


- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine
{
    self = [super initWithWebViewEngine:engine];
    if (self) {
        _didStartLocatingUser = NO;
        _isUpdateLocationOnce = NO;
        _didBusLineSearch = NO;
        _pageCapacity = 10;
        
        _overlayDataDic = [NSMutableDictionary dictionary];
        _overlayViewDic = [NSMutableDictionary dictionary];
        _pointAnnotationDic = [NSMutableDictionary dictionary];
        _routePlanDic = [NSMutableDictionary dictionary];
        _pointAnnotationViewDic = [NSMutableDictionary dictionary];
       
        _positionOfCompass = CGPointMake(10, 10);
        _showCallOut = NO;
        _tmpFuncDict = [NSMutableDictionary dictionary];
        _searchers = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc{
    [self clean];
}

- (void)clean{
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

    if (_currentMapView) {
        [_currentMapView setDelegate:nil];
        [_currentMapView viewWillDisappear];
        [_currentMapView removeFromSuperview];
    }
}


#pragma mark - Tools
-(NSString *)randomString{
    return [NSString stringWithFormat:@"%d",arc4random()%10000];
}


#pragma mark - Tools

- (void)intResultCallbackWithKeyPath:(NSString *)keyPath isSuccess:(BOOL)isSuccess{
    [self.webViewEngine callbackWithFunctionKeyPath:keyPath arguments:ACArgsPack(@0,@2,isSuccess ? @0 : @1)];
}


#pragma mark - BMKGeneralDelegate

- (void)onGetNetworkState:(int)iError{
    
    if (iError == 0) {
        return;
    }
    NSDictionary *result = @{@"errorInfo":@(iError)};
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onSDKReceiverError" arguments:ACArgsPack(result.ac_JSONFragment)];
}

- (void)onGetPermissionState:(int)iError{
    if (iError == E_PERMISSIONCHECK_OK) {
        [self intResultCallbackWithKeyPath:@"uexBaiduMap.cbStart" isSuccess:YES];
        return;
    }
    NSDictionary *result = @{@"errorInfo":@(iError)};
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onSDKReceiverError" arguments:ACArgsPack(result.ac_JSONFragment)];
}

#pragma mark - BMKMapViewDelegate

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView
{
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbOpen" arguments:nil];
    [self.tmpFuncDict[@"cbOpen"] executeWithArguments:nil completionHandler:^(JSValue * _Nullable returnValue) {
        [self.tmpFuncDict setValue:nil forKey:@"cbOpen"];
    }];
    
}
//******************************基本功能************************************




//打开地图
-(void)open:(NSMutableArray *)inArguments{

    if (self.currentMapView) {
        return;
    }

    NSString * baiduMapKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"uexBaiduMapKey"];
    self.mapManager = [BaiduMapManager defaultManager];

    if(![self.mapManager start:baiduMapKey generalDelegate:self]) {
        return;
    }
    
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum,NSNumber * wNum,NSNumber *hNum,NSNumber *lonNum,NSNumber *latNum,ACJSFunctionRef *cbOpen) = inArguments;
    //打开地图 设置中心点
    float x = [xNum floatValue];
    float y = [yNum floatValue];
    float w = [wNum floatValue];
    float h  = [hNum floatValue];
    
    _isFirstTime = YES;
    self.currentMapView = [[BMKMapView alloc]initWithFrame:CGRectMake(x, y, w, h)];
    [self.currentMapView setDelegate:self];
    [self.currentMapView viewWillAppear];
    [[self.webViewEngine webView] addSubview:self.currentMapView];
    
    if (lonNum && latNum) {
        double  longitude = [lonNum doubleValue];
        double  latitude =  [latNum doubleValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latitude,longitude);
        [self.currentMapView setCenterCoordinate:center animated:NO];
    }
    [self.tmpFuncDict setValue:cbOpen forKey:@"cbOpen"];
}

//***************隐藏和显示百度地图************
-(void)hideMap:(NSMutableArray *)inArguments{
    [self.currentMapView setHidden:YES];
}

-(void)showMap:(NSMutableArray *)inArguments{
    [self.currentMapView setHidden:NO];
}




//关闭地图
-(void)close:(NSMutableArray *)inArguments{
    if(!self.currentMapView){
        return;
    }
    [self.currentMapView setDelegate:nil];
    [self.currentMapView viewWillDisappear];
    [self.currentMapView removeFromSuperview];
    self.currentMapView = nil;

    
}

//设置地图的类型
//BMKMapTypeStandard   = 1,               ///< 标准地图
//BMKMapTypeSatellite  = 4,               ///< 卫星地图
-(void)setMapType:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *typeNum) = inArguments;
    
    NSInteger mapType = [typeNum integerValue];
    switch (mapType) {
        case 1:
            self.currentMapView.mapType = BMKMapTypeStandard;
            break;
        case 2:
            self.currentMapView.mapType = BMKMapTypeSatellite;
            break;
        default:
            break;
    }
}
//设置是否开启实时交通
-(void)setTrafficEnabled:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *num) = inArguments;
    [self.currentMapView setTrafficEnabled:num.boolValue];
}
/**
 *设定地图中心点坐标
 *@param coordinate 要设定的地图中心点坐标，用经纬度表示
 *@param animated 是否采用动画效果
 */
-(void)setCenter:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *lonNum,NSNumber *latNum,NSNumber *aniNum) = inArguments;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latNum.doubleValue, lonNum.doubleValue);
    BOOL animated = aniNum.boolValue;
    [self.currentMapView setCenterCoordinate:center animated:animated];
}

//************************覆盖物功能******************************

-(NSArray *)addMarkersOverlay:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSArray *markArr) = inArguments;
    if (!markArr) {
        return nil;
    }
    
    NSMutableArray *ids=[NSMutableArray array];
    for(id markDic in markArr){
        if (![markDic isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString * idStr = [markDic objectForKey:@"id"]?:[self randomString];
        [ids addObject:idStr];
        double lon = [[markDic objectForKey:@"longitude"] doubleValue];
        double lat = [[markDic objectForKey:@"latitude"] doubleValue];
        NSString * iconPath = [markDic objectForKey:@"icon"];
        NSDictionary *dic = [markDic objectForKey:@"bubble"];
        NSString *title = [dic objectForKey:@"title"];
        NSString *imageUrl = [dic objectForKey:@"bgImage"];
        ACPointAnnotation *aPoint = [[ACPointAnnotation alloc] init];
        CLLocationCoordinate2D cc2d;
        cc2d.longitude = lon;
        cc2d.latitude = lat;
        aPoint.coordinate = cc2d;
        aPoint.pointId = idStr;
        if (title && [title length] > 0) {
            aPoint.title = title;
        }
        if (imageUrl && [imageUrl length] > 0) {
            aPoint.imageUrl = [self absPath:imageUrl];
        }
        if (iconPath && [iconPath length] > 0) {
            aPoint.iconUrl = [self absPath:iconPath];
        }
        [self.currentMapView addAnnotation:aPoint];
        [self.pointAnnotationDic setObject:aPoint forKey:idStr];
    }
    return ids;
}

-(NSNumber *)setMarkerOverlay:(NSMutableArray *)inArguments {

    
    ACArgsUnpack(NSString *idStr,NSDictionary *markInfoDic) = inArguments;

    
    ACPointAnnotation * oldPointAnnotation = [self.pointAnnotationDic objectForKey:idStr];
    NSDictionary * markInfo = dictionaryArg(markInfoDic[@"makerInfo"]);
    
    if (!oldPointAnnotation || !markInfo) {
        return UEX_FALSE;
    }
    [self.currentMapView removeAnnotation:oldPointAnnotation];

    
    
    CLLocationCoordinate2D cc2d = oldPointAnnotation.coordinate;
    NSNumber *lonNum = numberArg(markInfo[@"longitude"]);
    if (lonNum) {
        cc2d.longitude = lonNum.doubleValue;
        oldPointAnnotation.coordinate = cc2d;
    }
    NSNumber *latNum = numberArg(markInfo[@"latitude"]);
    if (latNum) {
        cc2d.latitude = latNum.doubleValue;
        oldPointAnnotation.coordinate = cc2d;
    }

    NSString * iconPath = stringArg(markInfo[@"icon"]);
    if (iconPath && [iconPath length] > 0) {
        oldPointAnnotation.iconUrl = [self absPath:iconPath];
    }
    
    NSDictionary * bubble = dictionaryArg(markInfo[@"bubble"]);
    if (bubble && [[bubble allKeys]count] > 0) {
        NSString * title= stringArg(bubble[@"title"]);
        if (title && [title length] > 0) {
            oldPointAnnotation.title = title;
        }
        NSString * imageUrl = stringArg(bubble[@"bgImage"]);
        if (imageUrl && [imageUrl length] > 0) {
            oldPointAnnotation.imageUrl = [self absPath:imageUrl];
        }
    }
    
    [self.currentMapView addAnnotation:oldPointAnnotation];
    return UEX_TRUE;
}

-(NSNumber *)showBubble:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSString * idStr) = inArguments;
    
    ACPointAnnotation * pAnnotation = [self.pointAnnotationDic objectForKey:idStr];
    if (!pAnnotation) {
        return UEX_FALSE;
    }
    [self.currentMapView selectAnnotation:pAnnotation animated:YES];
    for (ACPointAnnotation * pAnnotation in [self.pointAnnotationDic allValues]) {
        if ([pAnnotation.pointId isEqual:idStr]) {
            [self.currentMapView selectAnnotation:pAnnotation animated:YES];
        } else {
            [self.currentMapView deselectAnnotation:pAnnotation animated:YES];
        }
    }
    return UEX_TRUE;
}

-(void)hideBubble:(NSMutableArray *)inArguments {
    for (ACPointAnnotation * pAnnotation in [self.pointAnnotationDic allValues]) {
            [self.currentMapView deselectAnnotation:pAnnotation animated:YES];
    }
}

-(void)removeMakersOverlay:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSArray* idArray) = inArguments;

    if (!idArray) {
        return;
    }
    
    if ([idArray count] == 0) {
        [self.currentMapView removeAnnotations:self.currentMapView.annotations];
        [self.pointAnnotationDic removeAllObjects];
        return;
    }
    for (id aId in idArray) {
        NSString * identifier = stringArg(aId);
        if (!identifier) {
            continue;
        }
        identifier = [identifier stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"\""]];
        ACPointAnnotation * pAnnotation = [self.pointAnnotationDic objectForKey:identifier];
        [self.currentMapView removeAnnotation:pAnnotation];
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
            if (!view) {
                view = [[BMKAnnotationView alloc]initWithAnnotation:routeAnnotation reuseIdentifier:@"start_node"];
                view.image = [UIImage imageWithContentsOfFile:[self getMyBundlePath1:@"images/icon_nav_start.png"]];
                view.centerOffset = CGPointMake(0, -(view.frame.size.height * 0.5));
                view.canShowCallout = YES;
            }
            view.annotation = routeAnnotation;
        }
            break;
        case 1:
        {
            view = [mapview dequeueReusableAnnotationViewWithIdentifier:@"end_node"];
            if (view == nil) {

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
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onMakerClickListner" arguments:ACArgsPack(numberArg(pointId))];
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onMarkerClickListener" arguments:ACArgsPack(numberArg(pointId))];
        }
    }
    
}

//添加点覆盖物{"id":"d1","fillColor":"#111333","radius":20,"latitude":39.532,"longitude":116.222}
-(NSString *)addDotOverlay:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSDictionary* dict) = inArguments;
    NSString * idStr = stringArg(dict[@"id"]) ?:[self randomString];
    
    if ([_overlayViewDic objectForKey:idStr]) {
        [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.overlayDataDic setValue:idStr forKey:@"id"];
    //    [self.overlayDataDic setDictionary:dict];
    [self.overlayDataDic setObject:@"0" forKey:@"lineWidth"];
    [self.overlayDataDic setObject:@"#000000" forKey:@"strokeColor"];
    CLLocationCoordinate2D coor;
    coor.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    coor.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    float radius = [[dict objectForKey:@"radius"] floatValue];
    BMKCircle* circle = [BMKCircle circleWithCenterCoordinate:coor radius:radius];
    [self.currentMapView addOverlay:circle];
    
    return idStr;
}

//添加弧线覆盖物
-(NSString *)addArcOverlay:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* dict) = inArguments;
    NSString * idStr = stringArg(dict[@"id"]) ?:[self randomString];
    
    if ([_overlayViewDic objectForKey:idStr]) {
        [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.overlayDataDic setValue:idStr forKey:@"id"];
    //    [self.overlayDataDic setDictionary:dict];
    CLLocationCoordinate2D coords[3] = {0};
    coords[0].latitude = [[dict objectForKey:@"startLatitude"] doubleValue];
    coords[0].longitude = [[dict objectForKey:@"startLongitude"] doubleValue];
    coords[1].latitude = [[dict objectForKey:@"centerLatitude"] doubleValue];
    coords[1].longitude = [[dict objectForKey:@"centerLongitude"] doubleValue];
    coords[2].latitude = [[dict objectForKey:@"endLatitude"] doubleValue];
    coords[2].longitude = [[dict objectForKey:@"endLongitude"] doubleValue];
    BMKArcline * arcline = [BMKArcline arclineWithCoordinates:coords];
    [self.currentMapView addOverlay:arcline];
    
    return idStr;
}

//添加线型覆盖物
-(NSString *)addPolylineOverlay:(NSMutableArray *)inArguments{
    //    typeOverLayerView = line;
    ACArgsUnpack(NSDictionary* dict) = inArguments;
    NSString * idStr = stringArg(dict[@"id"]) ?:[self randomString];
    
    if ([_overlayViewDic objectForKey:idStr]) {
        [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.overlayDataDic setValue:idStr forKey:@"id"];
    NSArray * propertyArray = [dict objectForKey:@"property"];
    int caplity = (int)[propertyArray count];
    CLLocationCoordinate2D coords[999] = {0};
    for (int i = 0; i <[ propertyArray count]; i++) {
        coords[i].latitude = [[[propertyArray objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
        coords[i].longitude =  [[[propertyArray objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
    }
    BMKPolyline * polyline = [BMKPolyline polylineWithCoordinates:coords count:caplity];
    [self.currentMapView addOverlay:polyline];
    
    return idStr;
}

//添加圆型覆盖物
-(NSString *)addCircleOverlay:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* dict) = inArguments;
    NSString * idStr = stringArg(dict[@"id"]) ?:[self randomString];
    
    if ([_overlayViewDic objectForKey:idStr]) {
        [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.overlayDataDic setValue:idStr forKey:@"id"];
    CLLocationCoordinate2D coor;
    coor.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    coor.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    float radius = [[dict objectForKey:@"radius"] floatValue];
    BMKCircle * circle = [BMKCircle circleWithCenterCoordinate:coor radius:radius];
    [self.currentMapView addOverlay:circle];
    
    return idStr;
}

//添加多边型覆盖物
-(NSString *)addPolygonOverlay:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* dict) = inArguments;
    NSString * idStr = stringArg(dict[@"id"]) ?:[self randomString];

    if ([_overlayViewDic objectForKey:idStr]) {
        [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.overlayDataDic setValue:idStr forKey:@"id"];
    NSArray *propertyArray = [dict objectForKey:@"property"];

    int caplity = (int)[propertyArray count];
    CLLocationCoordinate2D coords[100] = {0};
    for (int i = 0; i < [propertyArray count]; i  ++) {
        coords[i].latitude = [[[propertyArray objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
        coords[i].longitude = [[[propertyArray objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
    }
    BMKPolygon* polygon = [BMKPolygon polygonWithCoordinates:coords count:caplity];
    [self.currentMapView addOverlay:polygon];
    
    return idStr;
}

//添加addGroundOverLayer
-(NSString *)addGroundOverlay:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* dict) = inArguments;
    NSString * idStr = stringArg(dict[@"id"]) ?:[self randomString];
    
    if ([_overlayViewDic objectForKey:idStr]) {
        [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
        [_overlayViewDic removeObjectForKey:idStr];
    }
    
    self.overlayDataDic = nil;
    self.overlayDataDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.overlayDataDic setValue:idStr forKey:@"id"];
    NSArray * propertyArr = [dict objectForKey:@"property"];
    NSString * imageUrl = [dict objectForKey:@"imageUrl"];
    int type = 0;
    if ([dict objectForKey:@"type"]) {
        type = [[dict objectForKey:@"type"] intValue];
    }

    if (type != 0) {
        return nil;
    }
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
    [self.currentMapView addOverlay:groundOverlay];
    
    return idStr;
}
//添加文字覆盖物
- (void) addTextOverLay: (NSMutableArray *) inArguments {
    
}

//<method name="addText" />
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKArcline class]]){

        BMKArclineView * arclineView = [[BMKArclineView alloc] initWithOverlay:overlay];
        NSString * colorStr=[self.overlayDataDic objectForKey:@"strokeColor"];
        arclineView.strokeColor = [MapUtility getColor:colorStr];
        arclineView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        NSString * idStr = [self.overlayDataDic objectForKey:@"id"];
        [_overlayViewDic setObject:overlay forKey:idStr];
        return arclineView;
    }
    if ([overlay isKindOfClass:[BMKCircle class]]){

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

        polylineView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        NSString * idStr = [self.overlayDataDic objectForKey:@"id"];
        if (idStr) {
            [_overlayViewDic setObject:overlay forKey:idStr];
        }
        
        return polylineView;
    }
    
    if ([overlay isKindOfClass:[BMKPolygon class]]){

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

        BMKGroundOverlayView * groundView = [[BMKGroundOverlayView alloc] initWithOverlay:overlay];
        NSString * idStr=[self.overlayDataDic objectForKey:@"id"];
        [_overlayViewDic setObject:overlay forKey:idStr];
        return groundView;
    }
    return nil;
}



//清除覆盖物
-(void)removeOverlay:(NSMutableArray *)inArguments{

    if (inArguments.count == 0) {
        if (self.currentMapView) {
            NSArray * overlaysArray = [NSArray arrayWithArray:self.currentMapView.overlays];
            [self.currentMapView removeOverlays:overlaysArray];
            [_overlayViewDic removeAllObjects];
        }
        return;
    }
    
    
    
    for (id aID in inArguments) {
        NSString *idStr = stringArg(aID);
        if ([_overlayViewDic objectForKey:idStr]) {
            [self.currentMapView removeOverlay:[_overlayViewDic objectForKey:idStr]];
            [_overlayViewDic removeObjectForKey:idStr];
        }
        
    }
    
}
//************************地图操作******************************
/// 地图比例尺级别，在手机上当前可使用的级别为3-19级
-(void)setZoomLevel:(NSMutableArray *)inArguments{
    float zoomLevel = [[inArguments objectAtIndex:0] floatValue];
    if (zoomLevel >=3 && zoomLevel <= 19) {
        self.currentMapView.zoomLevel = zoomLevel;
    }
}
//地图旋转角度，在手机上当前可使用的范围为－180～180度
-(void)rotate:(NSMutableArray *)inArguments{
    float rotation = [[inArguments objectAtIndex:0] floatValue];
    self.currentMapView.rotation = rotation;
}
//地图俯视角度，在手机上当前可使用的范围为－45～0度
-(void)overlook:(NSMutableArray *)inArguments{
    float overlooking = [[inArguments objectAtIndex:0] floatValue];
    self.currentMapView.overlooking = overlooking;
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
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onMakerBubbleClickListner" arguments:ACArgsPack(numberArg(pointId))];
            [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMarkerBubbleClickListener" arguments:ACArgsPack(numberArg(pointId))];
        }
    }
}
/**
 *地图区域改变完成后会调用此接口
 *@param mapview 地图View
 *@param animated 是否动画
 */
- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.isFirstTime) {
        self.isFirstTime = NO;
        return;
    }
    double latitude = mapView.centerCoordinate.latitude;
    double longitude = mapView.centerCoordinate.longitude;
    float zoomLevel = mapView.zoomLevel;
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onZoomLevelChangeListener" arguments:ACArgsPack(@(zoomLevel),@(latitude),@(longitude))];

}
/**
 *点中底图标注后会回调此接口
 *@param mapview 地图View
 *@param mapPoi 标注点信息
 */
- (void)mapView:(BMKMapView *)mapView onClickedMapPoi:(BMKMapPoi*)mapPoi
{

    //NSString* showmeg = [NSString stringWithFormat:@"您点击了底图标注:%@,\r\n当前经度:%f,当前纬度:%f,\r\nZoomLevel=%d;RotateAngle=%d;OverlookAngle=%d", mapPoi.text,mapPoi.pt.longitude,mapPoi.pt.latitude, (int)self.currentMapView.zoomLevel,self.currentMapView.rotation,self.currentMapView.overlooking];
//    NSDictionary * showDic = [NSDictionary dictionaryWithObjectsAndKeys:mapPoi.text,@"mapPoiText",mapPoi.pt.longitude,@"longitude",mapPoi.pt.latitude,@"latitude",(int)self.currentMapView.zoomLevel,@"zoomLevel",self.currentMapView.rotation,@"rotation",self.currentMapView.overlooking,@"overlooking", nil];
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
    
    NSDictionary *result = @{
                             @"longitude":@(coordinate.longitude),
                             @"latitude":@(coordinate.latitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onMapClickListener" arguments:ACArgsPack(result.ac_JSONFragment)];
}

/**
 *双击地图时会回调此接口
 *@param mapview 地图View
 *@param coordinate 返回双击处坐标点的经纬度
 */
- (void)mapview:(BMKMapView *)mapView onDoubleClick:(CLLocationCoordinate2D)coordinate{
    
    NSDictionary *result = @{
                             @"longitude":@(coordinate.longitude),
                             @"latitude":@(coordinate.latitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onMapDoubleClickListener" arguments:ACArgsPack(result.ac_JSONFragment)];
}

/**
 *长按地图时会回调此接口
 *@param mapview 地图View
 *@param coordinate 返回长按事件坐标点的经纬度
 */
- (void)mapview:(BMKMapView *)mapView onLongClick:(CLLocationCoordinate2D)coordinate{
    
    
    NSDictionary *result = @{
                             @"longitude":@(coordinate.longitude),
                             @"latitude":@(coordinate.latitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onMapLongClickListener" arguments:ACArgsPack(result.ac_JSONFragment)];
}
//增加地图手势监听(返回值包括缩放等级和中心点坐标)
//onMapStatusChange


//地图区域发生变化的监听函数
//- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    NSString* showmeg = [NSString stringWithFormat:@"地图区域发生了变化(x=%d,y=%d,\r\nwidth=%d,height=%d).\r\nZoomLevel=%d;RotateAngle=%d;OverlookAngle=%d",(int)self.currentMapView.visibleMapRect.origin.x,(int)self.currentMapView.visibleMapRect.origin.y,(int)self.currentMapView.visibleMapRect.size.width,(int)self.currentMapView.visibleMapRect.size.height,(int)self.currentMapView.zoomLevel,self.currentMapView.rotation,self.currentMapView.overlooking];
//    NSString * zoomLevel = [NSString stringWithFormat:@"%d",(int)self.currentMapView.zoomLevel];
//    NSDictionary * showDic = [NSDictionary dictionaryWithObjectsAndKeys:zoomLevel,@"zoomLevel",self.currentMapView.rotation,@"rotation",self.currentMapView.overlooking,@"overlooking",(int)self.currentMapView.visibleMapRect.origin.x,@"x",(int)self.currentMapView.visibleMapRect.origin.y,@"y",(int)self.currentMapView.visibleMapRect.size.width,@"width",(int)self.currentMapView.visibleMapRect.size.height,@"height", nil];
//    NSString * onRegionDidChange = [showDic JSONValue];
//    NSString * inCallbackName = @"uexBaiduMap.onRegionDidChange";
//    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,onRegionDidChange];
//    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
//    [showDic release];
//}
//************************UI控制******************************
///设定地图View能否支持用户多点缩放(双指)
-(void)setZoomEnable:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setZoomEnabled:enable];
}

///设定地图View能否支持用户缩放(双击或双指单击)
-(void)setZoomEnabledWithTap:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setZoomEnabledWithTap:enable];

}

///设定地图View能否支持用户移动地图
-(void)setScrollEnable:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setScrollEnabled:enable];
    
}
///设定地图View能否支持俯仰角
-(void)setOverlookEnable:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setOverlookEnabled:enable];

}
///设定地图View能否支持旋转
-(void)setRotateEnable:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setRotateEnabled:enable];
    

}
//放大地图
-(void)zoomIn:(NSMutableArray *)inArguments{
    if (self.currentMapView) {
        [self.currentMapView zoomIn];
    }
}

//缩小地图
-(void)zoomOut:(NSMutableArray *)inArguments{
    if (self.currentMapView) {
        [self.currentMapView zoomOut];
    }
}

-(void)zoomToSpan:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSNumber *lonNum,NSNumber *latNum) = inArguments;
    if (!latNum || !lonNum) {
        return;
    }
    BMKCoordinateRegion region;
    region.center = self.currentMapView.centerCoordinate;
    region.span.longitudeDelta = [lonNum doubleValue];
    region.span.latitudeDelta = [latNum doubleValue];
    [self.currentMapView setRegion:region animated:YES];
}

//将地图缩放到指定的矩形区域
-(void)zoomToBounds:(NSMutableArray *)inArguments{
    //
}
-(void)setCompassEnable:(NSMutableArray *)inArguments{
    
    BOOL isOpen = [inArguments.firstObject boolValue];
    
    if (isOpen) {
        
        [self.currentMapView setCompassPosition:self.positionOfCompass];
        
    } else {
        
        self.positionOfCompass = self.currentMapView.compassPosition;
        self.currentMapView.compassPosition = CGPointMake(-50, -50);
        
    }
    
}


/// 指南针的位置，设定坐标以BMKMapView左上角为原点，向右向下增长
-(void)setCompassPosition:(NSMutableArray *) inArguments{
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum) = inArguments;
    if (!xNum || !yNum) {
        return;
    }
    float x = [xNum floatValue];
    float y = [yNum floatValue];
    [self.currentMapView setCompassPosition:CGPointMake(x, y)];
}
/// 设定是否显式比例尺
-(void)showMapScaleBar:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    
    [self.currentMapView setShowMapScaleBar:enable];
}
-(void)setMapScaleBarPosition:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum) = inArguments;
    if (!xNum || !yNum) {
        return;
    }
    float x = [xNum floatValue];
    float y = [yNum floatValue];
    [self.currentMapView setMapScaleBarPosition:CGPointMake(x, y)];
}
//************POI**************************

//setPoiPageCapacity设置搜索POI单页数据量
-(void)setPoiPageCapacity:(NSMutableArray *)inArguments{
    int pageCapacity = [inArguments.firstObject intValue];
    self.pageCapacity = pageCapacity;
}

-(NSNumber *)getPoiPageCapacity:(NSMutableArray *)inArguments{
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbGetPoiPageCapacity" arguments:ACArgsPack(@0,@2,@(self.pageCapacity))];
    return @(self.pageCapacity);

}

//poiSearchInCity 城市范围内搜索
-(void)poiSearchInCity:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    NSString * city = stringArg(jsDic[@"city"]);
    NSString * keyword = stringArg(jsDic[@"searchKey"]);
    int pageIndex = [[jsDic objectForKey:@"pageNum"] intValue];
    

    
    BMKCitySearchOption * option = [[BMKCitySearchOption alloc]init];
    option.city = city;
    option.keyword = keyword;
    option.pageCapacity = _pageCapacity;
    option.pageIndex = pageIndex;
    uexBaiduPOISearcher *searcher = [[uexBaiduPOISearcher alloc]init];
    searcher.mode = uexBaiduPOISearchModeCity;
    searcher.searchOption = option;
    [self.searchers addObject:searcher];
    [searcher searchWithCompletion:^(id resultObj, NSInteger errorCode) {
        [self cbPOISearchResult:resultObj errorCode:(BMKSearchErrorCode)errorCode cbFunction:cb];
        [searcher dispose];
        [self.searchers removeObject:searcher];
        
    }];
}
//poiSearchNearBy 周边搜索
-(void)poiNearbySearch:(NSMutableArray *)inArguments{
    //key, longitude, latitude,radius, pageIndex
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    NSString * keyword = stringArg(jsDic[@"searchKey"]);
    double longitude = [[jsDic objectForKey:@"longitude"] doubleValue];
    double latitude = [[jsDic objectForKey:@"latitude"] doubleValue];
    int radius = [[jsDic objectForKey:@"radius"] intValue];
    int pageIndex = [[jsDic objectForKey:@"pageNum"] intValue];

    //发起检索
    BMKNearbySearchOption * option = [[BMKNearbySearchOption alloc]init];
    option.pageIndex = pageIndex;
    option.pageCapacity = _pageCapacity;
    option.location = CLLocationCoordinate2DMake(latitude, longitude);
    option.keyword = keyword;
    option.radius = radius;
    
    uexBaiduPOISearcher *searcher = [[uexBaiduPOISearcher alloc]init];
    searcher.mode = uexBaiduPOISearchModeNearby;
    searcher.searchOption = option;
    [self.searchers addObject:searcher];
    [searcher searchWithCompletion:^(id resultObj, NSInteger errorCode) {
        [self cbPOISearchResult:resultObj errorCode:(BMKSearchErrorCode)errorCode cbFunction:cb];
        [searcher dispose];
        [self.searchers removeObject:searcher];
        
    }];
}

//poiSearchInBounds 区域内搜索
-(void)poiBoundSearch:(NSMutableArray *)inArguments{
    //key， lbLongitude， lbLatitude， rtLongitude， rtLatitude， pageIndex
    
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    
    
    NSString * keyword = [jsDic objectForKey:@"searchKey"];
    int pageIndex = [[jsDic objectForKey:@"pageNum"] intValue];
    
    double lbLongitude = [[[jsDic objectForKey:@"southwest"] objectForKey:@"longitude"] doubleValue];
    double lbLatitude = [[[jsDic objectForKey:@"southwest"] objectForKey:@"latitude"] doubleValue];
    double rtLongitude = [[[jsDic objectForKey:@"northeast"] objectForKey:@"longitude"] doubleValue];
    double rtLatitude = [[[jsDic objectForKey:@"northeast"] objectForKey:@"latitude"] doubleValue];
    

    
    //发起检索
    BMKBoundSearchOption * option = [[BMKBoundSearchOption alloc]init];
    option.leftBottom = CLLocationCoordinate2DMake(lbLatitude, lbLongitude);
    option.rightTop = CLLocationCoordinate2DMake(rtLatitude, rtLongitude);
    option.pageIndex = pageIndex;
    option.pageCapacity = _pageCapacity;
    option.keyword = keyword;
    
    uexBaiduPOISearcher *searcher = [[uexBaiduPOISearcher alloc]init];
    searcher.mode = uexBaiduPOISearchModeBound;
    searcher.searchOption = option;
    [self.searchers addObject:searcher];
    [searcher searchWithCompletion:^(id resultObj, NSInteger errorCode) {
        [self cbPOISearchResult:resultObj errorCode:(BMKSearchErrorCode)errorCode cbFunction:cb];
        [searcher dispose];
        [self.searchers removeObject:searcher];
        
    }];
}

//实现PoiSearchDeleage处理回调结果

- (void)cbPOISearchResult:(BMKPoiResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode cbFunction:(ACJSFunctionRef *)cb{
    __block UEX_ERROR err = kUexNoError;
    __block NSMutableDictionary * resultDic = [NSMutableDictionary dictionary];
    @onExit{
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbPoiSearchResult" arguments:ACArgsPack(resultDic.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(err,resultDic)];
    };
    if (errorCode == BMK_SEARCH_AMBIGUOUS_KEYWORD){
        err = uexErrorMake(1,@"起始点有歧义");
        return;
    }
    
    if (errorCode != BMK_SEARCH_NO_ERROR) {
        err = uexErrorMake(errorCode,@"抱歉，未找到结果");
        return;
    }
    
    
    
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

    

}



//*****************线路规划**********************************
//busLineSearch公交线路搜索
-(void)busLineSearch:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    
    BusLineObjct * tempBusLineObj = [_routePlanDic objectForKey:@"busLineObj"];
    if (tempBusLineObj) {
        [tempBusLineObj remove];
    }
    
    
    [self.overlayDataDic setObject:@"busline" forKey:@"id"];
    NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];//[MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
    [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
    NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
    [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
    [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];
    
    BusLineObjct * busLineObj = [[BusLineObjct alloc]initWithuexObj:self andMapView:self.currentMapView andJson:jsDic];
    [_routePlanDic setObject:busLineObj forKey:@"busLineObj"];
    [busLineObj searchWithCompletion:^(id result, NSInteger error) {
        [busLineObj dispose];
        BMKBusLineResult* busLineResult = (BMKBusLineResult *)result;
        UEX_ERROR err = kUexNoError;
        NSDictionary *dict = nil;
        
        if (error == BMK_SEARCH_NO_ERROR) {
            NSString * busCompany = busLineResult.busCompany;
            NSString * busLineName = busLineResult.busLineName;
            NSString * uid = busLineResult.uid;
            NSString * startTime = busLineResult.startTime;
            NSString * endTime = busLineResult.endTime;
            NSString * isMonTicket = [NSString stringWithFormat:@"%d",busLineResult.isMonTicket];
            NSMutableArray *  busStations = [NSMutableArray array];
            for (BMKBusStation * station in busLineResult.busStations) {
                NSString * title = station.title;
                double lon = station.location.longitude;
                NSString * longitude = [NSString stringWithFormat:@"%f",lon];
                double lat = station.location.latitude;
                NSString * latitude = [NSString stringWithFormat:@"%f",lat];
                NSDictionary * tempDic = [NSDictionary dictionaryWithObjectsAndKeys:title,@"title",longitude,@"longitude",latitude,@"latitude", nil];
                [busStations addObject:tempDic];
            }
            
            dict = [NSDictionary dictionaryWithObjectsAndKeys:busCompany,@"busCompany",busLineName,@"busLineName",uid,@"uid",startTime,@"startTime",endTime,@"endTime",isMonTicket,@"isMonTicket",busStations,@"busStations", nil];

        }else{
            err = uexErrorMake(error);
        }
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbBusLineSearchResult" arguments:ACArgsPack(dict.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(err,dict)];
    }];
    
    


}

-(void)removeBusLine:(NSMutableArray *)inArguments {
    BusLineObjct * busLineObj = [_routePlanDic objectForKey:@"busLineObj"];
    if (busLineObj) {
        [busLineObj remove];
        [_routePlanDic removeObjectForKey:@"busLineObj"];
    }
}




-(void)removeRoutePlan:(NSMutableArray *)inArguments {

    ACArgsUnpack(NSString *idStr) = inArguments;
    if (!idStr) {
        return;
    }
    SearchPlanObject * spObj = [_routePlanDic objectForKey:idStr];
    if (spObj) {
        [spObj remove];
    }
}


-(NSString *)searchRoutePlan:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSDictionary *dict,ACJSFunctionRef *cb) = inArguments;
    
    NSString * idStr = [dict objectForKey:@"id"]?:[self randomString];
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

    
    
    
    SearchPlanObject * spObj = [[SearchPlanObject alloc]initWithuexObj:self andMapView:self.currentMapView andJson:dict];
    [_routePlanDic setObject:spObj forKey:idStr];

    [spObj searchWithCompletion:^(id resultObj, NSInteger errorCode) {

        [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onSearchRoutePlan" arguments:ACArgsPack(idStr,@(errorCode))];
        [cb executeWithArguments:ACArgsPack(@(errorCode))];
        [spObj dispose];
    }];
    return idStr;
}


//*****************地里编码**********************************
-(void)geocode:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    
    NSString * city = [jsDic objectForKey:@"city"];
    NSString * address = [jsDic objectForKey:@"address"];
    

    BMKGeoCodeSearchOption * geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
    geoCodeSearchOption.city = city;
    geoCodeSearchOption.address = address;

    
    uexBaiduGeoCodeSearcher *searcher = [[uexBaiduGeoCodeSearcher alloc]init];
    searcher.option = geoCodeSearchOption;
    [self.searchers addObject:searcher];
    [searcher searchWithCompletion:^(id resultObj, NSInteger errorCode) {
        BMKGeoCodeResult *result = (BMKGeoCodeResult *)resultObj;
        if (errorCode != BMK_SEARCH_NO_ERROR) {
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbGeoCodeResult" arguments:ACArgsPack(@(errorCode))];
            [cb executeWithArguments:ACArgsPack(@(errorCode))];
        }else{
            NSDictionary *dict = @{
                                   @"longitude":@(result.location.longitude),
                                   @"latitude":@(result.location.latitude)
                                   };
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbGeoCodeResult" arguments:ACArgsPack(dict.ac_JSONFragment)];
            [cb executeWithArguments:ACArgsPack(@0,dict)];
        }
        [searcher dispose];
    }];
}






-(void)reverseGeocode: (NSMutableArray *) inArguments {
    
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }

    
    double longitude = [[jsDic objectForKey:@"longitude"] doubleValue];
    double latitude = [[jsDic objectForKey:@"latitude"] doubleValue];
    CLLocationCoordinate2D pt = CLLocationCoordinate2DMake(latitude, longitude);


    BMKReverseGeoCodeOption * reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeoCodeSearchOption.reverseGeoPoint = pt;
    
    uexBaiduReverseGeocodeSearcher *searcher = [[uexBaiduReverseGeocodeSearcher alloc]init];
    searcher.option = reverseGeoCodeSearchOption;
    [self.searchers addObject:searcher];
    [searcher searchWithCompletion:^(id resultObj, NSInteger errorCode) {
        BMKReverseGeoCodeResult *result = (BMKReverseGeoCodeResult *)resultObj;
        
        if (errorCode != BMK_SEARCH_NO_ERROR) {
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbReverseGeoCodeResult" arguments:ACArgsPack(@(errorCode))];
            [cb executeWithArguments:ACArgsPack(@(errorCode))];
        } else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:result.address forKey:@"address"];
            [dict setValue:result.addressDetail.city forKey:@"city"];
            [dict setValue:result.addressDetail.streetName forKey:@"street"];
            [dict setValue:result.addressDetail.streetNumber forKey:@"streetNumber"];
            [dict setValue:result.addressDetail.province forKey:@"province"];
            [dict setValue:result.addressDetail.district forKey:@"district"];
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbReverseGeoCodeResult" arguments:ACArgsPack(dict.ac_JSONFragment)];
            [cb executeWithArguments:ACArgsPack(@0,dict)];
        }
    }];
}

//******************计算工具*****************************

//计算两点之间距离
- (NSNumber *)getDistance:(NSMutableArray*)inArguments{
    double lat1 = [[inArguments objectAtIndex:0] doubleValue];
    double lon1 = [[inArguments objectAtIndex:1] doubleValue];
    double lat2 = [[inArguments objectAtIndex:2] doubleValue];
    double lon2 = [[inArguments objectAtIndex:3] doubleValue];
    BMKMapPoint point1 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(lat1,lon1));
    BMKMapPoint point2 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(lat2,lon2));
    CLLocationDistance distance = BMKMetersBetweenMapPoints(point1,point2);

    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbGetDistance" arguments:ACArgsPack(@0,@1,@(distance))];
    return @(distance);
}

- (NSDictionary *)getCenter:(NSMutableArray*)inArguments{
    if (!self.currentMapView) {
        return nil;
    }
    NSDictionary *center = @{
                             @"latitude":@(self.currentMapView.centerCoordinate.latitude),
                             @"longitude":@(self.currentMapView.centerCoordinate.longitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath:@"cbGetCenter" arguments:ACArgsPack(center.ac_JSONFragment)];
    return center;
}

//转换GPS坐标至百度坐标
- (void)getBaiduFromGPS:(NSMutableArray *)inArguments{
    CLLocationCoordinate2D locationCoord;
    if ([inArguments count] == 2) {
        locationCoord.longitude = [[inArguments objectAtIndex:0] doubleValue];
        locationCoord.latitude = [[inArguments objectAtIndex:1] doubleValue];
    }

    //BMK_COORDTYPE_GPS----->///GPS设备采集的原始GPS坐标
    NSDictionary * baidudict = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(locationCoord.latitude, locationCoord.longitude),BMK_COORDTYPE_GPS);
    CLLocationCoordinate2D lC2D = BMKCoorDictionaryDecode(baidudict);

    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbBaiduFromGPS" arguments:ACArgsPack(@(lC2D.latitude),@(lC2D.longitude))];

}

//转换 google地图、soso地图、aliyun地图、mapabc地图和amap地图所用坐标至百度坐标
- (void)getBaiduFromGoogle:(NSMutableArray *)inArguments{
    CLLocationCoordinate2D locationCoord;
    if ([inArguments count]== 2) {
        locationCoord.longitude = [[inArguments objectAtIndex:0] doubleValue];
        locationCoord.latitude = [[inArguments objectAtIndex:1] doubleValue];
    }

    NSDictionary * baidudict = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(locationCoord.latitude, locationCoord.longitude),BMK_COORDTYPE_COMMON);
    CLLocationCoordinate2D lC2D = BMKCoorDictionaryDecode(baidudict);


    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbBaiduFromGoogle" arguments:ACArgsPack(@(lC2D.latitude),@(lC2D.longitude))];
}
//******************定位*****************************
-(void)getCurrentLocation:(NSMutableArray *)inArguments{
    
    ACArgsUnpack(ACJSFunctionRef *cbCurrentLocation) = inArguments;
    
    if (!self.locationService) {
        self.locationService = [[BMKLocationService alloc]init];
    }
    if (!_didStartLocatingUser) {
        self.locationService.delegate = self;
        [self.locationService startUserLocationService];
        _isUpdateLocationOnce = YES;
        [self.tmpFuncDict setValue:cbCurrentLocation forKey:@"cbCurrentLocation"];
    } else {
        double longit = _locationService.userLocation.location.coordinate.longitude;
        double lat = _locationService.userLocation.location.coordinate.latitude;
        NSDate * timestamp = _locationService.userLocation.location.timestamp;
        NSString * timeStr = [NSString stringWithFormat:@"%.0f", [timestamp timeIntervalSince1970]];
        NSDictionary *dict = @{
                               @"longitude":@(longit),
                               @"latitude":@(lat),
                               @"timestamp":timeStr
                               };
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbCurrentLocation" arguments:ACArgsPack(dict.ac_JSONFragment)];
        [cbCurrentLocation executeWithArguments:ACArgsPack(kUexNoError,dict)];
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
    self.currentMapView.showsUserLocation = NO;
    if (self.locationService) {
        [self.locationService stopUserLocationService];
        self.locationService.delegate = nil;
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
        self.currentMapView.showsUserLocation = YES;//显示定位图层
    } else {
        self.currentMapView.showsUserLocation = NO;//显示定位图层
    }
    
}



/**
 *在将要启动定位时，会调用此函数
 */
- (void)willStartLocatingUser{
    _didStartLocatingUser = YES;
    
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbStartLocation" arguments:ACArgsPack(@0,@2,@0)];
}

/**
 *在停止定位后，会调用此函数
 */
- (void)didStopLocatingUser{
    _didStartLocatingUser = NO;
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbStopLocation" arguments:ACArgsPack(@0,@2,@0)];
}

//处理方向变更信息
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    [self.currentMapView updateLocationData:userLocation];
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
    NSDictionary *dict = @{
                           @"longitude":@(longit),
                           @"latitude":@(lat),
                           @"timestamp":timeStr
                           };
    
    if (_isUpdateLocationOnce) {
        _isUpdateLocationOnce = NO;
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.cbCurrentLocation" arguments:ACArgsPack(dict.ac_JSONFragment)];
        [self.tmpFuncDict[@"cbCurrentLocation"] executeWithArguments:ACArgsPack(kUexNoError,dict) completionHandler:^(JSValue * _Nullable returnValue) {
            [self.tmpFuncDict setValue:nil forKey:@"cbCurrentLocation"];
        }];
        [self.locationService stopUserLocationService];
        return;
    }
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexBaiduMap.onReceiveLocation" arguments:ACArgsPack(dict.ac_JSONFragment)];
    [self.currentMapView updateLocationData:userLocation];
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error{

}

- (void)setUserTrackingMode:(NSMutableArray *)inArguments {
//    BMKUserTrackingModeNone = 0,             /// 普通定位模式
//    BMKUserTrackingModeFollow,               /// 定位跟随模式
//    BMKUserTrackingModeFollowWithHeading,    /// 定位罗盘模式
    int mode = 0;//
    if ([inArguments count] >= 1) {
        mode = [[inArguments objectAtIndex:0] intValue];
    }
    
    
    self.currentMapView.showsUserLocation = NO;
    switch (mode) {
        case BMKUserTrackingModeFollow:
            self.currentMapView.userTrackingMode = BMKUserTrackingModeFollow;
            break;
        case BMKUserTrackingModeFollowWithHeading:
            self.currentMapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading;
            break;
        default:
            self.currentMapView.userTrackingMode = BMKUserTrackingModeNone;
            break;
    }
    self.currentMapView.showsUserLocation = YES;
}


@end
