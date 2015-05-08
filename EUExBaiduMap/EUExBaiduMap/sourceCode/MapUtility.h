//
//  MapUtility.h
//  EUExBaiduMapEx
//
//  Created by xurigan on 14-9-17.
//  Copyright (c) 2014年 com.appcan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MapUtility : NSObject

+(UIColor *) getColor:(NSString *)hexColor;
+ (NSString *) changeUIColorToRGB:(UIColor *)color;
+ (NSString *)ToHex:(int)tmpid;

@end
