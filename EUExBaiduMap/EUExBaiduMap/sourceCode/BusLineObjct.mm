/**
 *
 *	@file   	: BusLineObjct.m in EUExBaiduMap
 *
 *	@author 	: CeriNo
 *
 *	@date   	: Created on 17/5/31.
 *
 *	@copyright 	: 2017 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
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

#import "BusLineObjct.h"
#import <BaiduMapAPI_Map/BMKMapView.h>

#import "MapUtility.h"
#import "ACPointAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import "BaiduMapManager.h"
#import "CustomPaoPaoView.h"
#import "BusLineAnnotation.h"
#import "RouteAnnotation.h"
#import <UIKit/UIKit.h>

@interface BusLineObjct()<BMKPoiSearchDelegate,BMKBusLineSearchDelegate>

@property (nonatomic, weak) EUExBaiduMap * uexObj;
@property (nonatomic, weak) BMKMapView * mapView;
@property (nonatomic, strong) NSDictionary * jsonDic;
@property (nonatomic, strong) NSMutableDictionary * overlayDataDic;
@property (nonatomic, strong) NSMutableArray * busPoiArray;
@property (nonatomic, strong) NSMutableArray * annotations;
@property (nonatomic, strong) NSMutableArray * overlayers;
@property (nonatomic, strong) NSString * searchCity;
@property (nonatomic, strong)BMKPoiSearch * POISearch;
@property (nonatomic, strong)BMKBusLineSearch * busLineSearch;
@property ((nonatomic ,strong))uexBaiduMapSearcherCompletionBlock completion;

@end

@implementation BusLineObjct

- (instancetype)initWithuexObj:(EUExBaiduMap *)uexObj andMapView:(BMKMapView *)mapView andJson:(NSDictionary *)jsonDic {
    
    if (self = [super init]) {
        self.uexObj = uexObj;
        self.mapView = mapView;
        self.jsonDic = jsonDic;
        self.annotations = [NSMutableArray array];
        self.overlayers = [NSMutableArray array];
    }
    return self;
    
}

- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion{
    self.completion = completion;
    [self doSearch];
}


- (void)dispose{
    self.POISearch.delegate = nil;
    self.busLineSearch.delegate = nil;
}

- (void)dealloc{
    [self dispose];
}

- (void)doSearch {
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
    if (!self.POISearch) {
        self.POISearch = [[BMKPoiSearch alloc]init];
        self.POISearch.delegate = self;
    }
    if (![_POISearch poiSearchInCity:citySearchOption]){
        NSLog(@"城市内检索发送失败");
        if (self.completion) {
            self.completion(nil,BMK_SEARCH_AMBIGUOUS_KEYWORD);
            self.completion = nil;
            
        }
        
    }
    
    
}

- (void)remove {
    [self dispose];
    [_mapView removeAnnotations:_annotations];
    [_annotations removeAllObjects];
    [_mapView removeOverlays:_overlayers];
    [_overlayers removeAllObjects];
}

- (void)onGetPoiResult:(BMKPoiSearch *)searcher result:(BMKPoiResult *)poiResult errorCode:(BMKSearchErrorCode)errorCode {
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
        if(![_busLineSearch busLineSearch:buslineSearchOption]){
            if (self.completion) {
                self.completion(nil,BMK_SEARCH_AMBIGUOUS_KEYWORD);
                self.completion = nil;
                
            }
        }
    }
}

- (void)onGetBusDetailResult:(BMKBusLineSearch*)searcher result:(BMKBusLineResult*)busLineResult errorCode:(BMKSearchErrorCode)error {
    
    if (self.completion) {
        self.completion(busLineResult,error);
        self.completion = nil;
        
    }
    if (error == BMK_SEARCH_NO_ERROR) {
        
        
        //[_uexObj.meBrwView stringByEvaluatingJavaScriptFromString:jsSuccessStr];
        
        
        BusLineAnnotation* item = [[BusLineAnnotation alloc]init];
        
        //站点信息
        NSInteger size = busLineResult.busStations.count;
        
        for (int j = 0; j < size; j++) {
            BMKBusStation* station = [busLineResult.busStations objectAtIndex:j];
            item = [[BusLineAnnotation alloc]init];
            item.coordinate = station.location;
            item.title = station.title;
            item.type = 2;
            [_mapView addAnnotation:item];
            [_annotations addObject:item];
            
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
        delete[] temppoints;
        
        BMKBusStation* start = [busLineResult.busStations objectAtIndex:0];
        [_mapView setCenterCoordinate:start.location animated:YES];
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}

@end
