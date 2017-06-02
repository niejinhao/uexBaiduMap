/**
 *
 *	@file   	: uexBaiduBusLineSearcher.m  in EUExBaiduMap
 *
 *	@author 	: CeriNo
 * 
 *	@date   	: 2017/6/1
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


#import "uexBaiduBusLineSearcher.h"

@interface uexBaiduBusLineSearcher()<BMKPoiSearchDelegate,BMKBusLineSearchDelegate>
@property (nonatomic, strong)BMKPoiSearch *poiSearch;
@property (nonatomic, strong)BMKBusLineSearch *busLineSearch;
@property (nonatomic, strong)uexBaiduMapSearcherCompletionBlock completion;
@end
@implementation uexBaiduBusLineSearcher

- (instancetype)init{
    self = [super init];
    if (self) {
        _poiSearch = [[BMKPoiSearch alloc] init];
        _poiSearch.delegate = self;
        _busLineSearch = [[BMKBusLineSearch alloc] init];
        _busLineSearch.delegate = self;
    }
    return self;
}

- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion{
    self.completion = completion;
    BMKCitySearchOption *option = [[BMKCitySearchOption alloc]init];
    option.city = self.city;
    option.keyword = self.busLineName;
    if (![self.poiSearch poiSearchInCity:option]){
        [self failureCallback];
    }
}


- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult *)poiResult errorCode:(BMKSearchErrorCode)errorCode{
    if (errorCode != BMK_SEARCH_NO_ERROR) {
        [self errorCallback:errorCode];
        return;
    }
    BMKPoiInfo *busLineInfo = nil;
    for (BMKPoiInfo *info in poiResult.poiInfoList) {
        if (info.epoitype == 2 || info.epoitype == 4) {
            busLineInfo = info;
            break;
        }
    }
    if (!busLineInfo) {
        [self failureCallback];
        return;
    }
    BMKBusLineSearchOption *option = [[BMKBusLineSearchOption alloc]init];
    option.city = self.city;
    option.busLineUid = busLineInfo.uid;
    if (![self.busLineSearch busLineSearch:option]) {
        [self failureCallback];
    }
}
- (void)onGetBusDetailResult:(BMKBusLineSearch*)searcher result:(BMKBusLineResult*)busLineResult errorCode:(BMKSearchErrorCode)errorCode{
    if (errorCode != BMK_SEARCH_NO_ERROR) {
        [self errorCallback:errorCode];
    } else {
        [self successCallback:busLineResult];
    }
    
}




- (void)failureCallback{
    [self errorCallback:BMK_SEARCH_RESULT_NOT_FOUND];
}

- (void)errorCallback:(BMKSearchErrorCode)errorCode{
    if (self.completion) {
        self.completion(nil, errorCode);
        self.completion = nil;
    }
}
- (void)successCallback:(BMKBusLineResult *)searchResult{
    if (self.completion) {
        self.completion(searchResult, BMK_SEARCH_NO_ERROR);
        self.completion = nil;
    }
}

- (void)dispose{
    _poiSearch.delegate = nil;
    _busLineSearch.delegate = nil;
}
@end
