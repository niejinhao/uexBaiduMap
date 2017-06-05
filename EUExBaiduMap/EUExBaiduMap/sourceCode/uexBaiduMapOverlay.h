/**
 *
 *	@file   	: uexBaiduMapOverlay.h  in EUExBaiduMap
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


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface uexBaiduMapOverlay : NSObject
@property (nonatomic, strong)BMKOverlayView *overlayView;
@property (nonatomic, strong)id <BMKOverlay> bmkOverlay;
@property (nonatomic, strong)NSString *identifier;
@property (nonatomic, strong, nullable)UIColor *fillColor;
@property (nonatomic, strong, nullable)UIColor *strokeColor;
@property (nonatomic, assign)CGFloat lineWidth;
- (nullable instancetype)initWithInfoDictionary:(NSDictionary *)info;

+ (nullable instancetype)overlayOfShape:(BMKShape *)shape;
@end

@interface uexBaiduMapPolylineOverlay : uexBaiduMapOverlay
@property (nonatomic, strong)NSArray<CLLocation *> *points;
@end

@interface uexBaiduMapArcOverlay : uexBaiduMapOverlay
@property (nonatomic, assign)CLLocationCoordinate2D startPoint;
@property (nonatomic, assign)CLLocationCoordinate2D midPoint;
@property (nonatomic, assign)CLLocationCoordinate2D endPoint;

@end

@interface uexBaiduMapPolygonOverlay : uexBaiduMapOverlay
@property (nonatomic, strong)NSArray<CLLocation *> *points;
@end

@interface uexBaiduMapCircleOverlay : uexBaiduMapOverlay
@property (nonatomic, assign)CGFloat radius;
@property (nonatomic, assign)CLLocationCoordinate2D center;
@end

@interface uexBaiduMapDotOverlay : uexBaiduMapCircleOverlay
@end

@interface uexBaiduMapGroundOverlay : uexBaiduMapOverlay
@property (nonatomic, assign)CGFloat alpha;
@property (nonatomic, strong)UIImage *image;//默认不会进行初始化,需要单独赋值.
@property (nonatomic, assign)BMKCoordinateBounds bounds;
@property (nonatomic, strong)NSArray<CLLocation *> *points;
@end
NS_ASSUME_NONNULL_END


