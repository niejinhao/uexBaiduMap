/**
 *
 *	@file   	: uexBaiduMapInfo.h  in EUExBaiduMap
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


@class EUExBaiduMap;
@class BMKMapView;

typedef void (^uexBaiduMapInfoChangeBlock)(NSDictionary *changeInfo);


@interface uexBaiduMapInfo: NSObject

@property (nonatomic, assign)CLLocationCoordinate2D center;
@property (nonatomic, assign)CLLocationCoordinate2D northeast;
@property (nonatomic, assign)CLLocationCoordinate2D southwest;
@property (nonatomic, assign)float zoom;
@property (nonatomic, assign)int overlook;
@property (nonatomic, assign)int rotate;

- (instancetype)initWithMap:(BMKMapView *)mapView onChange:(uexBaiduMapInfoChangeBlock)onChangeBlock;

- (void)update:(BMKMapView *)mapView;
@end
