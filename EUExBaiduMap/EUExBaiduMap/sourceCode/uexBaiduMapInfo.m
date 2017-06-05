/**
 *
 *	@file   	: uexBaiduMapInfo.m  in EUExBaiduMap
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


#import "uexBaiduMapInfo.h"
#import "uexBaiduMapBaseDefine.h"


@interface uexBaiduMapInfo()
@property (nonatomic, strong)uexBaiduMapInfoChangeBlock onChangeBlock;
@property (nonatomic, strong)NSMutableDictionary *changeData;
@end
@implementation uexBaiduMapInfo


- (instancetype)initWithMap:(BMKMapView *)mapView onChange:(uexBaiduMapInfoChangeBlock)onChangeBlock{
    self = [super init];
    if (self) {
        [self update:mapView];
        _onChangeBlock = onChangeBlock;
    }
    return self;
}

- (void)update:(BMKMapView *)mapView{
    self.changeData = [NSMutableDictionary dictionary];
    self.center = mapView.centerCoordinate;
    [self updateRegion:mapView.region];
    self.zoom = mapView.zoomLevel;
    self.overlook = mapView.overlooking;
    self.rotate = mapView.rotation;
    if (self.changeData.count > 0 && self.onChangeBlock) {
        self.onChangeBlock(self.changeData);
    }
}
- (void)updateRegion:(BMKCoordinateRegion)region{
    self.southwest = CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta, region.center.longitude - region.span.longitudeDelta);
    self.northeast = CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta, region.center.longitude + region.span.longitudeDelta);
}

- (void)setRotate:(int)rotate{
    if (rotate == _rotate) {
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"oldRotate"] = @(_rotate);
    dict[@"newRotate"] = @(rotate);
    _rotate = rotate;
    self.changeData[@"rotate"] = dict;
}

- (void)setZoom:(float)zoom{
    if (zoom == _zoom) {
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"oldZoom"] = @(_zoom);
    dict[@"newZoom"] = @(zoom);
    _zoom = zoom;
    self.changeData[@"zoom"] = dict;
}
- (void)setOverlook:(int)overlook{
    if (overlook == _overlook) {
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"oldOverlook"] = @(_overlook);
    dict[@"newOverlook"] = @(overlook);
    _overlook = overlook;
    self.changeData[@"overlook"] = dict;
}


FOUNDATION_STATIC_INLINE BOOL CLLocationCoordinate2DIsEqual(CLLocationCoordinate2D c1, CLLocationCoordinate2D c2){
    return c1.longitude == c2.longitude && c1.latitude == c2.latitude;
}

FOUNDATION_STATIC_INLINE NSDictionary * dictFromCoordinate(CLLocationCoordinate2D coordinate){
    return @{
             @"longitude": @(coordinate.longitude),
             @"latitude": @(coordinate.latitude)
             };
}
- (void)setCenter:(CLLocationCoordinate2D)center{
    if (CLLocationCoordinate2DIsEqual(center, _center)) {
        return;
    }
    _center = center;
    self.changeData[@"center"] = dictFromCoordinate(center);
}
- (void)setNortheast:(CLLocationCoordinate2D)northeast{
    if (CLLocationCoordinate2DIsEqual(northeast, _northeast)) {
        return;
    }
    _northeast = northeast;
    self.changeData[@"northeast"] = dictFromCoordinate(northeast);
}
- (void)setSouthwest:(CLLocationCoordinate2D)southwest{
    if (CLLocationCoordinate2DIsEqual(southwest, _southwest)) {
        return;
    }
    _southwest = southwest;
    self.changeData[@"southwest"] = dictFromCoordinate(southwest);
    
}

@end
