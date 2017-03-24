//
//  LDPageAnimatorPushPop.h
//  ledai-iPhone
//
//  Created by chenxinxin on 14/11/26.
//  Copyright (c) 2014年 corichen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface DMPageAnimatePushPop : NSObject <CAAnimationDelegate>
@property (assign,nonatomic) float leaveRate;
@property (assign,nonatomic) float alphaRate;
@property (assign,nonatomic) float duration;
@property (strong,nonatomic) CAMediaTimingFunction* timeFunction;
-(instancetype) init;
@end
