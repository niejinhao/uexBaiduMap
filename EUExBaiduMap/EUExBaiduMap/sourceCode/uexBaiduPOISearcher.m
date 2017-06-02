/**
 *
 *	@file   	: uexBaiduPOISearcher.m  in EUExBaiduMap
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/6/12.
 *
 *	@copyright 	: 2016 The AppCan Open Source Project.
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

#import "uexBaiduPOISearcher.h"

@interface uexBaiduPOISearcher()<BMKPoiSearchDelegate>
@property (nonatomic, strong)BMKPoiSearch *POI;
@property (nonatomic, strong)uexBaiduMapSearcherCompletionBlock completion;
@end

@implementation uexBaiduPOISearcher


- (instancetype)init
{
    self = [super init];
    if (self) {
        _POI = [[BMKPoiSearch alloc]init];
        _POI.delegate = self;
    }
    return self;
}

- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion{
    self.completion = completion;
    switch (self.mode) {
        case uexBaiduPOISearchModeUnknown:{
            break;
        }
        case uexBaiduPOISearchModeNearby:{
            [self.POI poiSearchNearBy:self.searchOption];
            break;
        }
        case uexBaiduPOISearchModeCity:{
            [self.POI poiSearchInCity:self.searchOption];
            break;
        }
        case uexBaiduPOISearchModeBound:{
            [self.POI poiSearchInbounds:self.searchOption];
            break;
        }
    }
}

- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode{
    if (self.completion) {
        self.completion(poiResult,errorCode);
        self.completion = nil;
    }

 }


- (void)dispose{
    _POI.delegate = nil;
}


- (void)dealloc{
    [self dispose];
}

@end
