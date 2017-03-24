//
//  LDPageAnimatorPopRight.m
//  ledai
//
//  Created by chenxinxin on 2014-11-18.
//  Copyright (c) 2014 ledai. All rights reserved.
//

#import "DMPageAnimatePopRight.h"
#import "DMWeakify.h"

@interface DMPageAnimatePopRight()

@property (copy) void (^callback)();
@property (copy) void (^originCallback)();

@end

@implementation DMPageAnimatePopRight


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.callback) {
        self.callback();
    }
    self.callback = nil;
}

-(void) animateFrom:(UIViewController*)fromPage to:(UIViewController*)toPage callback:(void (^)())callback {
    self.originCallback = callback;
    
    UIView* from = fromPage.view;
    UIView* to = toPage.view;
    
    float alphaRate = self.alphaRate;
    float duration = self.duration;

    CGRect oldTopInitFrame = from.frame;
    CGRect oldTopTargetFrame = CGRectOffset(oldTopInitFrame, oldTopInitFrame.size.width, 0);
    CGRect newTopTargetFrame = to.frame;
    CGRect newTopInitFrame = CGRectOffset(newTopTargetFrame, -newTopTargetFrame.size.width*self.leaveRate, 0);
    from.frame = oldTopInitFrame;
    to.frame = newTopInitFrame;
    
    UIView* mask = [[UIView alloc] initWithFrame:to.bounds];
    mask.backgroundColor = [UIColor blackColor];
    mask.alpha = alphaRate;
    [to addSubview:mask];

#define animationKey @"popAnimation"

    CABasicAnimation*    fromAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    fromAnimation.duration = duration;
    fromAnimation.beginTime = 0;
    fromAnimation.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionTranslateX];
    fromAnimation.timingFunction = self.timeFunction;
    fromAnimation.fromValue = [NSNumber numberWithFloat:0];
    fromAnimation.toValue = [NSNumber numberWithFloat:oldTopTargetFrame.origin.x-oldTopInitFrame.origin.x];
    fromAnimation.fillMode = kCAFillModeForwards;
    fromAnimation.removedOnCompletion = NO;
    [from.layer addAnimation:fromAnimation forKey:animationKey];
    
    
    CABasicAnimation*    toAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    toAnimation.delegate = self;
    toAnimation.duration = duration;
    toAnimation.beginTime = 0;
    toAnimation.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionTranslateX];
    toAnimation.timingFunction = self.timeFunction;
    toAnimation.fromValue = [NSNumber numberWithFloat:0];
    toAnimation.toValue = [NSNumber numberWithFloat:newTopTargetFrame.origin.x-newTopInitFrame.origin.x];
    toAnimation.fillMode = kCAFillModeForwards;
    toAnimation.removedOnCompletion = NO;
    [to.layer addAnimation:toAnimation forKey:animationKey];
    
    @weakify_self
    @weakify(from)
    @weakify(to)
    self.callback = ^{
        @strongify_self
        @strongify(from)
        @strongify(to)
        if (self.originCallback) {
            self.originCallback();
        }
        [strong_to.layer removeAnimationForKey:animationKey];
        [strong_from.layer removeAnimationForKey:animationKey];
        strong_to.frame = newTopTargetFrame;
        strong_from.frame = oldTopInitFrame;
    };
    
    @weakify(mask)
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        @strongify(mask)
        strong_mask.alpha = 0;
    } completion:^(BOOL finished) {
        @strongify(mask)
        [strong_mask removeFromSuperview];
    }];
}
@end
