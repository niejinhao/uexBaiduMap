//
//  RouteAnnotation.h
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/24.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "BMKPointAnnotation.h"

@interface RouteAnnotation : BMKPointAnnotation
{
    int _type; ///<0:起点 1：终点 2：公交 3：地铁 4:驾乘 5:途经点
    int _degree;
}

@property (nonatomic) int type;
@property (nonatomic) int degree;
@end
