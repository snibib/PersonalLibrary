//
//  DMDropBoxAnimation.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/10.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMDropBoxAnimation.h"

@interface DMDropBoxAnimation()
@property (strong,nonatomic) UIImageView* temp;
@property (strong,nonatomic) UIView* box;
@end

@implementation DMDropBoxAnimation


- (UIImage *)screenshot:(UIView*) view;
{
    return [self screenshot:view withRect:view.bounds];
}

- (UIImage *)screenshot:(UIView*)view withRect:(CGRect)rect;
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL)
    {
        return nil;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    
    //[self layoutIfNeeded];
    if( [view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    }
    else
    {
        [view.layer renderInContext:context];
    }
    
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    NSData *imageData = UIImageJPEGRepresentation(image, 1); // convert to jpeg
    //    image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
    
    return image;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.temp) {
        [self.temp removeFromSuperview];
        self.temp = nil;
    }
    NSArray* frameValues = [NSArray arrayWithObjects:
                   [NSValue valueWithCATransform3D:CATransform3DMakeScale(1,1,1)],
                   [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2,1,1)],
                   [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8,1,1)],
                   [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1,1,1)],
                   [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9,1,1)],
                   [NSValue valueWithCATransform3D:CATransform3DMakeScale(1,1,1)],
                   nil];
    
    
    CAKeyframeAnimation* boxScale = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    [boxScale setValues:frameValues];
    boxScale.fillMode = kCAFillModeRemoved;
    boxScale.duration = 0.6f;
    [self.box.layer addAnimation:boxScale forKey:@"scaleAnimation"];
}

+ (UIView*) appRootView {
    return [UIApplication sharedApplication].windows.lastObject;
}


-(void) animateDropView:(UIView*)view toBox:(UIView*)box {
    if(view == nil || box == nil) {
        return;
    }
    
    self.box = box;
    UIView* container = [DMDropBoxAnimation appRootView];
    
    CGFloat shorter = view.frame.size.width > view.frame.size.height ? view.frame.size.height : view.frame.size.width;
    
    self.temp = [[UIImageView alloc] init];
    self.temp.image = [self screenshot:view];
    self.temp.frame = [container convertRect:view.frame fromView:view.superview];
    self.temp.layer.cornerRadius = shorter/2;
    self.temp.layer.masksToBounds = YES;
    [container addSubview:self.temp];
    
    CGFloat duration = 0.6f;
    CAMediaTimingFunction* timeFunction = [CAMediaTimingFunction functionWithControlPoints:0.25f :0.3f :0.23f :0.16f];
    
    CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.duration=duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    //animation.repeatCount=HUGE_VALF;// repeat forever
    //animation.calculationMode = kCAAnimationCubicPaced;
    animation.timingFunction = timeFunction;
    animation.delegate = self;
    
    
    CGPoint boxCenter = [container convertPoint:box.center fromView:box.superview];
    CGPoint top;
    CGPoint viewCenter = [container convertPoint:view.center fromView:view.superview];
    if (viewCenter.y < boxCenter.y) {
        top = CGPointMake(viewCenter.x + (boxCenter.x-viewCenter.x)/4, viewCenter.y-50);
    } else {
        top = CGPointMake(boxCenter.x - (boxCenter.x-viewCenter.x)/4, boxCenter.y-50);
    }
    
    
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath, NULL, viewCenter.x, viewCenter.y);
    CGPathAddQuadCurveToPoint(curvedPath, NULL, viewCenter.x, top.y+(viewCenter.y-top.y)/2, top.x, top.y);
    CGPathAddQuadCurveToPoint(curvedPath, NULL, boxCenter.x-(boxCenter.x-top.x)*3/5, top.y, boxCenter.x, boxCenter.y);
    animation.path=curvedPath;
    
    self.temp.layer.anchorPoint = CGPointMake(0.5, 0.5);
    [self.temp.layer addAnimation:animation forKey:@"dropBoxAnimation"];
    
    
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    scaleAnimation.toValue = [NSNumber numberWithFloat:0.06f];
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.duration = duration;
    scaleAnimation.timingFunction = timeFunction;
    [self.temp.layer addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    

   
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    NSArray* frameValues = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0],
                            [NSNumber numberWithFloat:1],
                            [NSNumber numberWithFloat:0],
                            nil];
     [opacityAnimation setValues:frameValues];
    opacityAnimation.removedOnCompletion = NO;
    opacityAnimation.fillMode = kCAFillModeForwards;
    opacityAnimation.duration = duration;
    opacityAnimation.timingFunction = timeFunction;
    [self.temp.layer addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}

+(void) animate:(UIView*)view toBox:(UIView*)box {
    DMDropBoxAnimation* animation = [[DMDropBoxAnimation alloc] init];
    [animation animateDropView:view toBox:box];
}

@end
