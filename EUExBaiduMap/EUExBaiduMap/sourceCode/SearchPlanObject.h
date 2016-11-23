//
//  SearchPlanObject.h
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/28.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUExBaiduMap.h"
#import <BaiduMapAPI_Map/BMKMapView.h>

@interface SearchPlanObject : NSObject<uexBaiduMapSearcher>

-(id)initWithuexObj:(EUExBaiduMap *)uexObj andMapView:(BMKMapView *)mapView andJson:(NSDictionary *)jsonDic;



-(void)remove;

@end
