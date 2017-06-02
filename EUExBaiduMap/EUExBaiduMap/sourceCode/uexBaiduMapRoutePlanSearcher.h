/**
 *
 *	@file   	: uexBaiduMapRoutePlanSearcher.h  in EUExBaiduMap
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


#import <Foundation/Foundation.h>
#import "uexBaiduMapBaseDefine.h"
#import "uexBaiduMapAnnotation.h"
#import "uexBaiduMapOverlay.h"
typedef NS_ENUM(NSInteger, uexBaiduMapRoutePlanType) {
    uexBaiduMapRoutePlanTypeDriving = 0,
    uexBaiduMapRoutePlanTypeBus,
    uexBaiduMapRoutePlanTypeWalking
};


NS_ASSUME_NONNULL_BEGIN



@interface uexBaiduMapRoutePlanResult : NSObject
@property (nonatomic, strong)NSString *identifier;
@property (nonatomic, assign)uexBaiduMapRoutePlanType type;
@property (nonatomic, strong)NSMutableArray<uexBaiduMapNodeAnnotation *> *associatedAnnotations;
@property (nonatomic, strong)uexBaiduMapPolylineOverlay *associatedOverlay;
@property (nonatomic, strong)id searchResult;
@end

@interface uexBaiduMapRoutePlanSearcher: NSObject<uexBaiduMapSearcher>
@property (nonatomic, strong)NSString *identifier;
- (instancetype)initWithInfoDictionary:(NSDictionary *)info;
@end

NS_ASSUME_NONNULL_END
