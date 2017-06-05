/**
 *
 *	@file   	: uexBaiduMapRoutePlanSearcher.m  in EUExBaiduMap
 *
 *	@author 	: CeriNo
 * 
 *	@date   	: 2017/6/2
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


#import "uexBaiduMapRoutePlanSearcher.h"



@implementation uexBaiduMapRoutePlanResult
@end

@interface uexBaiduMapRoutePlanSearcher()<BMKRouteSearchDelegate>
@property (nonatomic, assign)uexBaiduMapRoutePlanType type;
@property (nonatomic, strong)BMKPlanNode *startNode;
@property (nonatomic, strong)BMKPlanNode *endNode;
@property (nonatomic, strong)BMKRouteSearch *routeSearch;
@property (nonatomic, strong)uexBaiduMapSearcherCompletionBlock completion;
@end

typedef uexBaiduMapNodeAnnotation * (^NodeAnnotationGenerateBlock)(__kindof BMKRouteStep *step);




@implementation uexBaiduMapRoutePlanSearcher

- (instancetype)initWithInfoDictionary:(NSDictionary *)info{
    self = [super init];
    if (!info || !self) {
        return nil;
    }
    NSNumber *typeNum = numberArg(info[@"type"]);
    if (!typeNum) {
        return nil;
    }
    _type = typeNum.integerValue;
    _startNode = [self nodeFromInfoDictionary:dictionaryArg(info[@"start"])];
    _endNode = [self nodeFromInfoDictionary:dictionaryArg(info[@"end"])];
    if (!_startNode || !_endNode) {
        return nil;
    }
    _identifier = stringArg(info[@"id"]) ?: UUID();
    _routeSearch = [[BMKRouteSearch alloc] init];
    _routeSearch.delegate = self;
    return self;
}

- (void)dispose{
    _routeSearch.delegate = nil;
    _routeSearch = nil;
}

- (BMKPlanNode *)nodeFromInfoDictionary:(NSDictionary *)info{
    if (!info) {
        return nil;
    }
    BMKPlanNode *node = [[BMKPlanNode alloc] init];
    NSNumber *latNum = numberArg(info[@"latitude"]);
    NSNumber *lonNum = numberArg(info[@"longitude"]);
    node.cityName = stringArg(info[@"city"]);
    node.name = stringArg(info[@"name"]);
    if (!latNum || !lonNum) {
        if (!node.cityName || !node.name) {
            return nil;
        }
        return node;
    }
    node.pt = CLLocationCoordinate2DMake(latNum.doubleValue, lonNum.doubleValue);
    return node;
}


- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion{
    self.completion = completion;
    BOOL ret;
    switch (self.type) {
        case uexBaiduMapRoutePlanTypeBus:{
            BMKTransitRoutePlanOption *option = [[BMKTransitRoutePlanOption alloc] init];
            option.city = self.startNode.cityName;
            option.from = self.startNode;
            option.to = self.endNode;
            ret = [self.routeSearch transitSearch:option];
        }
            break;
        case uexBaiduMapRoutePlanTypeDriving:{
            BMKDrivingRoutePlanOption *option = [[BMKDrivingRoutePlanOption alloc] init];
            option.from = self.startNode;
            option.to = self.endNode;
            ret = [self.routeSearch drivingSearch:option];
        }
            break;
        case uexBaiduMapRoutePlanTypeWalking:{
            BMKWalkingRoutePlanOption *option = [[BMKWalkingRoutePlanOption alloc] init];
            option.from = self.startNode;
            option.to = self.endNode;
            ret = [self.routeSearch walkingSearch:option];
        }
        break;
    }
    if (!ret) {
        [self failureCallback];
    }
}
- (void)failureCallback{
    [self errorCallback:BMK_SEARCH_RESULT_NOT_FOUND];
}

- (void)errorCallback:(BMKSearchErrorCode)errorCode{
    if (self.completion) {
        self.completion(nil, errorCode);
        self.completion = nil;
    }
}
- (void)successCallback:(uexBaiduMapRoutePlanResult *)result{
    if (self.completion) {
        self.completion(result, BMK_SEARCH_NO_ERROR);
        self.completion = nil;
    }
}

- (NSMutableArray<uexBaiduMapNodeAnnotation *> *)generateAnnotationsFromRouteLine:(__kindof BMKRouteLine *)plan withBlock:(NodeAnnotationGenerateBlock)block{
    
    NSMutableArray<uexBaiduMapNodeAnnotation *> *annotations = [NSMutableArray array];
    uexBaiduMapNodeAnnotation *start = [uexBaiduMapNodeAnnotation startNodeAnnotation];
    start.title = UEX_LOCALIZEDSTRING(@"起点");
    start.coordinate = plan.starting.location;
    [annotations addObject:start];
    uexBaiduMapNodeAnnotation *end = [uexBaiduMapNodeAnnotation endNodeAnnotation];
    end.title = UEX_LOCALIZEDSTRING(@"终点");
    end.coordinate = plan.terminal.location;
    [annotations addObject:end];
    for (BMKTransitStep *step in plan.steps){
        uexBaiduMapNodeAnnotation *annotation = block(step);
        [annotations addObject:annotation];
    }
    return annotations;
}

- (uexBaiduMapPolylineOverlay *)generateOverlayFromRouteLine:(__kindof BMKRouteLine *)plan{
    uexBaiduMapPolylineOverlay *overlay = [[uexBaiduMapPolylineOverlay alloc] init];
    overlay.identifier = UUID();
    overlay.fillColor = [UIColor colorWithRed:0 green:1 blue:1 alpha:1];
    overlay.strokeColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.7];
    overlay.lineWidth = 3;

    NSMutableArray<CLLocation *> *points = [NSMutableArray array];
    for (BMKRouteStep *step in plan.steps) {
        for (int i = 0; i < step.pointsCount; i++) {
            CLLocationCoordinate2D coordinate = BMKCoordinateForMapPoint(step.points[i]);
            [points addObject:[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude]];
        }
    }
    overlay.points = points;
    return overlay;
}

- (uexBaiduMapRoutePlanResult *)generateResultWithOverlay:(uexBaiduMapPolylineOverlay *)overlay
                                              annotations:(NSMutableArray<uexBaiduMapNodeAnnotation *> *)annotations
                                             resultObject:(id)resultObj{
    uexBaiduMapRoutePlanResult *result = [[uexBaiduMapRoutePlanResult alloc]init];
    result.identifier = self.identifier;
    result.searchResult = resultObj;
    result.associatedOverlay = overlay;
    result.associatedAnnotations = annotations;
    result.type = self.type;
    return result;
}

#pragma mark - BMKRouteSearchDelegate

- (void)onGetTransitRouteResult:(BMKRouteSearch*)searcher result:(BMKTransitRouteResult*)resultObj errorCode:(BMKSearchErrorCode)error{
    if (error != BMK_SEARCH_NO_ERROR) {
        [self errorCallback:error];
        return;
    }

    BMKTransitRouteLine * plan = resultObj.routes.firstObject;
    if (!plan) {
        [self failureCallback];
        return;
    }
    NSMutableArray<uexBaiduMapNodeAnnotation *> *annotations;
    annotations = [self generateAnnotationsFromRouteLine:plan withBlock:^uexBaiduMapNodeAnnotation *(BMKTransitStep *step) {
        uexBaiduMapNodeAnnotation *annotation;
        switch (step.stepType) {
            case BMK_BUSLINE:
                annotation = [uexBaiduMapNodeAnnotation busNodeAnnotation];
                break;
            case BMK_SUBWAY:
                annotation = [uexBaiduMapNodeAnnotation railNodeAnnotation];
                break;
            case BMK_WAKLING:
                annotation = [uexBaiduMapNodeAnnotation wayPointNodeAnnotation];
                break;
        }
        annotation.coordinate = step.entrace.location;
        annotation.title = step.instruction;
        return annotation;
    }];
    uexBaiduMapPolylineOverlay *overlay = [self generateOverlayFromRouteLine:plan];
    uexBaiduMapRoutePlanResult *result = [self generateResultWithOverlay:overlay annotations:annotations resultObject:resultObj];
    [self successCallback:result];
}

- (void)onGetDrivingRouteResult:(BMKRouteSearch*)searcher result:(BMKDrivingRouteResult*)resultObj errorCode:(BMKSearchErrorCode)error{
    if (error != BMK_SEARCH_NO_ERROR) {
        [self errorCallback:error];
        return;
    }
    
    BMKDrivingRouteLine * plan = resultObj.routes.firstObject;
    if (!plan) {
        [self failureCallback];
        return;
    }
    NSMutableArray<uexBaiduMapNodeAnnotation *> *annotations;
    annotations = [self generateAnnotationsFromRouteLine:plan withBlock:^uexBaiduMapNodeAnnotation *(BMKDrivingStep *step) {
        uexBaiduMapNodeAnnotation *annotation = [uexBaiduMapNodeAnnotation directionNodeAnnotationWithRotateDegree:step.direction * 30];
        annotation.title = step.entraceInstruction;
        annotation.coordinate = step.entrace.location;
        return annotation;
    }];
    for (BMKPlanNode* node in plan.wayPoints) {
        uexBaiduMapNodeAnnotation *annotation = [uexBaiduMapNodeAnnotation wayPointNodeAnnotation];
        annotation.coordinate = node.pt;
        annotation.title = node.name;
        [annotations addObject:annotation];
    }
    uexBaiduMapPolylineOverlay *overlay = [self generateOverlayFromRouteLine:plan];
    uexBaiduMapRoutePlanResult *result = [self generateResultWithOverlay:overlay annotations:annotations resultObject:resultObj];
    [self successCallback:result];
}

- (void)onGetWalkingRouteResult:(BMKRouteSearch*)searcher result:(BMKWalkingRouteResult*)resultObj errorCode:(BMKSearchErrorCode)error{
    if (error != BMK_SEARCH_NO_ERROR) {
        [self errorCallback:error];
        return;
    }
    
    BMKWalkingRouteLine * plan = resultObj.routes.firstObject;
    if (!plan) {
        [self failureCallback];
        return;
    }
    NSMutableArray<uexBaiduMapNodeAnnotation *> *annotations;
    annotations = [self generateAnnotationsFromRouteLine:plan withBlock:^uexBaiduMapNodeAnnotation *(BMKWalkingStep *step) {
        uexBaiduMapNodeAnnotation *annotation = [uexBaiduMapNodeAnnotation directionNodeAnnotationWithRotateDegree:step.direction * 30];
        annotation.title = step.entraceInstruction;
        annotation.coordinate = step.entrace.location;
        return annotation;
    }];
    uexBaiduMapPolylineOverlay *overlay = [self generateOverlayFromRouteLine:plan];
    uexBaiduMapRoutePlanResult *result = [self generateResultWithOverlay:overlay annotations:annotations resultObject:resultObj];
    [self successCallback:result];
}
@end
