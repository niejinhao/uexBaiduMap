//
//  BaiduMapManager.m
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/22.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "BaiduMapManager.h"


@implementation BaiduMapManager 

static BMKMapManager *DefaultManager = nil;

+ (BMKMapManager *)defaultManager {
    if (!DefaultManager) {
        DefaultManager = [[BMKMapManager alloc] init];
    }
    return DefaultManager;
}



@end
