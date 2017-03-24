//
//  DMGrowAnimation.m
//  DMAnimation
//
//  Created by chenxinxin on 15/10/21.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMGrowAnimation.h"
#import "DMLog.h"
#import "DMPage.h"
#import "DMNavigator.h"

@implementation DMGrowAnimation


DMLOG_DEFINE(DMGrowAnimation)

-(instancetype) init {
    if(self=[super init]) {
        self.duration = 2;
    }
    return self;
}

-(UIView*) findHostView:(UIView*)view {
    return [DMNavigator getInstance].view;
}

-(void) animateView:(UIView*) view {
    NSArray* frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 20, 0)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 10, 0)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 5, 0)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 2, 0)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 0, 0)],
                            nil];
    
    
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    [animation setValues:frameValues];
    animation.fillMode = kCAFillModeForwards;
    animation.duration = self.duration;
    
    [view.layer addAnimation:animation forKey:@"growAnimation"];
}


+(void) animateViews:(NSArray*)views {
    for (int i = 0; i < views.count; i++) {
        id view = views[i];
        if([view isKindOfClass:[UIView class]]) {
            UIView* uiView = (UIView*)view;
            DMGrowAnimation* animation = [[DMGrowAnimation alloc] init];
            [animation animateView:uiView];
        }
    }
}

@end
