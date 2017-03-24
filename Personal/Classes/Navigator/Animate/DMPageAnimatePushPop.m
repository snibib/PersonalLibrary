//
//  LDPageAnimatorPushPop.m
//  ledai-iPhone
//
//  Created by chenxinxin on 14/11/26.
//  Copyright (c) 2014年 corichen. All rights reserved.
//

#import "DMPageAnimatePushPop.h"

@implementation DMPageAnimatePushPop

-(instancetype) init {
    if(self=[super init]) {
        self.alphaRate = 0.4;
        self.leaveRate = 0.3;
        self.duration = 0.6;
        self.timeFunction = [CAMediaTimingFunction functionWithControlPoints:0 :0.6 :0.3 :1];
    }
    return self;
}
@end
