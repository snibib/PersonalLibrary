//
//  DMBubbleAnimation.m
//  DMAnimation
//
//  Created by chenxinxin on 15/10/21.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMBubbleAnimation.h"

@implementation DMBubbleAnimation

-(instancetype) init {
    if(self=[super init]) {
        self.beginTime = CACurrentMediaTime();
        self.duration = 1.2;
    }
    return self;
}

-(void) animateView:(UIView*) view {
    NSArray* frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1,1,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2,1.2,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8,0.8,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1,1.1,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9,0.9,1)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1,1,1)],
                            nil];
    
    //    NSArray* keyTimes =  [NSArray arrayWithObjects:
    //                          [NSNumber numberWithFloat:0.0],
    //                          [NSNumber numberWithFloat:0.3],
    //                          [NSNumber numberWithFloat:0.6],
    //                          [NSNumber numberWithFloat:0.8],
    //                          [NSNumber numberWithFloat:0.9],
    //                          [NSNumber numberWithFloat:1.0], nil];
    
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    [animation setValues:frameValues];
    animation.fillMode = kCAFillModeForwards;
    animation.duration = self.duration;
    //animation.keyTimes = keyTimes;
    animation.beginTime = self.beginTime;
    
    [view.layer addAnimation:animation forKey:@"bubbleAnimation"];
}


+(void) animateViews:(NSArray*)views {
    for (int i = 0; i < views.count; i++) {
        id view = views[i];
        if([view isKindOfClass:[UIView class]]) {
            UIView* uiView = (UIView*)view;
            DMBubbleAnimation* animation = [[DMBubbleAnimation alloc] init];
            animation.beginTime = CACurrentMediaTime() + (rand() % 100) / 200.0;
            [animation animateView:uiView];
        }
    }
}
@end
