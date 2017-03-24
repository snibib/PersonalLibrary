//
//  DMMagicScrollView.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/30.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMMagicScrollView.h"
#import "DMPropertyAnimation.h"
#import "DMWeakify.h"


@interface DMMagicViewInfo : NSObject
@property (weak,nonatomic) UIView* view;
@property (assign,nonatomic) CGRect fromRect;
@property (assign,nonatomic) CGRect toRect;
@property (assign,nonatomic) CGFloat fromOpacity;
@property (assign,nonatomic) CGFloat toOpacity;
@property (assign,nonatomic) CGFloat rate;
@end

@implementation DMMagicViewInfo

-(void) setRate:(CGFloat)rate {
    self->_rate = rate;
    CGFloat x = self.fromRect.origin.x + (self.toRect.origin.x - self.fromRect.origin.x) * rate;
    CGFloat y = self.fromRect.origin.y + (self.toRect.origin.y - self.fromRect.origin.y) * rate;
    CGFloat width = self.fromRect.size.width + (self.toRect.size.width - self.fromRect.size.width) * rate;
    CGFloat height = self.fromRect.size.height + (self.toRect.size.height - self.fromRect.size.height) * rate;
    
    if (self.fromOpacity != self.toOpacity) {
        self.view.layer.opacity = self.fromOpacity + (self.toOpacity - self.fromOpacity) * rate;
    }
    CGRect frame = CGRectMake(x, y, width, height);
    if (!CGRectEqualToRect(frame, self.view.frame)) {
        self.view.frame = frame;
    }
}
@end



@interface DMMagicScrollView()

@property (strong,nonatomic) DMPropertyAnimation* propertyAnimation;
@property (strong,nonatomic) UIPanGestureRecognizer* panGestureRecognizer;

@property (assign,nonatomic) CGPoint touchDownPoint;
@property (assign,nonatomic) CGFloat touchDownOffsetX;


@property (strong,nonatomic) NSMutableArray* magicState;
@end

@implementation DMMagicScrollView

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self initSelf];
    }
    return self;
}

-(instancetype) init {
    if(self = [super init]) {
        [self initSelf];
    }
    return self;
}


-(instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initSelf];
    }
    return self;
}

-(DMPropertyAnimation*) propertyAnimation {
    if (self->_propertyAnimation == nil) {
        self->_propertyAnimation = [[DMPropertyAnimation alloc] init];
        self->_propertyAnimation.loopCount = 1;
    }
    return self->_propertyAnimation;
}

-(void) initSelf {
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:self.panGestureRecognizer];
    
    self.offsetX = 0;
    self.scrollLength = self.frame.size.width / 3;
}



-(NSMutableArray*) magicState {
    if (self->_magicState == nil) {
        self->_magicState = [[NSMutableArray alloc] init];
    }
    return self->_magicState;
}

-(void) setScrollRate:(CGFloat)scrollRate {
    [self setOffsetX:self.scrollLength*scrollRate];
}

-(CGFloat) scrollRate {
    return self.offsetX / self.scrollLength;
}

-(void) setOffsetX:(CGFloat)offsetX {
    if (offsetX < 0) {
        offsetX = 0;
    }
    if (offsetX > self.scrollLength) {
        offsetX = self.scrollLength;
    }
    
    self->_offsetX = offsetX;
    CGFloat rate = self->_offsetX / self.scrollLength;    
    
    for (DMMagicViewInfo* viewInfo in self.magicState) {
        viewInfo.rate = rate;
    }
    
    if ([self.delegate respondsToSelector:@selector(magicScrollView:didUpdateScroll:)]) {
        [self.delegate magicScrollView:self didUpdateScroll:rate];
    }
}


-(void) prepareStates {
    if (self.delegate == nil) {
        return;
    }
    
    self.magicState = nil;
    
    [self.delegate magicScrollViewSetupRightState:self];
    [self collectToFrameForView:self];
    [self.delegate magicScrollViewSetupLeftState:self];
    [self collectFromFrames];
    
    self.offsetX = self.offsetX;
}

-(void) collectFromFrames {
    for (DMMagicViewInfo* viewInfo in self.magicState) {
        viewInfo.fromRect = viewInfo.view.frame;
    }
}

-(void) collectToFrameForView:(UIView*) view {
    DMMagicViewInfo* info = [[DMMagicViewInfo alloc] init];
    info.view = view;
    info.toRect = view.frame;
    [self.magicState addObject:info];
    
    for (UIView* subView in view.subviews) {
        [self collectToFrameForView:subView];
    }
}

-(void) handlePan: (UIPanGestureRecognizer *)rec{
    CGPoint point = [rec translationInView:self];
    
    if (rec.state == UIGestureRecognizerStateBegan) {
        [self.propertyAnimation stop];
        self.touchDownPoint = point;
        self.touchDownOffsetX = self.offsetX;
        [self prepareStates];
        return;
    }
    
    if (rec.state == UIGestureRecognizerStateChanged) {
        CGFloat deltaX = point.x - self.touchDownPoint.x;
        CGFloat targetOffsetX = self.touchDownOffsetX + deltaX;
        self.offsetX = targetOffsetX;
    }
    
    if (rec.state == UIGestureRecognizerStateEnded) {
        CGPoint v = [rec velocityInView:self];
        CGFloat vx = v.x;
        if (vx > 128 || (vx > 0 && self.offsetX > self.scrollLength / 2) || (vx<0 && self.offsetX > self.scrollLength/2 && vx > -128)) {
            [self flyToRight:vx];
        } else {
            [self flyToLeft:vx];
        }
    }
}

-(void) scrollToInitState {
    [self prepareStates];
    [self flyToLeft:-512];
}
-(void) scrollToFinalState {
    [self prepareStates];
    [self flyToRight:512];
}

-(void) flyToRight:(float)vx {
    if (vx < 256) {
        vx = 256;
    }
    
    [self.propertyAnimation stop];
    
    float fromOffsetX = self.offsetX;
    float toOffsetX = self.scrollLength;

    
    float s = toOffsetX - fromOffsetX;
    if (s == 0) {
        return;
    }
    
    float a = -vx*vx / (2*s);
    float t = -vx / a;
    
    self.propertyAnimation.duration = t;
    @weakify_self
    self.propertyAnimation.callback = ^(float rate) {
        @strongify_self
        
        float tt = t * rate;
        float ss = vx * tt + a * tt * tt / 2;
        
        if(rate == 1) {
            self.offsetX = toOffsetX;
        } else {
            self.offsetX = fromOffsetX + ss;
        }
    };
    [self.propertyAnimation start];
}

-(void) flyToLeft:(float)vx {
    if (vx > -256) {
        vx = -256;
    }
    
    [self.propertyAnimation stop];
    
    float fromOffsetX = self.offsetX;
    float toOffsetX = 0;
    
    float s = toOffsetX - fromOffsetX;
    if (s == 0) {
        return;
    }
    float a = -vx*vx / (2*s);
    float t = -vx / a;
    
    self.propertyAnimation.duration = t;
    @weakify_self
    self.propertyAnimation.callback = ^(float rate) {
        @strongify_self
        
        float tt = t * rate;
        float ss = vx * tt + a * tt * tt / 2;
        
        if (rate == 1) {
            self.offsetX = toOffsetX;
        } else {
            self.offsetX = fromOffsetX + ss;
        }
    };
    [self.propertyAnimation start];

}



@end
