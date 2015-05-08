//
//  BusLineObjct.h
//  EUExBaiduMap
//
//  Created by xurigan on 14/12/2.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EUExBaiduMap; 
#import "BMKMapView.h"

@interface BusLineObjct : NSObject

-(id)initWithuexObj:(EUExBaiduMap *)uexObj andMapView:(BMKMapView *)mapView andJson:(NSDictionary *)jsonDic;

-(void)doSearch;

-(void)remove;

@end
