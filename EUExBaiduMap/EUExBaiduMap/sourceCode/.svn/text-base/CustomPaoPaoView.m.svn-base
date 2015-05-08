//
//  CustomPaoPaoView.m
//  EUExBaiduMap
//
//  Created by xurigan on 14/11/24.
//  Copyright (c) 2014年 com.zywx. All rights reserved.
//

#import "CustomPaoPaoView.h"

@implementation CustomPaoPaoView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        CGRect bgImageVFrame = frame;
        _bgImageView = [[UIImageView alloc]initWithFrame:bgImageVFrame];
        [self addSubview:_bgImageView];
        _title = [[UILabel alloc]init];
        _title.textAlignment = NSTextAlignmentCenter;
        _title.backgroundColor = [UIColor clearColor];
        [self addSubview:_title];
        
//        UIGestureRecognizer * tap = [[UIGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
//        [self addGestureRecognizer:tap];
        
    }
    return self;
}

-(void)tap{
    
}

-(void)dealloc{
    [_bgImageView release];
    [_title release];
    [super dealloc];
}

@end

@implementation UIImage(InternalMethod)

- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees
{
    
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
    CGSize rotatedSize;
    
    rotatedSize.width = width;
    rotatedSize.height = height;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    CGContextRotateCTM(bitmap, degrees * M_PI / 180);
    CGContextRotateCTM(bitmap, M_PI);
    CGContextScaleCTM(bitmap, -1.0, 1.0);
    CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width/2, -rotatedSize.height/2, rotatedSize.width, rotatedSize.height), self.CGImage);
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
