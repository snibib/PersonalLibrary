//
//  LDPageAnimatorPushLeft.m
//  ledai
//
//  Created by chenxinxin on 2014-11-18.
//  Copyright (c) 2014 ledai. All rights reserved.
//

#import "DMPageAnimatePushTop.h"
#import "DMWeakify.h"

@interface DMPageAnimatePushTop()

@property (copy) void (^callback)();
@property (copy) void (^originCallback)();

@end


@implementation DMPageAnimatePushTop



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
//    CGRect oldTopTargetFrame = oldTopInitFrame;
    CGRect newTopTargetFrame = to.frame;
    CGRect newTopInitFrame = CGRectMake(newTopTargetFrame.origin.x, newTopTargetFrame.origin.y+newTopTargetFrame.size.height, newTopTargetFrame.size.width, newTopTargetFrame.size.height);
    
    from.frame = oldTopInitFrame;
    to.frame = newTopInitFrame;
    
    UIView* mask = [[UIView alloc] initWithFrame:from.bounds];
    mask.backgroundColor = [UIColor blackColor];
    mask.alpha = 0;
    [from addSubview:mask];
    
#define animationKey @"pushAnimation"
    
    
    CABasicAnimation*    toAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    toAnimation.delegate = self;
    toAnimation.duration = duration;
    toAnimation.beginTime = 0; //CACurrentMediaTime() + 1;
    toAnimation.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionTranslateY];
    toAnimation.timingFunction = self.timeFunction;
    toAnimation.fromValue = [NSNumber numberWithFloat:0];
    toAnimation.toValue = [NSNumber numberWithFloat:newTopTargetFrame.origin.y-newTopInitFrame.origin.y];
    toAnimation.removedOnCompletion = NO;
    toAnimation.fillMode = kCAFillModeForwards;
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
        [strong_from.layer removeAnimationForKey:animationKey];
        [strong_to.layer removeAnimationForKey:animationKey];
        strong_to.frame = newTopTargetFrame;
        strong_from.frame = oldTopInitFrame;
    };
    
    @weakify(mask)
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        @strongify(mask)
        strong_mask.alpha = alphaRate;
    } completion:^(BOOL finished) {
        @strongify(mask)
        [strong_mask removeFromSuperview];
    }];

}
@end
