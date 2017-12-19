/**
 *
 *	@file   	: EUExBaiduMap.m in EUExBaiduMap
 *
 *	@author 	: CeriNo
 *
 *	@date   	: Created on 17/5/31.
 *
 *	@copyright 	: 2017 The AppCan Open Source Project.
 *
 *  This program is free software:you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "EUExBaiduMap.h"
#import <CoreLocation/CoreLocation.h>

#import "uexBaiduPOISearcher.h"
#import "uexBaiduGeoCodeSearcher.h"
#import "uexBaiduReverseGeocodeSearcher.h"
#import <AppCanKit/ACEXTScope.h>
#import "uexBaiduMapOverlay.h"
#import "uexBaiduMapInfo.h"
#import "uexBaiduMapAnnotation.h"
#import "uexBaiduBusLineSearcher.h"
#import "uexBaiduMapRoutePlanSearcher.h"

@implementation BMKIndoorFloorCell

@synthesize floorTitleLabel = _floorTitleLabel;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    BMKIndoorFloorCell *cell = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    
    _floorTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 35, 30)];
    [_floorTitleLabel setTextAlignment:NSTextAlignmentCenter];
    [_floorTitleLabel setFont:[UIFont systemFontOfSize:14]];
    [_floorTitleLabel setTextColor:[UIColor blackColor]];
    [cell addSubview:_floorTitleLabel];
    
    UIView *selectBg = [[UIView alloc] initWithFrame:cell.frame];
    selectBg.backgroundColor = [UIColor colorWithRed:50.0/255 green:120.0/255.0 blue:1 alpha:0.8];
    cell.selectedBackgroundView = selectBg;
    
    return cell;
}


@end

@interface EUExBaiduMap()<BMKGeneralDelegate,BMKMapViewDelegate, BMKLocationServiceDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) BMKMapView * currentMapView;
@property (nonatomic, strong) BMKLocationService * locationService;
@property (nonatomic, assign) int pageCapacity;
@property (nonatomic, assign) BOOL isUpdateLocationOnce;
@property (nonatomic, assign) BOOL didStartLocatingUser;
@property (nonatomic, assign) BOOL didBusLineSearch;
@property (nonatomic, assign) BOOL isFirstTime;
@property (nonatomic, assign) CGPoint positionOfCompass;
@property (nonatomic, strong) NSMutableArray<id<uexBaiduMapSearcher>> *searchers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, uexBaiduMapOverlay *> *overlays;
@property (nonatomic, strong) NSMutableDictionary<NSString *, uexBaiduMapAnnotation *> *annotations;
@property (nonatomic, strong) NSMutableDictionary<NSString *, uexBaiduMapRoutePlanResult *> *routePlanResults;
@property (nonatomic, strong) uexBaiduMapInfo *mapInfo;
@property (nonatomic, strong) ACJSFunctionRef *cbOpenFunc;
@property (nonatomic, strong) ACJSFunctionRef *cbGetCurrentLocationFunc;
@property (nonatomic, strong) UITableView *floorTableView;//显示楼层条
@property (nonatomic, strong) BMKBaseIndoorMapInfo *indoorMapInfoFocused;//存储当前聚焦的室内图

@end


static BMKMapManager *_mapManager = nil;

@implementation EUExBaiduMap

#pragma mark - Life Cycle


- (instancetype)initWithWebViewEngine: (id<AppCanWebViewEngineObject>)engine
{
    self = [super initWithWebViewEngine: engine];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _mapManager = [[BMKMapManager alloc] init];
        });
        _pageCapacity = 10;
        _overlays = [NSMutableDictionary dictionary];
        _annotations = [NSMutableDictionary dictionary];
        _routePlanResults = [NSMutableDictionary dictionary];
        _positionOfCompass = CGPointMake(10, 10);
        _searchers = [NSMutableArray array];
        _indoorMapInfoFocused = [[BMKBaseIndoorMapInfo alloc] init];
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
    if (_currentMapView) {
        [_currentMapView setDelegate: nil];
        [_currentMapView viewWillDisappear];
        [_currentMapView removeFromSuperview];
        _currentMapView = nil;
    }
}



#pragma mark - BMKGeneralDelegate

- (void)onGetNetworkState: (int)iError{
    
    if (iError == 0) {
        return;
    }
    NSDictionary *result = @{@"errorInfo": @(iError)};
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onSDKReceiverError" arguments: ACArgsPack(result.ac_JSONFragment)];
}

- (void)onGetPermissionState: (int)iError{
    if (iError == E_PERMISSIONCHECK_OK) {
            [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbStart" arguments: ACArgsPack(@0,@2,@0)];
        return;
    }
    NSDictionary *result = @{@"errorInfo": @(iError)};
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onSDKReceiverError" arguments: ACArgsPack(result.ac_JSONFragment)];
}

#pragma mark - BMKMapViewDelegate

- (void)mapViewDidFinishLoading: (BMKMapView *)mapView{
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbOpen" arguments: nil];
    [self.cbOpenFunc executeWithArguments: nil];
    self.cbOpenFunc = nil;
}
//******************************基本功能************************************





//打开地图
- (void)open: (NSMutableArray *)inArguments{

    if (self.currentMapView) {
        return;
    }

    NSString * baiduMapKey = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"uexBaiduMapKey"];
    if(![_mapManager start: baiduMapKey generalDelegate: self]) {
        return;
    }
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum,NSNumber * wNum,NSNumber *hNum,NSNumber *lonNum,NSNumber *latNum) = inArguments;
    ACJSFunctionRef *callback = JSFunctionArg(inArguments.lastObject);
    //打开地图 设置中心点
    CGFloat x = [xNum floatValue];
    CGFloat y = [yNum floatValue];
    CGFloat w = [wNum floatValue];
    CGFloat h = [hNum floatValue];
    
    _isFirstTime = YES;
    self.currentMapView = [[BMKMapView alloc]initWithFrame: CGRectMake(x, y, w, h)];
    [self.currentMapView setDelegate: self];
    [self.currentMapView viewWillAppear];
    [[self.webViewEngine webView] addSubview: self.currentMapView];
    
    //添加楼层条
    _floorTableView = [[UITableView alloc] init];
    CGFloat floorH = 150;
    CGFloat floorY = self.currentMapView.frame.size.height - floorH - 100;
    _floorTableView.frame = CGRectMake(10, floorY, 35, floorH);
    _floorTableView.alpha = 0.8;
    _floorTableView.layer.borderWidth = 1;
    _floorTableView.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.7].CGColor;
    _floorTableView.delegate = self;
    _floorTableView.dataSource = self;
    _floorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _floorTableView.hidden = YES;
    [self.currentMapView addSubview:_floorTableView];
    
    if (lonNum && latNum) {
        double  longitude = [lonNum doubleValue];
        double  latitude = [latNum doubleValue];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latitude,longitude);
        [self.currentMapView setCenterCoordinate: center animated: NO];
    }
    @weakify(self);
    self.mapInfo = [[uexBaiduMapInfo alloc]initWithMap: self.currentMapView onChange: ^(NSDictionary *changeInfo) {
        @strongify(self);
        [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMapStatusChangeListener" arguments: ACArgsPack(changeInfo.ac_JSONFragment)];
    }];
    self.currentMapView.baseIndoorMapEnabled = YES;
    self.cbOpenFunc = callback;
}

//***************隐藏和显示百度地图************
- (void)hideMap: (NSMutableArray *)inArguments{
    [self.currentMapView setHidden: YES];
}

- (void)showMap: (NSMutableArray *)inArguments{
    [self.currentMapView setHidden: NO];
}

//关闭地图
- (void)close: (NSMutableArray *)inArguments{
    if(!self.currentMapView){
        return;
    }
    [self.currentMapView setDelegate: nil];
    [self.currentMapView viewWillDisappear];
    [self.currentMapView removeFromSuperview];
    self.currentMapView = nil;
}

//设置地图的类型
//BMKMapTypeStandard = 1,               ///< 标准地图
//BMKMapTypeSatellite = 4,               ///< 卫星地图
- (void)setMapType: (NSMutableArray *)inArguments{
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
// 设置是否开启实时交通
- (void)setTrafficEnabled: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *num) = inArguments;
    if (num) {
        [self.currentMapView setTrafficEnabled: num.boolValue];
    }
}

// 设定地图中心点坐标
- (void)setCenter: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *lonNum,NSNumber *latNum,NSNumber *aniNum) = inArguments;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latNum.doubleValue, lonNum.doubleValue);
    BOOL animated = aniNum.boolValue;
    [self.currentMapView setCenterCoordinate: center animated: animated];
}

//************************覆盖物功能******************************

- (void)addAnnotation: (uexBaiduMapAnnotation *)annotation{
    if (!annotation || !self.currentMapView) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentMapView addAnnotation: annotation];
    });
    [self.annotations setValue: annotation forKey: annotation.identifier];

}
- (void)removeAnnotationWithIdentifier: (NSString *)identifier{
    uexBaiduMapAnnotation *annotation = self.annotations[identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentMapView removeAnnotation: annotation];
    });
    [self.annotations removeObjectForKey: identifier];
}
- (void)removeAllAnnotations{
    for (NSString *identifier in self.annotations.allKeys) {
        [self removeAnnotationWithIdentifier: identifier];
    }
}

- (void)removeAllCustomAnnotations{
    for (uexBaiduMapAnnotation *annotation in self.annotations.allValues) {
        if ([annotation isKindOfClass: [uexBaiduMapCustomAnnotation class]]) {
            [self removeAnnotationWithIdentifier: annotation.identifier];
        }
        
    }
}


- (NSArray *)addMarkersOverlay: (NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSArray *infoArray) = inArguments;
    UEX_PARAM_GUARD_NOT_NIL(infoArray, nil);
    NSMutableArray *ids = [NSMutableArray array];
    for (id obj in infoArray) {
        NSDictionary *info = dictionaryArg(obj);
        if (!info) {
            continue;
        }
        NSString *identifier = stringArg(info[@"id"]) ?: UUID();
        NSNumber *latNum = numberArg(info[@"latitude"]);
        NSNumber *lonNum = numberArg(info[@"longitude"]);
        if (!latNum || !lonNum) {
            continue;
        }
        uexBaiduMapCustomAnnotation *annotation = [[uexBaiduMapCustomAnnotation alloc]init];
        annotation.identifier = identifier;
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latNum.doubleValue, lonNum.doubleValue);
        annotation.coordinate = coordinate;
        annotation.iconPath = [self absPath: stringArg(info[@"icon"])];
        NSDictionary *bubble = dictionaryArg(info[@"bubble"]);
        if (bubble) {
            annotation.bubbleTitle = stringArg(bubble[@"title"]);
            annotation.bubbleImagePath = [self absPath: stringArg(bubble[@"bgImage"])];
        }
        [self addAnnotation: annotation];
        [ids addObject: identifier];
    }

    return ids;
}

- (UEX_BOOL)setMarkerOverlay: (NSMutableArray *)inArguments {

    
    ACArgsUnpack(NSString *identifier,NSDictionary *makerInfo) = inArguments;
    uexBaiduMapCustomAnnotation *annotation = (uexBaiduMapCustomAnnotation *)self.annotations[identifier];
    UEX_PARAM_GUARD_NOT_NIL(annotation, UEX_FALSE);
    UEX_PARAM_GUARD_NOT_NIL(makerInfo, UEX_FALSE);
    NSDictionary *info = dictionaryArg(makerInfo[@"makerInfo"]);
    UEX_PARAM_GUARD_NOT_NIL(info, UEX_FALSE);
    [self removeAnnotationWithIdentifier: identifier];
    CLLocationCoordinate2D coordinate = annotation.coordinate;
    NSNumber *lonNum = numberArg(info[@"longitude"]);
    NSNumber *latNum = numberArg(info[@"latitude"]);
    if (lonNum) {
        coordinate.longitude = lonNum.doubleValue;
    }
    if (latNum) {
        coordinate.latitude = latNum.doubleValue;
    }
    annotation.coordinate = coordinate;
    NSString *iconPath = stringArg(info[@"icon"]);
    if (iconPath) {
        annotation.iconPath = [self absPath: iconPath];
    }
    NSDictionary *bubble = dictionaryArg(info[@"bubble"]);
    if (bubble) {
        NSString *title = stringArg(bubble[@"title"]);
        if (title) {
            annotation.bubbleTitle = title;
        }
        NSString *imagePath = stringArg(bubble[@"bgImage"]);
        if (imagePath) {
            annotation.bubbleImagePath = [self absPath: imagePath];
        }
    }
    [self addAnnotation: annotation];
    return UEX_TRUE;
}

- (UEX_BOOL)showBubble: (NSMutableArray *)inArguments {
    ACArgsUnpack(NSString * identifier) = inArguments;

    if (![self.annotations.allKeys containsObject: identifier]) {
        return UEX_FALSE;
    }
    for (uexBaiduMapAnnotation *annotation in self.annotations.allValues) {
        if ([annotation.identifier isEqual: identifier]) {
            [self.currentMapView selectAnnotation: annotation animated: YES];
        }else {
            [self.currentMapView deselectAnnotation: annotation animated: YES];
        }
    }
    return UEX_TRUE;
}

- (void)hideBubble: (NSMutableArray *)inArguments {
    for (uexBaiduMapAnnotation *annotation in self.annotations.allValues) {
        [self.currentMapView deselectAnnotation: annotation animated: YES];
    }
}

- (void)removeMakersOverlay: (NSMutableArray *)inArguments {
    ACArgsUnpack(NSArray* identifiers) = inArguments;
    UEX_PARAM_GUARD_NOT_NIL(identifiers);
    
    if (identifiers.count == 0) {
        [self removeAllAnnotations];
        return;
    }
    for (id aId in identifiers) {
        NSString * identifier = stringArg(aId);
        if (!identifier) {
            continue;
        }
        [self removeAnnotationWithIdentifier: identifier];
    }
}



- (BMKAnnotationView *)mapView: (BMKMapView *)mapView viewForAnnotation: (id <BMKAnnotation>)annotation {
    if (isUexBaiduMapAnnotation(annotation)) {
        uexBaiduMapAnnotation *uexAnnotation = (uexBaiduMapAnnotation *)annotation;
        return [uexAnnotation annotationViewForMap: mapView];
    }

    return nil;
}

/**
 *当选中一个annotation views时，调用此接口
 *@param mapView 地图View
 *@param views 选中的annotation views
 */

- (void)mapView: (BMKMapView *)mapView didSelectAnnotationView: (BMKAnnotationView *)view{
    id annotation = view.annotation;
    if (![annotation isKindOfClass: [uexBaiduMapCustomAnnotation class]]) {
        return;
    }
    NSString *identifier = [annotation identifier];
    if (!identifier) {
        return;
    }
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMakerClickListner" arguments: ACArgsPack(identifier)];
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMarkerClickListener" arguments: ACArgsPack(identifier)];
}

- (void)removeAllOverlays{
    for (NSString *identifier in self.overlays.allKeys) {
        [self removeOverlayWithIdentifier: identifier];
    }
}

- (void)removeOverlayWithIdentifier: (NSString *)identifier{
    if (!identifier) {
        return;
    }
    uexBaiduMapOverlay *overlay = self.overlays[identifier];
    if (!overlay) {
        return;
    }
    [self.currentMapView removeOverlay: overlay.bmkOverlay];
    [self.overlays removeObjectForKey: identifier];
}

- (void)addOverlay: (uexBaiduMapOverlay *)overlay{
    if (!overlay || !self.currentMapView) {
        return;
    }
    NSString *identifier = overlay.identifier;
    [self removeOverlayWithIdentifier: identifier];
    self.overlays[identifier] = overlay;
    [self.currentMapView addOverlay: overlay.bmkOverlay];
}



- (NSString *)addDotOverlay: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* info) = inArguments;
    uexBaiduMapDotOverlay *overlay = [[uexBaiduMapDotOverlay alloc]initWithInfoDictionary: info];
    [self addOverlay: overlay];
    return overlay.identifier;
}


//添加弧线覆盖物
- (NSString *)addArcOverlay: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* info) = inArguments;
    uexBaiduMapArcOverlay *overlay = [[uexBaiduMapArcOverlay alloc]initWithInfoDictionary: info];
    [self addOverlay: overlay];
    return overlay.identifier;
}

//添加线型覆盖物
- (NSString *)addPolylineOverlay: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* info) = inArguments;
    uexBaiduMapPolylineOverlay *overlay = [[uexBaiduMapPolylineOverlay alloc]initWithInfoDictionary: info];
    [self addOverlay: overlay];
    return overlay.identifier;
}

//添加圆型覆盖物
- (NSString *)addCircleOverlay: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* info) = inArguments;
    uexBaiduMapCircleOverlay *overlay = [[uexBaiduMapCircleOverlay alloc]initWithInfoDictionary: info];
    [self addOverlay: overlay];
    return overlay.identifier;
}

//添加多边型覆盖物
- (NSString *)addPolygonOverlay: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* info) = inArguments;
    uexBaiduMapPolygonOverlay *overlay = [[uexBaiduMapPolygonOverlay alloc]initWithInfoDictionary: info];
    [self addOverlay: overlay];
    return overlay.identifier;
}

//添加addGroundOverLayer
- (NSString *)addGroundOverlay: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary* info) = inArguments;
    uexBaiduMapGroundOverlay *overlay = [[uexBaiduMapGroundOverlay alloc]initWithInfoDictionary: info];
    NSString *imageURL = [self absPath: stringArg(info[@"imageUrl"])];
    UIImage *image;
    if ([[imageURL stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceCharacterSet].lowercaseString hasPrefix: @"http"]) {
        image = [UIImage imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString: imageURL]]];
    } else {
        image = [UIImage imageWithContentsOfFile: imageURL];
    }
    overlay.image = image;
    [self addOverlay: overlay];
    return overlay.identifier;
}

//添加文字覆盖物
//iOS 不支持
- (void)addTextOverLay: (NSMutableArray *) inArguments {
}

- (BMKOverlayView *)mapView: (BMKMapView *)mapView viewForOverlay: (id <BMKOverlay>)overlay{
    if ([overlay isKindOfClass: [BMKShape class]]) {
        BMKShape *shape = overlay;
        return [uexBaiduMapOverlay overlayOfShape: shape].overlayView;
    }
    return nil;
}


//清除覆盖物
- (void)removeOverlay: (NSMutableArray *)inArguments{
    if (inArguments.count == 0) {
        [self removeAllOverlays];
        return;
    }
    for (id arg in inArguments) {
            NSString *identifier = stringArg(arg);
        [self removeOverlayWithIdentifier: identifier];
    }
}

//************************地图操作******************************
/// 地图比例尺级别，在手机上当前可使用的级别为3-19级
- (void)setZoomLevel: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *level) = inArguments;
    float zoomLevel = level.floatValue;
    if (zoomLevel >= 3 && zoomLevel <= 21) {
        self.currentMapView.zoomLevel = zoomLevel;
    }
}
//地图旋转角度，在手机上当前可使用的范围为－180～180度
- (void)rotate: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *degree) = inArguments;
    if(degree){
        self.currentMapView.rotation = degree.intValue;
    }
    
}
//地图俯视角度，在手机上当前可使用的范围为－45～0度
- (void)overlook: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *degree) = inArguments;
    if(degree){
        self.currentMapView.overlooking = degree.intValue;
    }
}
//************************事件监听******************************

/**
 *当点击annotation view弹出的泡泡时，调用此接口
 *@param mapView 地图View
 *@param view 泡泡所属的annotation view
 */

- (void)mapView: (BMKMapView *)mapView annotationViewForBubble: (BMKAnnotationView *)view {
    id annotation = view.annotation;
    if (![annotation isKindOfClass: [uexBaiduMapCustomAnnotation class]]) {
        return;
    }
    NSString *identifier = [annotation identifier];
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMakerBubbleClickListner" arguments: ACArgsPack(identifier)];
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMarkerBubbleClickListener" arguments: ACArgsPack(identifier)];
}
/**
 *地图区域改变完成后会调用此接口
 *@param mapview 地图View
 *@param animated 是否动画
 */
- (void)mapView: (BMKMapView *)mapView regionDidChangeAnimated: (BOOL)animated {
    if (self.isFirstTime) {
        self.isFirstTime = NO;
        return;
    }
    double latitude = mapView.centerCoordinate.latitude;
    double longitude = mapView.centerCoordinate.longitude;
    float zoomLevel = mapView.zoomLevel;
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onZoomLevelChangeListener" arguments: ACArgsPack(@(zoomLevel),@(latitude),@(longitude))];
    [self.mapInfo update:mapView];
}
/**
 *点中底图标注后会回调此接口
 *@param mapview 地图View
 *@param mapPoi 标注点信息
 */
- (void)mapView: (BMKMapView *)mapView onClickedMapPoi: (BMKMapPoi*)mapPoi{

}

 
/**
 *点中底图空白处会回调此接口
 *@param mapview 地图View
 *@param coordinate 空白处坐标点的经纬度
 */
- (void)mapView: (BMKMapView *)mapView onClickedMapBlank: (CLLocationCoordinate2D)coordinate {
    NSDictionary *result = @{
                             @"longitude": @(coordinate.longitude),
                             @"latitude": @(coordinate.latitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMapClickListener" arguments: ACArgsPack(result.ac_JSONFragment)];
}

/**
 *双击地图时会回调此接口
 *@param mapview 地图View
 *@param coordinate 返回双击处坐标点的经纬度
 */
- (void)mapview: (BMKMapView *)mapView onDoubleClick: (CLLocationCoordinate2D)coordinate{
    
    NSDictionary *result = @{
                             @"longitude": @(coordinate.longitude),
                             @"latitude": @(coordinate.latitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMapDoubleClickListener" arguments: ACArgsPack(result.ac_JSONFragment)];
}

/**
 *长按地图时会回调此接口
 *@param mapview 地图View
 *@param coordinate 返回长按事件坐标点的经纬度
 */
- (void)mapview: (BMKMapView *)mapView onLongClick: (CLLocationCoordinate2D)coordinate{
    
    
    NSDictionary *result = @{
                             @"longitude": @(coordinate.longitude),
                             @"latitude": @(coordinate.latitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onMapLongClickListener" arguments: ACArgsPack(result.ac_JSONFragment)];
}
//增加地图手势监听(返回值包括缩放等级和中心点坐标)
//onMapStatusChange
- (void)mapStatusDidChanged:(BMKMapView *)mapView{
    [self.mapInfo update:mapView];
}

//************************UI控制******************************
///设定地图View能否支持用户多点缩放(双指)
- (void)setZoomEnable: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setZoomEnabled: enable];
}

///设定地图View能否支持用户缩放(双击或双指单击)
- (void)setZoomEnabledWithTap: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setZoomEnabledWithTap: enable];

}

///设定地图View能否支持用户移动地图
- (void)setScrollEnable: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setScrollEnabled: enable];
    
}
///设定地图View能否支持俯仰角
- (void)setOverlookEnable: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setOverlookEnabled: enable];

}
///设定地图View能否支持旋转
- (void)setRotateEnable: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    [self.currentMapView setRotateEnabled: enable];
    

}
//放大地图
- (void)zoomIn: (NSMutableArray *)inArguments{
    if (self.currentMapView) {
        [self.currentMapView zoomIn];
    }
}

//缩小地图
- (void)zoomOut: (NSMutableArray *)inArguments{
    if (self.currentMapView) {
        [self.currentMapView zoomOut];
    }
}

- (void)zoomToSpan: (NSMutableArray *)inArguments{

    ACArgsUnpack(NSNumber *lonNum,NSNumber *latNum) = inArguments;
    if (!latNum || !lonNum) {
        return;
    }
    BMKCoordinateRegion region;
    region.center = self.currentMapView.centerCoordinate;
    region.span.longitudeDelta = [lonNum doubleValue];
    region.span.latitudeDelta = [latNum doubleValue];
    [self.currentMapView setRegion: region animated: YES];
}

//将地图缩放到指定的矩形区域
- (void)zoomToBounds: (NSMutableArray *)inArguments{
    //
}
- (void)setCompassEnable: (NSMutableArray *)inArguments{
    BOOL isOpen = [inArguments.firstObject boolValue];
    if (isOpen) {
        self.currentMapView.compassPosition = self.positionOfCompass;
    } else {
        self.positionOfCompass = self.currentMapView.compassPosition;
        self.currentMapView.compassPosition = CGPointMake(-50, -50);
        
    }
    
}


/// 指南针的位置，设定坐标以BMKMapView左上角为原点，向右向下增长
- (void)setCompassPosition: (NSMutableArray *) inArguments{
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum) = inArguments;
    if (!xNum || !yNum) {
        return;
    }
    CGFloat x = [xNum floatValue];
    CGFloat y = [yNum floatValue];
    self.currentMapView.compassPosition = CGPointMake(x, y);
}
/// 设定是否显式比例尺
- (void)showMapScaleBar: (NSMutableArray *)inArguments{
    
    ACArgsUnpack(NSNumber *enableNum) = inArguments;
    if (!enableNum) {
        return;
    }
    BOOL enable = [enableNum boolValue];
    
    [self.currentMapView setShowMapScaleBar: enable];
}
- (void)setMapScaleBarPosition: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSNumber *xNum,NSNumber *yNum) = inArguments;
    if (!xNum || !yNum) {
        return;
    }
    float x = [xNum floatValue];
    float y = [yNum floatValue];
    [self.currentMapView setMapScaleBarPosition: CGPointMake(x, y)];
}
//************POI**************************

//setPoiPageCapacity设置搜索POI单页数据量
- (void)setPoiPageCapacity: (NSMutableArray *)inArguments{
    int pageCapacity = [inArguments.firstObject intValue];
    self.pageCapacity = pageCapacity;
}

- (NSNumber *)getPoiPageCapacity: (NSMutableArray *)inArguments{
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbGetPoiPageCapacity" arguments: ACArgsPack(@0,@2,@(self.pageCapacity))];
    return @(self.pageCapacity);

}

//poiSearchInCity 城市范围内搜索
- (void)poiSearchInCity: (NSMutableArray *)inArguments{

    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    NSString * city = stringArg(jsDic[@"city"]);
    NSString * keyword = stringArg(jsDic[@"searchKey"]);
    int pageIndex = [[jsDic objectForKey: @"pageNum"] intValue];
    BMKCitySearchOption * option = [[BMKCitySearchOption alloc]init];
    option.city = city;
    option.keyword = keyword;
    option.pageCapacity = self.pageCapacity;
    option.pageIndex = pageIndex;
    uexBaiduPOISearcher *searcher = [[uexBaiduPOISearcher alloc]init];
    searcher.mode = uexBaiduPOISearchModeCity;
    searcher.searchOption = option;
    [self.searchers addObject: searcher];
    [searcher searchWithCompletion: ^(id resultObj, NSInteger errorCode) {
        [self cbPOISearchResult: resultObj errorCode: (BMKSearchErrorCode)errorCode cbFunction: cb];
        [searcher dispose];
        [self.searchers removeObject: searcher];
        
    }];
}
//poiSearchNearBy 周边搜索
- (void)poiNearbySearch: (NSMutableArray *)inArguments{
    //key, longitude, latitude,radius, pageIndex
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    NSString * keyword = stringArg(jsDic[@"searchKey"]);
    double longitude = [[jsDic objectForKey: @"longitude"] doubleValue];
    double latitude = [[jsDic objectForKey: @"latitude"] doubleValue];
    int radius = [[jsDic objectForKey: @"radius"] intValue];
    int pageIndex = [[jsDic objectForKey: @"pageNum"] intValue];

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
    [self.searchers addObject: searcher];
    [searcher searchWithCompletion: ^(id resultObj, NSInteger errorCode) {
        [self cbPOISearchResult: resultObj errorCode: (BMKSearchErrorCode)errorCode cbFunction: cb];
        [searcher dispose];
        [self.searchers removeObject: searcher];
        
    }];
    
}

//poiSearchInBounds 区域内搜索
- (void)poiBoundSearch: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    NSString * keyword = [jsDic objectForKey: @"searchKey"];
    int pageIndex = [[jsDic objectForKey: @"pageNum"] intValue];
    double lbLongitude = [[[jsDic objectForKey: @"southwest"] objectForKey: @"longitude"] doubleValue];
    double lbLatitude = [[[jsDic objectForKey: @"southwest"] objectForKey: @"latitude"] doubleValue];
    double rtLongitude = [[[jsDic objectForKey: @"northeast"] objectForKey: @"longitude"] doubleValue];
    double rtLatitude = [[[jsDic objectForKey: @"northeast"] objectForKey: @"latitude"] doubleValue];
    
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
    [self.searchers addObject: searcher];
    [searcher searchWithCompletion: ^(id resultObj, NSInteger errorCode) {
        [self cbPOISearchResult: resultObj errorCode: (BMKSearchErrorCode)errorCode cbFunction: cb];
        [searcher dispose];
        [self.searchers removeObject: searcher];
        
    }];
}

//实现PoiSearchDeleage处理回调结果

- (void)cbPOISearchResult: (BMKPoiResult*)poiResult errorCode: (BMKSearchErrorCode)errorCode cbFunction: (ACJSFunctionRef *)cb{
    __block UEX_ERROR err = kUexNoError;
    __block NSMutableDictionary * resultDic = [NSMutableDictionary dictionary];
    @onExit{
        [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbPoiSearchResult" arguments: ACArgsPack(resultDic.ac_JSONFragment)];
        [cb executeWithArguments: ACArgsPack(err,resultDic)];
    };
    if (errorCode == BMK_SEARCH_AMBIGUOUS_KEYWORD){
        err = uexErrorMake(1,@"起始点有歧义");
        return;
    }
    
    if (errorCode != BMK_SEARCH_NO_ERROR) {
        err = uexErrorMake(errorCode,@"抱歉，未找到结果");
        return;
    }
    
    NSString * totalPoiNum = [NSString stringWithFormat: @"%d",poiResult.totalPoiNum];
    NSString * totalPageNum = [NSString stringWithFormat: @"%d",poiResult.pageNum];
    NSString * currentPageNum = [NSString stringWithFormat: @"%d",poiResult.currPoiNum];
    NSString * currentPageCapacity = [NSString stringWithFormat: @"%d",poiResult.pageIndex];
    NSMutableArray * poiInfoList = [NSMutableArray array];
    
    for (BMKPoiInfo * poiInfo in poiResult.poiInfoList) {
        NSString * epoitype = [NSString stringWithFormat: @"%d",poiInfo.epoitype];
        NSString * latitude = [NSString stringWithFormat: @"%f",poiInfo.pt.latitude];
        NSString * longitude = [NSString stringWithFormat: @"%f",poiInfo.pt.longitude];
        NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
        [tempDict setValue: poiInfo.uid forKey: @"uid"];
        [tempDict setValue: epoitype forKey: @"poiType"];
        [tempDict setValue: poiInfo.phone forKey: @"phoneNum"];
        [tempDict setValue: poiInfo.address forKey: @"address"];
        [tempDict setValue: poiInfo.name forKey: @"name"];
        [tempDict setValue: longitude forKey: @"longitude"];
        [tempDict setValue: latitude forKey: @"latitude"];
        [tempDict setValue: poiInfo.city forKey: @"city"];
        [tempDict setValue: poiInfo.postcode forKey: @"postCode"];
        [poiInfoList addObject: tempDict];
    }
    [resultDic setObject: totalPoiNum forKey: @"totalPoiNum"];
    [resultDic setObject: totalPageNum forKey: @"totalPageNum"];
    [resultDic setObject: currentPageNum forKey: @"currentPageNum"];
    [resultDic setObject: currentPageCapacity forKey: @"currentPageCapacity"];
    [resultDic setObject: poiInfoList forKey: @"poiInfo"];

}



//*****************线路规划**********************************
//busLineSearch公交线路搜索
- (void)busLineSearch: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    NSString *city = stringArg(info[@"city"]);
    NSString *busLineName = stringArg(info[@"busLineName"]);
    UEX_PARAM_GUARD_NOT_NIL(city);
    UEX_PARAM_GUARD_NOT_NIL(busLineName);
    uexBaiduBusLineSearcher *searcher = [[uexBaiduBusLineSearcher alloc] init];
    searcher.city = city;
    searcher.busLineName = busLineName;
    [self.searchers addObject: searcher];
    [searcher searchWithCompletion: ^(BMKBusLineResult *result, NSInteger errorCode) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        UEX_ERROR error = kUexNoError;
        if (errorCode != BMK_SEARCH_NO_ERROR) {
            dict = nil;
            error = uexErrorMake(errorCode);
        }else{
            [self addBusLineOverlaysAndAnnotationsWithSearchResult: result];
            dict[@"busCompany"] = result.busCompany;
            dict[@"busLineName"] = result.busLineName;
            dict[@"uid"] = result.uid;
            dict[@"startTime"] = result.startTime;
            dict[@"endTime"] = result.endTime;
            dict[@"isMonTicket"] = @(result.isMonTicket);
            NSMutableArray *stations = [NSMutableArray array];
            for ( BMKBusStation *station in result.busStations) {
                NSMutableDictionary *stationDict = [NSMutableDictionary dictionary];
                stationDict[@"title"] = station.title;
                stationDict[@"longitude"] = @(station.location.longitude);
                stationDict[@"latitude"] = @(station.location.latitude);
                [stations addObject: stationDict];
            }
            dict[@"busStations"] = stations;
        }
        [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbBusLineSearchResult" arguments: ACArgsPack(dict.ac_JSONFragment)];
        [callback executeWithArguments: ACArgsPack(dict,dict)];
        [searcher dispose];
        [self.searchers removeObject: searcher];
    }];
}

static NSString *const kBusLineObjectIdentifierPrefix = @"uexBaiduMap.busLine.";
- (void)removeBusLineObjects{
    for(NSString *identifier in self.annotations.allKeys) {
        if ([identifier hasPrefix: kBusLineObjectIdentifierPrefix]) {
            [self removeAnnotationWithIdentifier: identifier];
        }
    }
    for(NSString *identifier in self.overlays.allKeys) {
        if ([identifier hasPrefix: kBusLineObjectIdentifierPrefix]) {
            [self removeOverlayWithIdentifier: identifier];
        }
    }
}

- (void)addBusLineOverlaysAndAnnotationsWithSearchResult: (BMKBusLineResult *)result{
    [self removeBusLineObjects];
    NSString *(^getID)() = ^{
        return [kBusLineObjectIdentifierPrefix stringByAppendingString: UUID()];
    };
    
    //添加公交站点的Annotation
    for (BMKBusStation *station in result.busStations) {
        uexBaiduMapNodeAnnotation *annotation = [uexBaiduMapNodeAnnotation busNodeAnnotation];
        annotation.identifier = getID();
        annotation.coordinate = station.location;
        annotation.title = station.title;
        [self addAnnotation: annotation];
    }
    
    //添加公交线路的overlay
    uexBaiduMapPolylineOverlay *overlay = [[uexBaiduMapPolylineOverlay alloc]init];
    overlay.identifier = getID();
    overlay.fillColor = [UIColor colorWithRed: 0 green: 1 blue: 1 alpha: 1];
    overlay.lineWidth = 3;
    overlay.strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 1 alpha: 0.7];
    NSMutableArray<CLLocation *> *points = [NSMutableArray array];
    for (BMKBusStep *step in result.busSteps){
        for (NSInteger i = 0; i < step.pointsCount; i++){
            BMKMapPoint mapPoint = step.points[i];
            CLLocationCoordinate2D coordinate = BMKCoordinateForMapPoint(mapPoint);
            CLLocation *location = [[CLLocation alloc]initWithLatitude: coordinate.latitude longitude: coordinate.longitude];
            [points addObject: location];
        }
    }
    overlay.points = points;
    [self addOverlay: overlay];
    //设置地图中心点为起始站点
    BMKBusStation* start = result.busStations.firstObject;
    if (start) {
        [self.currentMapView setCenterCoordinate: start.location animated: YES];
    }
}


- (void)removeBusLine: (NSMutableArray *)inArguments {
    [self removeBusLineObjects];
}




- (void)removeRoutePlan: (NSMutableArray *)inArguments {
    ACArgsUnpack(NSString *identifier) = inArguments;
    [self removeRoutePlanObjectsWithIdentifier:identifier];
}

- (void)addRoutePlanObjectsWithResult:(uexBaiduMapRoutePlanResult *)result{
    if (!self.currentMapView || !result) {
        return;
    }
    NSString *identifier = result.identifier;
    if ([self.routePlanResults.allKeys containsObject:identifier]) {
        [self removeRoutePlanObjectsWithIdentifier:identifier];
    }
    [self addOverlay:result.associatedOverlay];
    for (uexBaiduMapNodeAnnotation *annotation in result.associatedAnnotations){
        [self addAnnotation:annotation];
    }
    [self.routePlanResults setValue:result forKey:identifier];
}
- (void)removeRoutePlanObjectsWithIdentifier: (NSString *)identifier{
    if (!self.currentMapView || !identifier) {
        return;
    }
    uexBaiduMapRoutePlanResult *result = self.routePlanResults[identifier];
    [self removeOverlayWithIdentifier: result.associatedOverlay.identifier];
    for (uexBaiduMapNodeAnnotation *annotation in result.associatedAnnotations){
        [self removeAnnotationWithIdentifier: annotation.identifier];
    }
    [self.routePlanResults removeObjectForKey: identifier];
}

- (NSString *)searchRoutePlan: (NSMutableArray *)inArguments {
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    UEX_PARAM_GUARD_NOT_NIL(info, nil);
    uexBaiduMapRoutePlanSearcher *searcher = [[uexBaiduMapRoutePlanSearcher alloc] initWithInfoDictionary: info];
    UEX_PARAM_GUARD_NOT_NIL(searcher, nil);
    NSString *identifier = searcher.identifier;
    [searcher searchWithCompletion: ^(uexBaiduMapRoutePlanResult *result, NSInteger errorCode) {
        UEX_ERROR e = kUexNoError;
        if (errorCode != BMK_SEARCH_NO_ERROR) {
            e = uexErrorMake(errorCode);
        }else{
            [self addRoutePlanObjectsWithResult:result];
        }
        [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onSearchRoutePlan" arguments: ACArgsPack(identifier,@(errorCode))];
        [callback executeWithArguments: ACArgsPack(@(errorCode))];
        [searcher dispose];
    }];
    return identifier;
    
}


//*****************地里编码**********************************
- (void)geocode: (NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }
    
    NSString * city = [jsDic objectForKey: @"city"];
    NSString * address = [jsDic objectForKey: @"address"];
    
    BMKGeoCodeSearchOption * geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
    geoCodeSearchOption.city = city;
    geoCodeSearchOption.address = address;

    uexBaiduGeoCodeSearcher *searcher = [[uexBaiduGeoCodeSearcher alloc]init];
    searcher.option = geoCodeSearchOption;
    [self.searchers addObject: searcher];
    [searcher searchWithCompletion: ^(id resultObj, NSInteger errorCode) {
        BMKGeoCodeResult *result = (BMKGeoCodeResult *)resultObj;
        if (errorCode != BMK_SEARCH_NO_ERROR) {
            [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbGeoCodeResult" arguments: ACArgsPack(@(errorCode))];
            [cb executeWithArguments: ACArgsPack(@(errorCode))];
        }else{
            NSDictionary *dict = @{
                                   @"longitude": @(result.location.longitude),
                                   @"latitude": @(result.location.latitude)
                                   };
            [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbGeoCodeResult" arguments: ACArgsPack(dict.ac_JSONFragment)];
            [cb executeWithArguments: ACArgsPack(@0,dict)];
        }
        [searcher dispose];
    }];
}






- (void)reverseGeocode: (NSMutableArray *) inArguments {
    
    ACArgsUnpack(NSDictionary *jsDic,ACJSFunctionRef *cb) = inArguments;
    if (!jsDic) {
        return;
    }

    
    double longitude = [[jsDic objectForKey: @"longitude"] doubleValue];
    double latitude = [[jsDic objectForKey: @"latitude"] doubleValue];
    CLLocationCoordinate2D pt = CLLocationCoordinate2DMake(latitude, longitude);


    BMKReverseGeoCodeOption * reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeoCodeSearchOption.reverseGeoPoint = pt;
    
    uexBaiduReverseGeocodeSearcher *searcher = [[uexBaiduReverseGeocodeSearcher alloc]init];
    searcher.option = reverseGeoCodeSearchOption;
    [self.searchers addObject: searcher];
    [searcher searchWithCompletion: ^(id resultObj, NSInteger errorCode) {
        BMKReverseGeoCodeResult *result = (BMKReverseGeoCodeResult *)resultObj;
        
        if (errorCode != BMK_SEARCH_NO_ERROR) {
            [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbReverseGeoCodeResult" arguments: ACArgsPack(@(errorCode))];
            [cb executeWithArguments: ACArgsPack(@(errorCode))];
        } else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue: result.address forKey: @"address"];
            [dict setValue: result.addressDetail.city forKey: @"city"];
            [dict setValue: result.addressDetail.streetName forKey: @"street"];
            [dict setValue: result.addressDetail.streetNumber forKey: @"streetNumber"];
            [dict setValue: result.addressDetail.province forKey: @"province"];
            [dict setValue: result.addressDetail.district forKey: @"district"];
            [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbReverseGeoCodeResult" arguments: ACArgsPack(dict.ac_JSONFragment)];
            [cb executeWithArguments: ACArgsPack(@0,dict)];
        }
    }];
}

//******************计算工具*****************************

//计算两点之间距离
- (NSNumber *)getDistance: (NSMutableArray*)inArguments{
    double lat1 = [[inArguments objectAtIndex: 0] doubleValue];
    double lon1 = [[inArguments objectAtIndex: 1] doubleValue];
    double lat2 = [[inArguments objectAtIndex: 2] doubleValue];
    double lon2 = [[inArguments objectAtIndex: 3] doubleValue];
    BMKMapPoint point1 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(lat1,lon1));
    BMKMapPoint point2 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(lat2,lon2));
    CLLocationDistance distance = BMKMetersBetweenMapPoints(point1,point2);

    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbGetDistance" arguments: ACArgsPack(@0,@1,@(distance))];
    return @(distance);
}

- (NSDictionary *)getCenter: (NSMutableArray*)inArguments{
    if (!self.currentMapView) {
        return nil;
    }
    NSDictionary *center = @{
                             @"latitude": @(self.currentMapView.centerCoordinate.latitude),
                             @"longitude": @(self.currentMapView.centerCoordinate.longitude)
                             };
    [self.webViewEngine callbackWithFunctionKeyPath: @"cbGetCenter" arguments: ACArgsPack(center.ac_JSONFragment)];
    return center;
}

//转换GPS坐标至百度坐标
- (void)getBaiduFromGPS: (NSMutableArray *)inArguments{
    CLLocationCoordinate2D locationCoord;
    if ([inArguments count] == 2) {
        locationCoord.longitude = [[inArguments objectAtIndex: 0] doubleValue];
        locationCoord.latitude = [[inArguments objectAtIndex: 1] doubleValue];
    }

    //BMK_COORDTYPE_GPS----->///GPS设备采集的原始GPS坐标
    NSDictionary * baidudict = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(locationCoord.latitude, locationCoord.longitude),BMK_COORDTYPE_GPS);
    CLLocationCoordinate2D lC2D = BMKCoorDictionaryDecode(baidudict);

    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbBaiduFromGPS" arguments: ACArgsPack(@(lC2D.latitude),@(lC2D.longitude))];

}

//转换 google地图、soso地图、aliyun地图、mapabc地图和amap地图所用坐标至百度坐标
- (void)getBaiduFromGoogle: (NSMutableArray *)inArguments{
    CLLocationCoordinate2D locationCoord;
    if ([inArguments count] == 2) {
        locationCoord.longitude = [[inArguments objectAtIndex: 0] doubleValue];
        locationCoord.latitude = [[inArguments objectAtIndex: 1] doubleValue];
    }

    NSDictionary * baidudict = BMKConvertBaiduCoorFrom(CLLocationCoordinate2DMake(locationCoord.latitude, locationCoord.longitude),BMK_COORDTYPE_COMMON);
    CLLocationCoordinate2D lC2D = BMKCoorDictionaryDecode(baidudict);


    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbBaiduFromGoogle" arguments: ACArgsPack(@(lC2D.latitude),@(lC2D.longitude))];
}
//******************定位*****************************


- (NSDictionary *)getLocationData{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    CLLocation *location = self.locationService.userLocation.location;
    dict[@"latitude"] = @(location.coordinate.latitude);
    dict[@"longitude"] = @(location.coordinate.longitude);
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"yyyy-MM-dd HH: mm: ss";
    dict[@"timestamp"] = [formatter stringFromDate: location.timestamp];
    return [dict copy];
}

- (void)getCurrentLocation: (NSMutableArray *)inArguments{
    
    ACArgsUnpack(ACJSFunctionRef *callback) = inArguments;
    
    if (!self.locationService) {
        self.locationService = [[BMKLocationService alloc]init];
    }
    if (!_didStartLocatingUser) {
        self.locationService.delegate = self;
        [self.locationService startUserLocationService];
        _isUpdateLocationOnce = YES;
        self.cbGetCurrentLocationFunc = callback;
    } else {
        NSDictionary *dict = [self getLocationData];
        [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbCurrentLocation" arguments: ACArgsPack(dict.ac_JSONFragment)];
        [callback executeWithArguments: ACArgsPack(kUexNoError,dict)];
    }
    
}

- (void)startLocation: (NSMutableArray *)inArguments {
    if (!self.locationService) {
        self.locationService = [[BMKLocationService alloc]init];
    }
    if (!_didStartLocatingUser) {
        self.locationService.delegate = self;
        [self.locationService startUserLocationService];
    }
    
}

- (void)stopLocation: (NSMutableArray *)inArguments {
    self.currentMapView.showsUserLocation = NO;
    if (self.locationService) {
        [self.locationService stopUserLocationService];
        self.locationService.delegate = nil;
    }
}

//显示当前位置
- (void)setMyLocationEnable: (NSMutableArray *)inArguments{
    BOOL isShow = NO;
    if ([inArguments count] > 0) {
        isShow = [[inArguments objectAtIndex: 0] boolValue];
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
    
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbStartLocation" arguments: ACArgsPack(@0,@2,@0)];
}

/**
 *在停止定位后，会调用此函数
 */
- (void)didStopLocatingUser{
    _didStartLocatingUser = NO;
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbStopLocation" arguments: ACArgsPack(@0,@2,@0)];
}

//处理方向变更信息
- (void)didUpdateUserHeading: (BMKUserLocation *)userLocation
{
    [self.currentMapView updateLocationData: userLocation];
}
/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation: (BMKUserLocation *)userLocation{
    NSDictionary *dict = [self getLocationData];
    if (_isUpdateLocationOnce) {
        _isUpdateLocationOnce = NO;
        [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.cbCurrentLocation" arguments: ACArgsPack(dict.ac_JSONFragment)];
        [self.cbGetCurrentLocationFunc executeWithArguments: ACArgsPack(kUexNoError, dict)];
        self.cbGetCurrentLocationFunc = nil;
        [self.locationService stopUserLocationService];
        return;
    }
    [self.webViewEngine callbackWithFunctionKeyPath: @"uexBaiduMap.onReceiveLocation" arguments: ACArgsPack(dict.ac_JSONFragment)];
    [self.currentMapView updateLocationData: userLocation];
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)didFailToLocateUserWithError: (NSError *)error{

}

- (void)setUserTrackingMode: (NSMutableArray *)inArguments {
//    BMKUserTrackingModeNone = 0,             /// 普通定位模式
//    BMKUserTrackingModeFollow,               /// 定位跟随模式
//    BMKUserTrackingModeFollowWithHeading,    /// 定位罗盘模式
    int mode = 0;//
    if ([inArguments count] >= 1) {
        mode = [[inArguments objectAtIndex: 0] intValue];
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

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    BMKIndoorFloorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FloorCell"];
    if (cell == nil) {
        cell = [[BMKIndoorFloorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FloorCell"];
    }
    
    NSString *title = [NSString stringWithFormat:@"%@",[_indoorMapInfoFocused.arrStrFloors objectAtIndex:indexPath.row]];
    cell.floorTitleLabel.text = title;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _indoorMapInfoFocused.arrStrFloors.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //进行楼层切换
    NSArray *annotationArray = [NSArray arrayWithArray:self.currentMapView.annotations];
    [self.currentMapView removeAnnotations:annotationArray];
    NSArray *overlayArray = [NSArray arrayWithArray:self.currentMapView.overlays];
    [self.currentMapView removeOverlays:overlayArray];
    BMKSwitchIndoorFloorError error = [self.currentMapView switchBaseIndoorMapFloor:[_indoorMapInfoFocused.arrStrFloors objectAtIndex:indexPath.row] withID:_indoorMapInfoFocused.strID];
    if (error == BMKSwitchIndoorFloorSuccess) {
        [tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        NSLog(@"切换楼层成功");
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark - BMKMapViewDelegate
/**
 *地图进入/移出室内图会调用此接口
 *@param mapview 地图View
 *@param flag  YES:进入室内图; NO:移出室内图
 *@param info 室内图信息
 */
-(void)mapview:(BMKMapView *)mapView baseIndoorMapWithIn:(BOOL)flag baseIndoorMapInfo:(BMKBaseIndoorMapInfo *)info
{
    BOOL showIndoor = NO;
    if (flag) {//进入室内图
        if (info != nil && info.arrStrFloors.count > 0) {
            _indoorMapInfoFocused.strID = info.strID;
            _indoorMapInfoFocused.strFloor = info.strFloor;
            _indoorMapInfoFocused.arrStrFloors = info.arrStrFloors;
            
            [_floorTableView reloadData];
            NSInteger index = [info.arrStrFloors indexOfObject:info.strFloor];
            [_floorTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            
            showIndoor = YES;
        }
    }
    
    _floorTableView.hidden = !showIndoor;
//    _searchView.hidden = !showIndoor;

}

@end
