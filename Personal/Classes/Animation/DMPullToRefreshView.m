//
//  DMPullToRefreshView.m
//  DMTools
//
//  Created by chenxinxin on 15/10/23.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMPullToRefreshView.h"
#import "DMMutiProxy.h"
#import "DMWeakify.h"
#import "DMGifView.h"
#import "DMLog.h"
#import "DMPropertyAnimation.h"

@interface DMPullToRefreshHeader : UIView
@property (weak,nonatomic) DMPullToRefreshView* pullToRefreshView;
@property (strong,nonatomic) UIImageView* backgroundImageView;
@property (strong,nonatomic) DMGifView* backgroundGifView;
@property (strong,nonatomic) UIImageView* arrowImageView;
@property (assign,nonatomic) CGRect backgroundImageFrame;
@property (assign,nonatomic) BOOL isArrowDown;
@property (assign,nonatomic) BOOL loading;
///headview的高宽比例，传进来
@property (assign, nonatomic) CGFloat   headScaleRatio;
-(void) setTop : (CGFloat) top ;
-(BOOL) isPulledOut;
@end

@implementation DMPullToRefreshHeader

-(instancetype) init {
    if(self= [super init]) {
        self.backgroundImageView = [[UIImageView alloc] init];
        [self addSubview:self.backgroundImageView];
        
        self.backgroundGifView = [[DMGifView alloc] init];
        [self addSubview:self.backgroundGifView];
        
        self.isArrowDown = YES;
        
        self.arrowImageView = [[UIImageView alloc] init];
        self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.loading = NO;
        [self addSubview:self.arrowImageView];
        
        self.layer.masksToBounds = YES;
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];
    
    if (self.backgroundImageFrame.size.width > 0 && self.backgroundImageFrame.size.height > 0) {
        CGRect frame = self.backgroundImageFrame;
        self.backgroundImageView.frame = frame;
        self.backgroundGifView.frame = frame;
    } else {
        self.backgroundImageView.frame = self.bounds;
        self.backgroundGifView.frame = self.bounds;
    }
    

    
    CGFloat arrowHeight = self.pullToRefreshView.headerArrowHeight;
    CGFloat bottomMargin = self.pullToRefreshView.headerArrowMarginBottom;
    
    self.arrowImageView.frame = CGRectMake(0, self.bounds.size.height-arrowHeight-bottomMargin, self.bounds.size.width, arrowHeight);
}

-(void) layoutSelfByBGImageWithWidth:(CGFloat) width {
    if(self.backgroundImageView.image == nil) {
        CGFloat headerHeight = width * self.headScaleRatio;
        CGRect headerRect = CGRectMake(0, -headerHeight, width, headerHeight);
        self.frame = headerRect;
        return;
    }
    
    CGFloat headerHeight = width * (self.backgroundImageView.image.size.height/self.backgroundImageView.image.size.width);
    CGRect headerRect = CGRectMake(0, -headerHeight, width, headerHeight);
    self.frame = headerRect;
}

-(void) setTop : (CGFloat)top {
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
    BOOL pulledOut = [self isPulledOut];
    if (pulledOut != !self.isArrowDown) {
        self.isArrowDown = !pulledOut;
        if(self.isArrowDown) {
            [self rotateArrowDown];
        } else {
            [self rotateArrowUp];
        }
    }
}

-(void) rotateArrowUp {
    [self.arrowImageView.layer removeAllAnimations];
    self.arrowImageView.transform = CGAffineTransformMakeRotation(0 *M_PI / 180.0);
    
    @weakify_self
    [UIView animateWithDuration:self.pullToRefreshView.headerArrowRotateDuration animations:^{
        @strongify_self
        self.arrowImageView.transform = CGAffineTransformMakeRotation(180 *M_PI / 180.0);
    } completion:^(BOOL finished) {
        @strongify_self
        self.arrowImageView.transform = CGAffineTransformMakeRotation(180 *M_PI / 180.0);
    }];
}

-(void) rotateArrowDown {
    [self.arrowImageView.layer removeAllAnimations];
    self.arrowImageView.transform = CGAffineTransformMakeRotation(180 *M_PI / 180.0);
    
    @weakify_self
    [UIView animateWithDuration:self.pullToRefreshView.headerArrowRotateDuration animations:^{
        @strongify_self
        self.arrowImageView.transform = CGAffineTransformMakeRotation(0 *M_PI / 180.0);
    } completion:^(BOOL finished) {
        @strongify_self
        self.arrowImageView.transform = CGAffineTransformMakeRotation(0 *M_PI / 180.0);
    }];
}



-(BOOL) isPulledOut {
    return -self.frame.origin.y < self.frame.size.height / 2;
}

-(BOOL) isPulled {
    return -self.frame.origin.y < self.frame.size.height;
}


@end



@interface DMPullToRefreshView() <UIScrollViewDelegate>
@property (weak,nonatomic) DMPullToRefreshHeader* header;
@property (weak,nonatomic) UIView* scrollViewContainer;
@property (strong,nonatomic) DMMutiProxy* scrollViewDelegateProxy;
@property (assign,nonatomic) BOOL pulling;
@property (strong,nonatomic) DMPropertyAnimation* unexpandAnimation;
@end

@implementation DMPullToRefreshView


DMLOG_DEFINE(DMPullToRefreshView)

- (instancetype) init {
    if(self=[super init]) {
        [self initSelf];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self initSelf];
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self initSelf];
    }
    return self;
}

-(void) initSelf {
    self.pulling = NO;
    [self initInnerViews];
}

- (DMPullToRefreshHeader*) header {
    if(self->_header == nil) {
        [self initInnerViews];
    }
    return self->_header;
}

-(void) setHeaderBackgroundImage:(UIImage *)headerBackgroundImage {
    self.header.backgroundImageView.image = headerBackgroundImage;
    self.header.backgroundGifView.hidden = YES;
    self.header.backgroundImageView.hidden = NO;
}

-(void) setHeaderBackgroundGif:(NSData *)headerBackgroundGif {
    [self.header.backgroundGifView loadFromData:headerBackgroundGif];
    self.header.backgroundGifView.hidden = NO;
    self.header.backgroundImageView.hidden = YES;
}

-(void) setHeaderBackgroundFrame:(CGRect)headerBackgroundFrame {
    self.header.backgroundImageFrame = headerBackgroundFrame;
}

-(UIImage*) headerBackgroundImage {
    return self.header.backgroundImageView.image;
}

-(void) setHeaderArrowImage:(UIImage *)headerArrowImage {
    self.header.arrowImageView.image = headerArrowImage;
}

-(UIImage*) headerArrowImage {
    return self.header.arrowImageView.image;
}

-(DMMutiProxy*) scrollViewDelegateProxy {
    if(self->_scrollViewDelegateProxy == nil) {
        self->_scrollViewDelegateProxy = [[DMMutiProxy alloc] init];
        [self->_scrollViewDelegateProxy addWeakProxy:self];
    }
    return self->_scrollViewDelegateProxy;
}

-(void) setPullEnable:(BOOL)pullEnable {
    self->_pullEnable = pullEnable;
    self->_header.hidden = !pullEnable;
}

- (void) initInnerViews {
    if (self->_header != nil) {
        return;
    }
    self.pullEnable = YES;
    self.headerArrowMarginBottom = 10;
    self.headerArrowHeight = 26;
    self.headerArrowRotateDuration = 0.3;
    
    DMPullToRefreshHeader* header = [[DMPullToRefreshHeader alloc] init];
    header.pullToRefreshView = self;
    
    UIView* container = [[UIView alloc] init];
    self.header = header;
    self.scrollViewContainer = container;
    [self addSubview:container];
    [self addSubview:header];
  
    
    [self bindScrollView];
}

-(void) layoutSubviews {
    [super layoutSubviews];
    if (self.pullEnable) {
        CGFloat width = self.frame.size.width;
        [self.header layoutSelfByBGImageWithWidth:width];
    }
    self.scrollViewContainer.frame = self.bounds;
    self.scrollView.frame = self.bounds;
}

-(void) updateScrollViewPaddingTop:(float) padding {
    self.scrollView.contentInset = UIEdgeInsetsMake(padding, self.scrollView.contentInset.left, self.scrollView.contentInset.bottom, self.scrollView.contentInset.right);
}
-(void) notifyDataLoaded {
    [self notifyDataLoaded:nil];
}


-(void) notifyDataLoaded:(void(^)()) callback {
    if (!self.pullEnable) {
        if (callback) {
            callback();
        }
        return;
    }
    
    if (self->_unexpandAnimation != nil) {
        if (callback) {
            callback();
        }
        return;
    }
    
    if (!self.header.loading) {
        if (callback) {
            callback();
        }
        return;
    }
    
    
    self.unexpandAnimation = [[DMPropertyAnimation alloc] init];
    float from = -self.scrollView.contentInset.top - self.scrollView.contentOffset.y;
    float to = - self.header.frame.size.height;
    
   
    
    @weakify_self
    self.unexpandAnimation.callback = ^(float rate) {
        @strongify_self
        float top =  from + (to-from)*rate;
        if (rate >= 1) {
            top = to;
        }
        [self updateScrollViewPaddingTop:self.header.frame.size.height+top];
        [self.header setTop:top];
        if (rate >= 1) {
            self.header.loading = NO;
            [self.unexpandAnimation stop];
            self.unexpandAnimation = nil;
            [self.header.backgroundGifView stop];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(pullToRefreshViewPullEnd:)]) {
                [self.delegate pullToRefreshViewPullEnd:self];
            }
            if (callback) {
                callback();
            }
        }
    };
    self.unexpandAnimation.duration = 0.4;
    self.unexpandAnimation.loopCount = 1;
    [self.unexpandAnimation start];
}

- (void) setScrollView:(UIView*)scrollView {
    self->_scrollView = scrollView;
    if ([scrollView isKindOfClass:[UIScrollView class]]) {
        [self.scrollViewDelegateProxy addWeakProxy:((UIScrollView*)self->_scrollView).delegate];
        ((UIScrollView*)self->_scrollView).delegate = self.scrollViewDelegateProxy;
    } else if([scrollView isKindOfClass:[UIWebView class]]) {
        [self.scrollViewDelegateProxy addWeakProxy:((UIWebView*)scrollView).scrollView.delegate];
        ((UIWebView*)scrollView).scrollView.delegate = self.scrollViewDelegateProxy;
    }
    
    [self bindScrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.pullEnable) {
        return;
    }
    
    CGFloat y = scrollView.contentOffset.y;
    CGRect frame = self.header.frame;
    CGFloat targetY = -y - frame.size.height;
    if(targetY > 0) {
        targetY = 0;
    }
    [self.header setTop:targetY];
    
    if (y < 0) {
        if (!self.pulling) {
            self.pulling = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(pullToRefreshViewPullBegin:)]) {
                [self.delegate pullToRefreshViewPullBegin:self];
            }
            [self.header.backgroundGifView playLoop];
            
        }
    } else {
        if (self.pulling) {
            self.pulling = NO;
            if (!self.header.loading && self.delegate && [self.delegate respondsToSelector:@selector(pullToRefreshViewPullEnd:)]) {
                [self.delegate pullToRefreshViewPullEnd:self];
            }
            [self.header.backgroundGifView stop];
        }
    }
}

-(void) applyRefreshingState {
    [self updateScrollViewPaddingTop:self.header.frame.size.height];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.pullEnable) {
        return;
    }
    
    if ([self.header isPulledOut] && !self.header.loading) {
        self.header.loading = YES;
        [self applyRefreshingState];
        if (self.delegate && [self.delegate respondsToSelector:@selector(pullToRefreshViewDidRefresh:)]) {
            [self.delegate pullToRefreshViewDidRefresh:self];
        }
    }
}

- (void) bindScrollView {
    if(self->_scrollView == nil || self->_scrollViewContainer == nil) {
        return;
    }
    for (UIView* view in self.scrollViewContainer.subviews) {
        [view removeFromSuperview];
    }
    [self->_scrollView removeFromSuperview];
    [self.scrollViewContainer addSubview:self->_scrollView];
}

- (void) setHeadScaleRatio:(CGFloat)headScaleRatio {
    _headScaleRatio = headScaleRatio;
    if (self.header) {
        [self.header setHeadScaleRatio:headScaleRatio];
    }
}


@end
