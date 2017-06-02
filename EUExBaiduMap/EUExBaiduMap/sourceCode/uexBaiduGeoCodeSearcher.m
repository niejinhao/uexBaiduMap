/**
 *
 *	@file   	: uexBaiduGeoCodeSearcher.m  in EUExBaiduMap
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

#import "uexBaiduGeoCodeSearcher.h"
@interface uexBaiduGeoCodeSearcher()<BMKGeoCodeSearchDelegate>
@property (nonatomic, strong)uexBaiduMapSearcherCompletionBlock completion;
@property (nonatomic, strong)BMKGeoCodeSearch *geoCode;
@end
@implementation uexBaiduGeoCodeSearcher


- (instancetype)init{
    self = [super init];
    if (self) {
        _geoCode = [[BMKGeoCodeSearch alloc]init];
        _geoCode.delegate = self;
    }
    return self;
}

- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion{
    self.completion = completion;
    if (![self.geoCode geoCode:self.option]) {
        if (self.completion) {
            self.completion(nil,BMK_SEARCH_RESULT_NOT_FOUND);
            self.completion = nil;
        }
    }
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (self.completion) {
        self.completion(result,error);
        self.completion = nil;
    }
}


- (void)dispose{
    _geoCode.delegate = nil;
}

- (void)dealloc{
    [self dispose];
}

@end
