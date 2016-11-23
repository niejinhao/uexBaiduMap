//
//  BusLineObjct.h
//  EUExBaiduMap
//
//  Created by xurigan on 14/12/2.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Map/BMKMapView.h>
#import "EUExBaiduMap.h"


@interface BusLineObjct : NSObject<uexBaiduMapSearcher>

-(instancetype)initWithuexObj:(EUExBaiduMap *)uexObj andMapView:(BMKMapView *)mapView andJson:(NSDictionary *)jsonDic;



-(void)remove;

@end
