//
//  DMPropertyAnimation.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/30.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMPropertyAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import "DMLog.h"

@interface DMPropertyAnimation()
@property (strong,nonatomic) CADisplayLink* displayLink;
@property (assign,nonatomic) NSTimeInterval startTime;
@property (strong,nonatomic) NSTimer* timer;

@property (assign,nonatomic) NSUInteger remainLoopCount;
@end

@implementation DMPropertyAnimation

DMLOG_DEFINE(DMPropertyAnimation)

-(instancetype) init {
    if (self = [super init]) {
        self.loopCount = 0;
        DMDebug(@"init set loopCount = 1")
    }
    return self;
}

-(CADisplayLink*) displayLink {
    if (self->_displayLink == nil) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay:)];
    }
    return self->_displayLink;
}

-(void) setFrameInterval:(NSInteger)frameInterval {
    self.displayLink.frameInterval = frameInterval;
}

-(void) updateDisplay:(id)dl {
    if (self.remainLoopCount == 0) {
        DMDebug(@"updateDisplay detect loopCount == 0 stop animation")
        [self stop];
        return;
    }
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval passed = now - self.startTime;
    if (passed < self.duration) {
        float rate = passed / self.duration;
        if (self.callback != nil) {
            self.callback(rate);
        }
    } else {
        DMDebug(@"will loopCount-- loopCount:%lu",self.loopCount);
        self.remainLoopCount--;
        if (self.remainLoopCount == 0) {
            if (self.callback != nil) {
                self.callback(1);
            }
            [self stop];
        } else {
            if (self.callback != nil) {
                self.callback(1);
            }
            self.startTime = now;
        }
    }
}

-(void) start {
    [self stop];
    DMDebug(@"start loopCount:%lu",self.loopCount);
    self.remainLoopCount = self.loopCount;
    if (self.remainLoopCount == 0) {
        return;
    }
    self.startTime = [NSDate timeIntervalSinceReferenceDate];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void) stop {
    DMDebug(@"stop")
    if (self->_displayLink) {
        [self->_displayLink invalidate];
    }
    self->_displayLink = nil;
    self.remainLoopCount = 0;
}


- (void)dealloc
{
    [self stop];
}

@end
