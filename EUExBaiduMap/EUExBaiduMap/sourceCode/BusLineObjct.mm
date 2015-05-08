//
//  BusLineObjct.m
//  EUExBaiduMap
//
//  Created by xurigan on 14/12/2.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "BusLineObjct.h"
#import "BMapKIt.h"
#import "JSON.h"
#import "MapUtility.h"
#import "ACPointAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import "BaiduMapManager.h"
#import "CustomPaoPaoView.h"
#import "BusLineAnnotation.h"
#import "RouteAnnotation.h"
#import <UIKit/UIKit.h>

@interface BusLineObjct()<BMKPoiSearchDelegate,BMKBusLineSearchDelegate>

@property (nonatomic, retain) EUExBaiduMap * uexObj;
@property (nonatomic, retain) BMKMapView * mapView;
@property (nonatomic, retain) NSDictionary * jsonDic;
@property (nonatomic, retain) NSMutableDictionary * overlayDataDic;
@property (nonatomic, retain) NSMutableArray * busPoiArray;
@property (nonatomic, retain) NSMutableArray * annotations;
@property (nonatomic, retain) NSMutableArray * overlayers;
@property (nonatomic, copy) NSString * searchCity;
@property (nonatomic, retain)BMKPoiSearch * POISearch;
@property (nonatomic, retain)BMKBusLineSearch * busLineSearch;

@end

@implementation BusLineObjct

-(id)initWithuexObj:(EUExBaiduMap *)uexObj andMapView:(BMKMapView *)mapView andJson:(NSDictionary *)jsonDic {
    
    if (self = [super init]) {
        self.uexObj = uexObj;
        self.mapView = mapView;
        self.jsonDic = jsonDic;
        self.annotations = [NSMutableArray array];
        self.overlayers = [NSMutableArray array];
    }
    return self;
    
}

-(void)doSearch {
    self.searchCity = [_jsonDic objectForKey:@"city"];
    NSString * busLine = [_jsonDic objectForKey:@"busLineName"];
    //_didBusLineSearch = YES;
    
    
    if (!self.busPoiArray) {
        self.busPoiArray = [NSMutableArray array];
    } else if ([_busPoiArray count] > 0){
        [_busPoiArray removeAllObjects];
    }
    
    BMKCitySearchOption *citySearchOption = [[BMKCitySearchOption alloc]init];
    citySearchOption.pageIndex = 0;
    citySearchOption.pageCapacity = 10;
    citySearchOption.city= _searchCity;
    citySearchOption.keyword = busLine;
    if (!_POISearch) {
        self.POISearch = [[BMKPoiSearch alloc]init];
        _POISearch.delegate = self;
    }
    BOOL flag = [_POISearch poiSearchInCity:citySearchOption];
    [citySearchOption release];
    if(flag)
    {
        NSLog(@"城市内检索发送成功");
    }
    else
    {
        NSLog(@"城市内检索发送失败");
    }

}

-(void)remove {
    [_mapView removeAnnotations:_annotations];
    [_annotations removeAllObjects];
    [_mapView removeOverlays:_overlayers];
    [_overlayers removeAllObjects];
}

-(void)onGetPoiResult:(BMKPoiSearch *)searcher result:(BMKPoiResult *)poiResult errorCode:(BMKSearchErrorCode)errorCode {
    //_didBusLineSearch = NO;
    
    BMKPoiInfo * poi = nil;
    BOOL findBusline = NO;
    
    for (int i = 0; i < poiResult.poiInfoList.count; i++) {
        
        poi = [poiResult.poiInfoList objectAtIndex:i];
        
        if (poi.epoitype == 2 || poi.epoitype == 4) {
            findBusline = YES;
            [_busPoiArray addObject:poi];
        }
    }
    //开始bueline详情搜索
    if(findBusline) {
        //_currentIndex = 0;
        NSString* strKey = ((BMKPoiInfo*) [_busPoiArray objectAtIndex:0]).uid;
        BMKBusLineSearchOption *buslineSearchOption = [[BMKBusLineSearchOption alloc]init];
        buslineSearchOption.city= _searchCity;
        buslineSearchOption.busLineUid= strKey;
        if (!self.busLineSearch) {
            _busLineSearch = [[BMKBusLineSearch alloc]init];
            _busLineSearch.delegate = self;
        }
        BOOL flag = [_busLineSearch busLineSearch:buslineSearchOption];
        [buslineSearchOption release];
        if(flag) {
            NSLog(@"busline检索发送成功");
        } else {
            NSLog(@"busline检索发送失败");
        }
        
    }
}

- (void)onGetBusDetailResult:(BMKBusLineSearch*)searcher result:(BMKBusLineResult*)busLineResult errorCode:(BMKSearchErrorCode)error {
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
        
        NSDictionary * cbDic = [NSDictionary dictionaryWithObjectsAndKeys:busCompany,@"busCompany",busLineName,@"busLineName",uid,@"uid",startTime,@"startTime",endTime,@"endTime",isMonTicket,@"isMonTicket",busStations,@"busStations", nil];
        
        NSString * cbStr = [cbDic JSONFragment];
        
        NSString * inCallbackName = @"uexBaiduMap.cbBusLineSearchResult";
        NSString * jsSuccessStr = [NSString stringWithFormat:@"if(%@!=null){%@(\'%@\');}",inCallbackName,inCallbackName,cbStr];
        
        //[_uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsSuccessStr];
        
        
        BusLineAnnotation* item = [[BusLineAnnotation alloc]init];
         
         //站点信息
         int size = 0;
         size = busLineResult.busStations.count;
         for (int j = 0; j < size; j++) {
         BMKBusStation* station = [busLineResult.busStations objectAtIndex:j];
         item = [[BusLineAnnotation alloc]init];
         item.coordinate = station.location;
         item.title = station.title;
         item.type = 2;
         [_mapView addAnnotation:item];
             [_annotations addObject:item];
         [item release];
         }
         
         
         //路段信息
         int index = 0;
         //累加index为下面声明数组temppoints时用
         for (int j = 0; j < busLineResult.busSteps.count; j++) {
         BMKBusStep* step = [busLineResult.busSteps objectAtIndex:j];
         index += step.pointsCount;
         }
         //直角坐标划线
         BMKMapPoint * temppoints = new BMKMapPoint[index];
         int k=0;
         for (int i = 0; i < busLineResult.busSteps.count; i++) {
         BMKBusStep* step = [busLineResult.busSteps objectAtIndex:i];
         for (int j = 0; j < step.pointsCount; j++) {
         BMKMapPoint pointarray;
         pointarray.x = step.points[j].x;
         pointarray.y = step.points[j].y;
         temppoints[k] = pointarray;
         k++;
         }
         }
         
         
         BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:index];
         [self.overlayDataDic setObject:@"busLine" forKey:@"id"];
         NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
         [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
         NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
         [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
         [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];
         [_mapView addOverlay:polyLine];
        [_overlayers addObject:polyLine];
         delete temppoints;
         
         BMKBusStation* start = [busLineResult.busStations objectAtIndex:0];
         [_mapView setCenterCoordinate:start.location animated:YES];
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}

@end
