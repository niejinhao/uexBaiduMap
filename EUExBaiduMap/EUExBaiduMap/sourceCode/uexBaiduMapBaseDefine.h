/**
 *
 *	@file   	: uexBaiduMapBaseDefine.h in EUExBaiduMap
 *
 *	@author 	: CeriNo
 *
 *	@date   	: Created on 17/5/31.
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
#ifndef uexBaiduMapBaseDefine_h
#define uexBaiduMapBaseDefine_h

typedef void (^uexBaiduMapSearcherCompletionBlock)(id resultObj,NSInteger errorCode) ;



@protocol uexBaiduMapSearcher <NSObject>

- (void)searchWithCompletion:(uexBaiduMapSearcherCompletionBlock)completion;
- (void)dispose;

@end

FOUNDATION_STATIC_INLINE NSString* UUID(){
    return [NSUUID UUID].UUIDString;
}

#endif /* uexBaiduMapBaseDefine_h */
