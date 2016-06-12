//
//  SearchPlanObject.m
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/28.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "SearchPlanObject.h"
#import <BaiduMapAPI_Map/BMKMapView.h>

#import "MapUtility.h"
#import "ACPointAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import "BaiduMapManager.h"
#import "CustomPaoPaoView.h"
#import "BusLineAnnotation.h"
#import "RouteAnnotation.h"
#import <UIKit/UIKit.h>
#import "EUExBaiduMap.h"

@interface SearchPlanObject()<BMKRouteSearchDelegate>

@property (nonatomic, weak) EUExBaiduMap * uexObj;
@property (nonatomic, weak) BMKMapView * mapView;
@property (nonatomic, strong) NSDictionary * jsonDic;
@property (nonatomic, strong) BMKRouteSearch * routeSearch;
@property (nonatomic, strong) NSMutableDictionary * overlayDataDic;
@property (nonatomic, strong) NSMutableArray * annotations;
@property (nonatomic, strong) NSMutableArray * overlayers;
@property (nonatomic, strong) uexBaiduMapSearcherCompletionBlock completion;

@end

@implementation SearchPlanObject

//-(void)dealloc{
//    if (self.routeSearch) {
//        [self.routeSearch release];
//    }
//    
//    [super dealloc];
//}

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

-(void)remove {
    [self dispose];
    [_mapView removeAnnotations:_annotations];
    [_annotations removeAllObjects];
    [_mapView removeOverlays:_overlayers];
    [_overlayers removeAllObjects];
}


- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion{
    self.completion = completion;
    [self doSearch];
}
- (void)dealloc{
    [self dispose];
}

- (void)dispose{
    self.routeSearch.delegate = nil;
}

-(void)doSearch {
    
    
    int type = [[_jsonDic objectForKey:@"type"] intValue];
    
    NSDictionary * startDict = [_jsonDic objectForKey:@"start"];
    NSString * startCity = [startDict objectForKey:@"city"];
    NSString * startName = [startDict objectForKey:@"name"];
    NSString * startLongitude = [startDict objectForKey:@"longitude"];
    NSString * startLatitude = [startDict objectForKey:@"latitude"];
    
    NSDictionary * endDict = [_jsonDic objectForKey:@"end"];
    NSString * endCity = [endDict objectForKey:@"city"];
    NSString * endName = [endDict objectForKey:@"name"];
    NSString * endLongitude = [endDict objectForKey:@"longitude"];
    NSString * endLatitude = [endDict objectForKey:@"latitude"];
    
    
    CLLocationCoordinate2D startPt = (CLLocationCoordinate2D){0, 0};
    startPt.longitude = [startLongitude floatValue];
    startPt.latitude = [startLatitude floatValue];
    
    CLLocationCoordinate2D endPt = (CLLocationCoordinate2D){0, 0};
    endPt.longitude = [endLongitude floatValue];
    endPt.latitude = [endLatitude floatValue];
    
    BMKPlanNode * start = [[BMKPlanNode alloc]init];
    if ([startDict objectForKey:@"longitude"] && [startDict objectForKey:@"latitude"]) {
        start.pt = startPt;
    }
    if ([startDict objectForKey:@"city"] && [startDict objectForKey:@"name"]){
        start.cityName=startCity;
        start.name = startName;
    }
    
    BMKPlanNode * end = [[BMKPlanNode alloc]init];
    if ([endDict objectForKey:@"longitude"] && [endDict objectForKey:@"latitude"]) {
        end.pt = endPt;
    }
    if ([endDict objectForKey:@"city"] && [endDict objectForKey:@"name"]){
        end.cityName=endCity;
        end.name = endName;
    }
    BOOL flag = YES;
    switch (type) {
            
        case 0:{
            if (!self.routeSearch) {
                self.routeSearch = [[BMKRouteSearch alloc]init];
                self.routeSearch.delegate = self;
            }
            BMKDrivingRoutePlanOption * option = [[BMKDrivingRoutePlanOption alloc]init];
            option.from = start;
            option.to = end;
            //    option.wayPointsArray
            int policy = 0;
            switch (policy) {
                case BMK_DRIVING_BLK_FIRST://躲避拥堵(自驾)
                    option.drivingPolicy = BMK_DRIVING_BLK_FIRST;
                    break;
                case BMK_DRIVING_TIME_FIRST://最短时间(自驾)
                    option.drivingPolicy = BMK_DRIVING_TIME_FIRST;
                    break;
                case BMK_DRIVING_DIS_FIRST://最短路程(自驾)
                    option.drivingPolicy = BMK_DRIVING_DIS_FIRST;
                    break;
                case BMK_DRIVING_FEE_FIRST://少走高速(自驾)
                    option.drivingPolicy = BMK_DRIVING_FEE_FIRST;
                    break;
            }
            flag = [self.routeSearch drivingSearch:option];
            break;
        }
           
        case 1:{
            if (!self.routeSearch) {
                self.routeSearch = [[BMKRouteSearch alloc]init];
                self.routeSearch.delegate = self;
            }
            BMKTransitRoutePlanOption * option = [[BMKTransitRoutePlanOption alloc]init];
            option.city = start.cityName;
            option.from = start;
            option.to = end;
            int policy = 0;
            switch (policy) {
                case BMK_TRANSIT_TIME_FIRST://较快捷(公交)
                    option.transitPolicy=BMK_TRANSIT_TIME_FIRST;
                    break;
                case BMK_TRANSIT_TRANSFER_FIRST://少换乘(公交)
                    option.transitPolicy=BMK_TRANSIT_TRANSFER_FIRST;
                    break;
                case BMK_TRANSIT_WALK_FIRST://少步行(公交)
                    option.transitPolicy=BMK_TRANSIT_WALK_FIRST;
                    break;
                case BMK_TRANSIT_NO_SUBWAY://不坐地铁
                    option.transitPolicy=BMK_TRANSIT_NO_SUBWAY;
                    break;
            }
            
            flag = [self.routeSearch transitSearch:option];
            break;
        }
            
        case 2:{
            if (!self.routeSearch) {
                self.routeSearch = [[BMKRouteSearch alloc]init];
                self.routeSearch.delegate = self;
            }
            BMKWalkingRoutePlanOption * option = [[BMKWalkingRoutePlanOption alloc]init];
            option.from = start;
            option.to = end;
            
            flag = [self.routeSearch walkingSearch:option];
            break;
            
        }
            
    }
    
    if (!flag) {
        [self invokeCompletionBlockWithResult:nil errorCode:BMK_SEARCH_AMBIGUOUS_KEYWORD];
    }

}


- (void)invokeCompletionBlockWithResult:(id)result errorCode:(BMKSearchErrorCode)error{
    if(self.completion){
        self.completion(result,error);
        self.completion = nil;
    }
    
}

- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error{
    
    [self invokeCompletionBlockWithResult:result errorCode:error];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKDrivingRouteLine* plan = (BMKDrivingRouteLine*)[result.routes objectAtIndex:0];
        // 计算路线方案中的路段数目
        NSInteger size = [plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKDrivingStep* transitStep = [plan.steps objectAtIndex:i];
            if(i == 0){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.starting.location;
                item.title = UEX_LOCALIZEDSTRING(@"起点");
                item.type = 0;
                [_mapView addAnnotation:item]; // 添加起点标注
                [_annotations addObject:item];
//                [item release];
                
            }else if(i==size-1){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.terminal.location;
                item.title = UEX_LOCALIZEDSTRING(@"终点");
                item.type = 1;
                [_mapView addAnnotation:item]; // 添加终点标注
                [_annotations addObject:item];
//                [item release];
            }
            //添加annotation节点
            RouteAnnotation* item = [[RouteAnnotation alloc]init];
            item.coordinate = transitStep.entrace.location;
            item.title = transitStep.entraceInstruction;
            item.degree = transitStep.direction * 30;
            item.type = 4;
            [_mapView addAnnotation:item];
            [_annotations addObject:item];
//            [item release];
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        // 添加途经点
        if (plan.wayPoints) {
            for (BMKPlanNode* tempNode in plan.wayPoints) {
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item = [[RouteAnnotation alloc]init];
                item.coordinate = tempNode.pt;
                item.type = 5;
                item.title = tempNode.name;
                [_mapView addAnnotation:item];
                [_annotations addObject:item];
//                [item release];
            }
        }
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKDrivingStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [self.overlayDataDic setObject:@"Driving" forKey:@"id"];
        NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
        [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
        NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
        [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
        [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        [_overlayers addObject:polyLine];
        delete []temppoints;
        
        
    }
    
}

-(void)onGetWalkingRouteResult:(BMKRouteSearch *)searcher result:(BMKWalkingRouteResult *)result errorCode:(BMKSearchErrorCode)error{
    [self invokeCompletionBlockWithResult:result errorCode:error];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKWalkingRouteLine* plan = (BMKWalkingRouteLine*)[result.routes objectAtIndex:0];
        int size = (int)[plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKWalkingStep* transitStep = [plan.steps objectAtIndex:i];
            if(i==0){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.starting.location;
                item.title = UEX_LOCALIZEDSTRING(@"起点");
                item.type = 0;
                [_mapView addAnnotation:item]; // 添加起点标注
                [_annotations addObject:item];
//                [item release];
                
            }else if(i==size-1){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.terminal.location;
                item.title = UEX_LOCALIZEDSTRING(@"终点");
                item.type = 1;
                [_mapView addAnnotation:item]; // 添加起点标注
                [_annotations addObject:item];
//                [item release];
            }
            //添加annotation节点
            RouteAnnotation* item = [[RouteAnnotation alloc]init];
            item.coordinate = transitStep.entrace.location;
            item.title = transitStep.entraceInstruction;
            item.degree = transitStep.direction * 30;
            item.type = 4;
            [_mapView addAnnotation:item];
            [_annotations addObject:item];
//            [item release];
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKWalkingStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        
        [self.overlayDataDic setObject:@"Walking" forKey:@"id"];
        NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];//[MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
        [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
        NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
        [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
        [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];
        
        
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        [_overlayers addObject:polyLine];
        delete []temppoints;
        
        
    }
    
}



-(void)onGetTransitRouteResult:(BMKRouteSearch *)searcher result:(BMKTransitRouteResult *)result errorCode:(BMKSearchErrorCode)error{
    [self invokeCompletionBlockWithResult:result errorCode:error];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKTransitRouteLine* plan = (BMKTransitRouteLine*)[result.routes objectAtIndex:0];
        // 计算路线方案中的路段数目
        int size = (int)[plan.steps count];
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKTransitStep* transitStep = [plan.steps objectAtIndex:i];
            if(i==0){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.starting.location;
                item.title = UEX_LOCALIZEDSTRING(@"起点");
                item.type = 0;
                [_mapView addAnnotation:item]; // 添加起点标注
                [_annotations addObject:item];
//                [item release];
                
            }else if(i==size-1){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.terminal.location;
                item.title = UEX_LOCALIZEDSTRING(@"终点");
                item.type = 1;
                [_mapView addAnnotation:item]; // 添加起点标注
                [_annotations addObject:item];
//                [item release];
            }
            RouteAnnotation* item = [[RouteAnnotation alloc]init];
            item.coordinate = transitStep.entrace.location;
            item.title = transitStep.instruction;
            item.type = 3;
            [_mapView addAnnotation:item];
            [_annotations addObject:item];
//            [item release];
            
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }
        
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKTransitStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [self.overlayDataDic setObject:@"Transit" forKey:@"id"];
        NSString * fillColor = [MapUtility changeUIColorToRGB:[[UIColor cyanColor] colorWithAlphaComponent:1]];
        [self.overlayDataDic setObject:fillColor forKey:@"fillColor"];
        NSString * strokeColor = [MapUtility changeUIColorToRGB:[[UIColor blueColor] colorWithAlphaComponent:0.7]];
        [self.overlayDataDic setObject:strokeColor forKey:@"strokeColor"];
        [self.overlayDataDic setObject:@"3.0" forKey:@"lineWidth"];
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        [_overlayers addObject:polyLine];
        delete []temppoints;
    }
    
}

/*
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay{
    
    if ([overlay isKindOfClass:[BMKPolyline class]]){
        if (self.overlayDataDic == nil) {
            return nil;
        }
//        BMKPolylineView * polylineView = [[[BMKPolylineView alloc] initWithOverlay:overlay] autorelease];
        BMKPolylineView * polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[MapUtility getColor:[self.overlayDataDic objectForKey:@"fillColor"]] colorWithAlphaComponent:0.5];
        ;
        polylineView.strokeColor =  [[MapUtility getColor:[self.overlayDataDic objectForKey:@"fillColor"]] colorWithAlphaComponent:0.5];
        //[[MapUtility getColor:[self.overlayDataDic objectForKey:@"strokeColor"]] colorWithAlphaComponent:0.5];
        polylineView.lineWidth = [[self.overlayDataDic objectForKey:@"lineWidth"] floatValue];
        //NSString * idStr = [self.overlayDataDic objectForKey:@"id"];
        return polylineView;
    }
    
    return nil;
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
    return nil;
}



*/

@end
