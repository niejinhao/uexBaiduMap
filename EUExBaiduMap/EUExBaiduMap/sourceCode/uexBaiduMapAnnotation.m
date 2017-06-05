/**
 *
 *	@file   	: uexBaiduMapAnnotation.m  in EUExBaiduMap
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


#import "uexBaiduMapAnnotation.h"
#import "uexBaiduMapBaseDefine.h"

@interface uexBaiduMapCustomAnnotation()
@end
@implementation uexBaiduMapCustomAnnotation


- (UIImage *)imageWithPath:(NSString *)path{
    if (!path) {
        return nil;
    }
    if ([[path stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString hasPrefix:@"http"]) {
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:path] ];
        return [[UIImage alloc] initWithData:imageData];
    }else {
        return [UIImage imageWithContentsOfFile:path];
    }
}

- (BMKAnnotationView *)annotationViewForMap:(BMKMapView *)mapView{
    NSString *reuseIdentifier = @"uexBaiduMap.CustomAnnotation";
    BMKPinAnnotationView *view = (BMKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];
    if (!view) {
        view = [[BMKPinAnnotationView alloc]initWithAnnotation:self reuseIdentifier:reuseIdentifier];
    }
    view.annotation = self;
    UIImage *iconImage = [self imageWithPath:self.iconPath];
    if (iconImage) {
        view.image = iconImage;
    } else {
        view.pinColor = BMKPinAnnotationColorPurple;
    }
    UIImage *bubbleImage = [self imageWithPath:self.bubbleImagePath];
    if (bubbleImage) {
        BMKActionPaopaoView *paopaoView = [[BMKActionPaopaoView alloc]initWithCustomView:[self bubbleViewWithImage:bubbleImage]];
        view.paopaoView = paopaoView;
        view.canShowCallout = YES;
    }else{
        view.canShowCallout = NO;
    }
    view.animatesDrop = NO;
    view.draggable = NO;
    
    return view;
}

- (UIView *)bubbleViewWithImage:(UIImage *)bubbleImage{
    UIImageView *view = [[UIImageView alloc]initWithImage:bubbleImage];
    if (self.bubbleTitle) {
        UILabel *label = [[UILabel alloc] init];
        CGRect bounds = [self.bubbleTitle boundingRectWithSize:CGSizeMake(view.bounds.size.width, MAXFLOAT) options:0 attributes:nil context:nil];
        label.text = self.bubbleTitle;
        label.frame = bounds;
        [view addSubview:label];
        label.center = view.center;
    }
    return view;
}

@end

@interface uexBaiduMapNodeData : NSObject
@property (nonatomic, strong)NSString *reuseIdentifier;
@property (nonatomic, strong)NSString *iconPath;
@property (nonatomic, assign)BOOL canShowCallout;
@property (nonatomic, assign)BOOL iconNeedRotate;
@property (nonatomic, assign)CGFloat rotateDegree;
@property (nonatomic, assign)BOOL iconNeedOffset;
@property (nonatomic, assign)CGPoint offsetRatio;

@property (nonatomic, readonly)BOOL isStaticIcon;
@property (nonatomic, readonly)UIImage *icon;
@end

@implementation uexBaiduMapNodeData
- (instancetype)init{
    self = [super init];
    if (self) {
        _canShowCallout = YES;
        _offsetRatio = CGPointMake(0, -0.5);
    }
    return self;
}

- (void)setBundleImagePath:(NSString *)subPath{
    NSString * bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"mapapi.bundle"];
    NSBundle * bundle = [NSBundle bundleWithPath: bundlePath] ;
    self.iconPath = [bundle.resourcePath stringByAppendingPathComponent:subPath];
}

- (BOOL)isStaticIcon{
    return !self.iconNeedRotate;
}

- (UIImage *)icon{
    UIImage *icon = [UIImage imageWithContentsOfFile:self.iconPath];
    if (!icon) {
        return nil;
    }
    if (self.iconNeedRotate) {
        icon = [self rotateImage:icon];
    }
    return icon;
}

- (UIImage *)rotateImage:(UIImage *)origin{
    CGImageRef cgImage = origin.CGImage;
    CGFloat width = CGImageGetWidth(cgImage);
    CGFloat height = CGImageGetHeight(cgImage);
    CGSize rotatedSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
    CGContextRotateCTM(bitmap, self.rotateDegree * M_PI / 180);
    CGContextRotateCTM(bitmap, M_PI);
    CGContextScaleCTM(bitmap, -1.0, 1.0);
    CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width / 2, -rotatedSize.height / 2, rotatedSize.width, rotatedSize.height), cgImage);
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end


@interface uexBaiduMapNodeAnnotation()
@property (nonatomic, strong)uexBaiduMapNodeData *nodeData;
@end
@implementation uexBaiduMapNodeAnnotation

- (instancetype)initWithData:(uexBaiduMapNodeData *)data{
    self = [super init];
    if (self) {
        _identifier = UUID();
        _nodeData = data;
    }
    return self;
}

+ (instancetype)startNodeAnnotation{
    uexBaiduMapNodeData *data = [[uexBaiduMapNodeData alloc] init];
    data.reuseIdentifier = @"uexBaiduMap.NodeAnnotation.Start";
    data.iconNeedOffset = YES;
    [data setBundleImagePath:@"images/icon_nav_start.png"];
    return [[self alloc] initWithData:data];
}
+ (instancetype)endNodeAnnotation{
    uexBaiduMapNodeData *data = [[uexBaiduMapNodeData alloc] init];
    data.reuseIdentifier = @"uexBaiduMap.NodeAnnotation.End";
    data.iconNeedOffset = YES;
    [data setBundleImagePath:@"images/icon_nav_end.png"];
    return [[self alloc] initWithData:data];
}

+ (instancetype)busNodeAnnotation{
    uexBaiduMapNodeData *data = [[uexBaiduMapNodeData alloc] init];
    data.reuseIdentifier = @"uexBaiduMap.NodeAnnotation.Bus";
    [data setBundleImagePath:@"images/icon_nav_bus.png"];
    return [[self alloc] initWithData:data];
}
+ (instancetype)railNodeAnnotation{
    uexBaiduMapNodeData *data = [[uexBaiduMapNodeData alloc] init];
    data.reuseIdentifier = @"uexBaiduMap.NodeAnnotation.Rail";
    [data setBundleImagePath:@"images/icon_nav_rail.png"];
    return [[self alloc] initWithData:data];
}

+ (instancetype)directionNodeAnnotationWithRotateDegree:(CGFloat)degree{
    uexBaiduMapNodeData *data = [[uexBaiduMapNodeData alloc] init];
    data.reuseIdentifier = @"uexBaiduMap.NodeAnnotation.Direction";
    [data setBundleImagePath:@"images/icon_direction.png"];
    data.iconNeedRotate = YES;
    data.rotateDegree = degree;
    return [[self alloc] initWithData:data];
}
+ (instancetype)wayPointNodeAnnotation{
    uexBaiduMapNodeData *data = [[uexBaiduMapNodeData alloc] init];
    data.reuseIdentifier = @"uexBaiduMap.NodeAnnotation.WayPoint";
    data.iconNeedOffset = YES;
    [data setBundleImagePath:@"images/icon_nav_waypoint.png"];
    
    return [[self alloc] initWithData:data];
}

- (BMKAnnotationView *)annotationViewForMap:(BMKMapView *)mapView{
    BMKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:self.nodeData.reuseIdentifier];
    if (!view) {
        view = [[BMKAnnotationView alloc]initWithAnnotation:self reuseIdentifier:self.nodeData.reuseIdentifier];
        if (self.nodeData.isStaticIcon) {
            view.image = self.nodeData.icon;
        }
    } else {
        [view setNeedsDisplay];
    }
    if (!self.nodeData.isStaticIcon) {
        view.image = self.nodeData.icon;
    }
    if (self.nodeData.iconNeedOffset) {
        CGSize size = view.bounds.size;
        view.centerOffset = CGPointMake(size.width * self.nodeData.offsetRatio.x, size.height * self.nodeData.offsetRatio.y);
    }
    view.draggable = NO;
    view.canShowCallout = self.nodeData.canShowCallout;
    view.annotation = self;
    return view;
}
@end
