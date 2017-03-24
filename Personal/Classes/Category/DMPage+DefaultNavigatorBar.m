//
//  DMPage+DefaultNavigatorBar.m
//  Galleon
//
//  Created by 杨涵 on 2017/3/10.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "DMPage+DefaultNavigatorBar.h"
#import <objc/runtime.h>
#import "DMWeakify.h"

@interface GalleonNavigatorBar : UINavigationBar
{
    UILabel*    _titleLabel;
    
}
@property (nonatomic, strong)   UILabel             *titleLabel;
@property (nonatomic, copy)     NSString            *title;
@property (nonatomic, strong)   UIView              *leftView;
@property (nonatomic, strong)   UIView              *rightView;

-(void) setVisable:(BOOL)visable animated:(BOOL)animate;
-(BOOL) visable;

@end

@interface DMPage ()

@property (nonatomic, strong) GalleonNavigatorBar      *navigatorBar;

@end

static const  char defaultNavigatorBarKey;

@implementation DMPage (DefaultNavigatorBar)

- (void)setShowDefaultNavigatorBar:(BOOL)showDefaultNavigatorBar {
    objc_setAssociatedObject(self, @selector(showDefaultNavigatorBar), [NSNumber numberWithBool:showDefaultNavigatorBar], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (showDefaultNavigatorBar) {
        [self addDefaultNavigatorBar];
    }else {
        [self removeDefaultNavigatorBar];
    }
}

- (BOOL)showDefaultNavigatorBar {
    NSNumber *showState = objc_getAssociatedObject(self, _cmd);
    return [showState boolValue];
}

- (void)setNavigatorBar:(GalleonNavigatorBar *)navigatorBar {
    objc_setAssociatedObject(self, @selector(navigatorBar), navigatorBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (GalleonNavigatorBar *)navigatorBar {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)addDefaultNavigatorBar {
    if (self.navigatorBar == nil) {
        self.navigatorBar = [[GalleonNavigatorBar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64)];
    }
    [self.view addSubview:self.navigatorBar];
}

- (void)removeDefaultNavigatorBar {
    [self.navigatorBar removeFromSuperview];
}

- (void)setDefaultTitle:(NSString *)title {
    if (self.navigatorBar == nil) {
        return;
    }
    [self.navigatorBar setTitle:title];
}

- (void)setLeftView:(UIView *)leftView {
    if (self.navigatorBar == nil) {
        return;
    }
    [self.navigatorBar setLeftView:leftView];
}

- (void)setRightView:(UIView *)rightView {
    if (self.navigatorBar == nil) {
        return;
    }
    [self.navigatorBar setRightView:rightView];
}

@end

@interface GalleonNavigatorBar()

@property (assign,nonatomic) BOOL visable;

@end

@implementation GalleonNavigatorBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self setBarTintColor:[UIColor whiteColor]];
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, self.frame.size.width - 50 * 2, 44)];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setFont:[UIFont systemFontOfSize:17]];
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_titleLabel setTextColor:[self colorWithString:@"0x222222"]];
        [self addSubview:_titleLabel];
        
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-0.5, self.frame.size.width, 0.5)];
        bottomLine.backgroundColor = [self colorWithString:@"0xdddddd"];
        [self addSubview:bottomLine];
    }
    return self;
}

- (UIColor*) colorWithString:(NSString *)string{
    if([string hasPrefix:@"#"])
        string = [string substringFromIndex:1];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:[NSCharacterSet symbolCharacterSet]];
    unsigned hex;
    BOOL success = [scanner scanHexInt:&hex];
    
    if(!success)    return nil;
    
    CGFloat red   = ((hex & 0xFF0000) >> 16) / 255.0f;
    CGFloat green = ((hex & 0x00FF00) >>  8) / 255.0f;
    CGFloat blue  =  (hex & 0x0000FF) / 255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

-(void) setVisable:(BOOL)visable animated:(BOOL)animate {
    self.visable = visable;
    if (self.hidden == !visable) {
        return;
    }
    
    if (!animate) {
        self.hidden = !visable;
        return;
    }
    
    if (visable) {
        CGRect frame = self.frame;
        frame.origin.y = -frame.size.height;
        self.frame = frame;
        self.hidden = NO;
        
        @weakify_self
        [UIView animateWithDuration:0.4 animations:^{
            @strongify_self
            CGRect targetFrame = frame;
            targetFrame.origin.y = 0;
            self.frame = targetFrame;
        }];
    } else {
        CGRect frame = self.frame;
        frame.origin.y = 0;
        self.frame = frame;
        self.hidden = NO;
        
        @weakify_self
        [UIView animateWithDuration:0.4 animations:^{
            @strongify_self
            CGRect targetFrame = frame;
            targetFrame.origin.y =  -frame.size.height;
            self.frame = targetFrame;
        } completion:^(BOOL finished) {
            self.hidden = YES;
        }];
    }
}

-(BOOL) visable {
    return self->_visable;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    [_titleLabel setText:_title];
    
}

- (void)setLeftView:(UIView *)leftView
{
    [_leftView removeFromSuperview];
    _leftView = leftView;
    if (leftView.frame.size.height > 44) {
        _leftView.frame = CGRectMake(leftView.frame.origin.x, 20, leftView.frame.size.width, 44.0);
    }else {
        _leftView.frame = CGRectMake(leftView.frame.origin.x, 20+(44-leftView.frame.size.height)/2, leftView.frame.size.width, leftView.frame.size.height);
    }
    
    [self addSubview:_leftView];
}

- (void)setRightView:(UIView *)rightView
{
    [_rightView removeFromSuperview];
    _rightView = rightView;
    
    CGRect rect = _titleLabel.frame;
    if (rightView) {
        rect.size.width = rightView.frame.origin.x - 50 - 40;
    }
    else {
        rect = CGRectMake(50, 20, self.frame.size.width - 50 * 2, 44);
    }
    _titleLabel.frame = rect;
    if (_titleLabel.center.x != [UIScreen mainScreen].bounds.size.width/2) {
        _titleLabel.center  = CGPointMake([UIScreen mainScreen].bounds.size.width/2, _titleLabel.center.y);;
    }
    [self addSubview:_rightView];
}

@end
