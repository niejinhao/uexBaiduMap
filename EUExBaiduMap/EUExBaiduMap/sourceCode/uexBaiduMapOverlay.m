/**
 *
 *	@file   	: uexBaiduMapOverlay.m  in EUExBaiduMap
 *
 *	@author 	: CeriNo
 * 
 *	@date   	: 2017/5/31
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


#import "uexBaiduMapOverlay.h"
#import "uexBaiduMapBaseDefine.h"
#import <AppCanKit/AppCanKit.h>
#import <objc/runtime.h>


NS_ASSUME_NONNULL_BEGIN

static CLLocation * _Nullable locationFromData(id data){
    NSDictionary *dict = dictionaryArg(data);
    if (!dict) {
        return nil;
    }
    NSNumber *lat = numberArg(dict[@"latitude"]);
    NSNumber *lon = numberArg(dict[@"longitude"]);
    if (!lat || !lon) {
        return nil;
    }
    return [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lon.doubleValue];
}

static CLLocationCoordinate2D coordinateFromData(id data, NSString *latitudeKey, NSString *longitudeKey){
    NSNumber *lat = nil;
    NSNumber *lon = nil;
    NSDictionary *dict = dictionaryArg(data);
    if (dict) {
        lat = numberArg(dict[latitudeKey]);
        lon = numberArg(dict[longitudeKey]);
    }
    return CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue);
}

static UIColor * _Nullable colorFromData(id data){
    NSString *colorString = stringArg(data);
    if (!colorString) {
        return nil;
    }
    return [UIColor ac_ColorWithHTMLColorString:colorString];
}

static NSString *identifierFromData(id data){
    return stringArg(data) ?: UUID();
}

//返回的数组需要调用free进行释放
static CLLocationCoordinate2D *coordinatesFromLocations(NSArray<CLLocation *> *locations){
    CLLocationCoordinate2D * coordinates = malloc(sizeof(CLLocationCoordinate2D) * locations.count);
    for(NSInteger index = 0; index < locations.count; index++){
        coordinates[index] = locations[index].coordinate;
    }
    return coordinates;
}

@interface BMKShape(uexBaiduMap)
@property (nonatomic, strong)uexBaiduMapOverlay *uex_overlay;
@end
@implementation BMKShape(uexBaiduMap)
- (uexBaiduMapOverlay *)uex_overlay{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setUex_overlay:(uexBaiduMapOverlay *)uex_overlay{
    objc_setAssociatedObject(self, @selector(uex_overlay), uex_overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end


@implementation uexBaiduMapOverlay
- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info{
    UEX_PARAM_GUARD_NOT_NIL(info, nil);
    self = [super init];
    if (self) {
        _identidier = identifierFromData(info[@"id"]);
        _lineWidth = numberArg(info[@"lineWidth"]).floatValue;
        _strokeColor = colorFromData(info[@"strokeColor"]);
        _fillColor = colorFromData(info[@"fillColor"]);
    }
    return self;
}

- (BMKOverlayView *)overlayView{
    if (!_overlayView) {
        BMKOverlayGLBasicView *glOverlayView = [self makeGLOverlayView];
        if (glOverlayView) {
            glOverlayView.strokeColor = self.strokeColor;
            glOverlayView.lineWidth = self.lineWidth;
            glOverlayView.fillColor = self.fillColor;
            _overlayView = glOverlayView;
        } else {
            _overlayView = [self makeCustomOverlayView];
        }
    }
    return _overlayView;
}
- (id<BMKOverlay>)bmkOverlay{
    if (!_bmkOverlay) {
        BMKShape<BMKOverlay> *shape = [self makeBMKOverlay];
        shape.uex_overlay = self;
        _bmkOverlay = shape;
    }
    return _bmkOverlay;
}

+ (nullable instancetype)overlayOfShape:(BMKShape *)shape{
    return shape.uex_overlay;
}

#pragma mark -  for subclass to override
- (BMKOverlayGLBasicView *)makeGLOverlayView{
    return nil;
}
- (BMKOverlayView *)makeCustomOverlayView{
    return nil;
}
- (BMKShape<BMKOverlay> *)makeBMKOverlay{
    return nil;
}


@end


@implementation uexBaiduMapPolylineOverlay

- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info{
    self = [super initWithInfoDictionary:info];
    if (self) {
        NSMutableArray<CLLocation *> *points = [NSMutableArray array];
        NSArray *dataArray = arrayArg(info[@"property"]);
        for(id data in dataArray){
            CLLocation *point = locationFromData(data);
            if (point) {
                [points addObject:point];
            }
        }
        _points = [points copy];
        self.fillColor = self.fillColor ?: UIColor.blueColor;
        self.strokeColor = self.strokeColor ?: self.fillColor;
    }
    return self;
}

- (BMKShape<BMKOverlay> *)makeBMKOverlay{
    CLLocationCoordinate2D *coordinates = coordinatesFromLocations(self.points);
    BMKPolyline *polyline = [BMKPolyline polylineWithCoordinates:coordinates count:self.points.count];
    free(coordinates);
    return polyline;
}
- (BMKOverlayGLBasicView *)makeGLOverlayView{
    return [[BMKPolylineView alloc] initWithPolyline:self.bmkOverlay];
}

@end

@implementation uexBaiduMapArcOverlay

- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info{
    self = [super initWithInfoDictionary:info];
    if (self) {
        _startPoint = coordinateFromData(info, @"startLatitude", @"startLongitude");
        _midPoint = coordinateFromData(info, @"centerLatitude", @"centerLongitude");
        _endPoint = coordinateFromData(info, @"endLatitude", @"endLongitude");
    }
    return self;
}
- (BMKShape<BMKOverlay> *)makeBMKOverlay{
    CLLocationCoordinate2D coordinates[3];
    coordinates[0] = self.startPoint;
    coordinates[1] = self.midPoint;
    coordinates[2] = self.endPoint;
    return [BMKArcline arclineWithCoordinates:coordinates];
}
- (BMKOverlayGLBasicView *)makeGLOverlayView{
    return [[BMKArclineView alloc] initWithArcline:self.bmkOverlay];
}

@end

@implementation uexBaiduMapPolygonOverlay

- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info{
    self = [super initWithInfoDictionary:info];
    if (self) {
        NSMutableArray<CLLocation *> *points = [NSMutableArray array];
        NSArray *dataArray = arrayArg(info[@"property"]);
        for(id data in dataArray){
            CLLocation *point = locationFromData(data);
            if (point) {
                [points addObject:point];
            }
        }
        _points = [points copy];
    }
    return self;
}

- (BMKShape<BMKOverlay> *)makeBMKOverlay{
    CLLocationCoordinate2D *coordinates = coordinatesFromLocations(self.points);
    BMKPolygon *polygon = [BMKPolygon polygonWithCoordinates:coordinates count:self.points.count];
    free(coordinates);
    return polygon;
}
- (BMKOverlayGLBasicView *)makeGLOverlayView{
    return [[BMKPolygonView alloc] initWithPolygon:self.bmkOverlay];
}
@end

@implementation uexBaiduMapCircleOverlay
- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info{
    self = [super initWithInfoDictionary:info];
    if (self) {
        _radius = numberArg(info[@"radius"]).floatValue;
        _center = locationFromData(info).coordinate;
    }
    return self;
}
- (BMKShape<BMKOverlay> *)makeBMKOverlay{
    return [BMKCircle circleWithCenterCoordinate:self.center radius:self.radius];
}
- (BMKOverlayGLBasicView *)makeGLOverlayView{
    return [[BMKCircleView alloc] initWithCircle:self.bmkOverlay];
}

@end

@implementation uexBaiduMapDotOverlay
@end

@implementation uexBaiduMapGroundOverlay

- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info{
    self = [super initWithInfoDictionary:info];
    if (self) {
        NSMutableArray<CLLocation *> *points = [NSMutableArray array];
        NSArray *dataArray = arrayArg(info[@"property"]);
        for(id data in dataArray){
            CLLocation *point = locationFromData(data);
            if (point) {
                [points addObject:point];
            }
        }
        CLLocationCoordinate2D point1 = points.firstObject.coordinate;
        CLLocationCoordinate2D point2 = points.lastObject.coordinate;
        if(point1.latitude > point2.latitude){
            _bounds.northEast = point1;
            _bounds.southWest = point2;
        }else{
            _bounds.northEast = point2;
            _bounds.southWest = point1;
        }
    }
    return self;
}

- (BMKShape<BMKOverlay> *)makeBMKOverlay{
    return [BMKGroundOverlay groundOverlayWithBounds:self.bounds icon:self.image];
}

- (BMKOverlayView *)makeCustomOverlayView{
    return [[BMKGroundOverlayView alloc] initWithGroundOverlay:self.bmkOverlay];
}
@end

NS_ASSUME_NONNULL_END
