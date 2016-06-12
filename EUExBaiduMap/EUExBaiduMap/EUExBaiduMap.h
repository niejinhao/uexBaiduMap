//
//  EUExBaiduMap.h
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/3.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^uexBaiduMapSearcherCompletionBlock)(id resultObj,NSInteger errorCode) ;


@protocol uexBaiduMapSearcher <NSObject>

- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion;
- (void)dispose;

@end



@interface EUExBaiduMap : EUExBase

@end
