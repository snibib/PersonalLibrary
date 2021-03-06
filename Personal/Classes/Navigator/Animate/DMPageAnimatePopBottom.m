//
//  LDPageAnimatorPopRight.m
//  ledai
//
//  Created by chenxinxin on 2014-11-18.
//  Copyright (c) 2014 ledai. All rights reserved.
//

#import "DMPageAnimatePopBottom.h"
#import "DMWeakify.h"

@interface DMPageAnimatePopBottom()

@property (copy) void (^callback)();
@property (copy) void (^originCallback)();

@end

@implementation DMPageAnimatePopBottom


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
    CGRect oldTopTargetFrame = CGRectOffset(oldTopInitFrame, 0, oldTopInitFrame.size.height);
    CGRect newTopTargetFrame = to.frame;
    CGRect newTopInitFrame = newTopTargetFrame;
    from.frame = oldTopInitFrame;
    to.frame = newTopInitFrame;
    
    UIView* mask = [[UIView alloc] initWithFrame:to.bounds];
    mask.backgroundColor = [UIColor blackColor];
    mask.alpha = alphaRate;
    [to addSubview:mask];

#define animationKey @"popAnimation"

    CABasicAnimation*    fromAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    fromAnimation.delegate = self;
    fromAnimation.duration = duration;
    fromAnimation.beginTime = 0;
    fromAnimation.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionTranslateY];
    fromAnimation.timingFunction = self.timeFunction;
    fromAnimation.fromValue = [NSNumber numberWithFloat:0];
    fromAnimation.toValue = [NSNumber numberWithFloat:oldTopTargetFrame.origin.y-oldTopInitFrame.origin.y];
    fromAnimation.fillMode = kCAFillModeForwards;
    fromAnimation.removedOnCompletion = NO;
    [from.layer addAnimation:fromAnimation forKey:animationKey];
    
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
