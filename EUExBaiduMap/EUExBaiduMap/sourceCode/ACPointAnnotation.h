//
//  MyPointAnnotation.h
//  EUExBaiduMapEx
//
//  Created by xurigan on 14-9-17.
//  Copyright (c) 2014年 com.appcan. All rights reserved.
//

#import "BMKPointAnnotation.h"

@interface ACPointAnnotation : BMKPointAnnotation

@property(nonatomic)CGSize imgSize;
@property(nonatomic,copy)NSString * pointId;
@property(nonatomic,copy)NSString * imageUrl;
@property(nonatomic,copy)NSString * iconUrl;

@end
