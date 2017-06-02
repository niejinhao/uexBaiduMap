/**
 *
 *	@file   	: uexBaiduMapAnnotation.h  in EUExBaiduMap
 *
 *	@author 	: CeriNo
 * 
 *	@date   	: 2017/6/1
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




@protocol uexBaiduMapAnnotationProtocol <NSObject>
@property (nonatomic, strong)NSString *identifier;
- (BMKAnnotationView *)annotationViewForMap:(BMKMapView *)mapView;
@end

typedef BMKPointAnnotation<uexBaiduMapAnnotationProtocol> uexBaiduMapAnnotation;

FOUNDATION_STATIC_INLINE BOOL isUexBaiduMapAnnotation(id obj){
    return [obj isKindOfClass:[BMKPointAnnotation class]] && [obj conformsToProtocol:@protocol(uexBaiduMapAnnotationProtocol)];
}


@interface uexBaiduMapCustomAnnotation: uexBaiduMapAnnotation
@property (nonatomic, strong)NSString *identifier;
@property (nonatomic, strong)NSString *iconPath;
@property (nonatomic, strong)NSString *bubbleTitle;
@property (nonatomic, strong)NSString *bubbleImagePath;

@end

@interface uexBaiduMapNodeAnnotation: uexBaiduMapAnnotation
@property (nonatomic, strong)NSString *identifier;
+ (instancetype)startNodeAnnotation;
+ (instancetype)endNodeAnnotation;
+ (instancetype)busNodeAnnotation;
+ (instancetype)railNodeAnnotation;
+ (instancetype)directionNodeAnnotationWithRotateDegree:(CGFloat)degree;
+ (instancetype)wayPointNodeAnnotation;
@end


