//
//  DMNavigator.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMNavigator.h"
#import "DMUrlDecoder.h"
#import "DMPage.h"
#import "DMWebPage.h"
#import "DMRNPage.h"
#import "DMPageAnimate.h"
#import "DMPageAnimatePushLeft.h"
#import "DMPageAnimatePopRight.h"
#import "DMPageAnimatePushTop.h"
#import "DMPageAnimatePopBottom.h"
#import "DMPageAnimateMagicMove.h"
#import "DMStringUtils.h"
#import "DMWeakify.h"
#import "DMSafeThread.h"
#import "DMCacheObject.h"
#import "DMLog.h"

@interface DMPageHolder : NSObject
@property (strong,nonatomic) DMPage* pageInstance;
/*!
 *  页面参数
 */
@property (strong,nonatomic) NSDictionary* pageParams;

/*!
 *  页面对象，也叫页面上下文
 */
@property (strong,nonatomic) NSDictionary* pageContext;

/*!
 *  框架参数
 */
@property (strong,nonatomic) NSDictionary* frameworkParams;

/*!
 *  跳转时传入的url(不包含传递给框架的参数,及@开头的参数)
 */
@property (strong,nonatomic) NSString* pageUrl;

@property (strong,nonatomic) NSString* pageName;

@property (strong,nonatomic) NSString* prePageUrl;
@property (assign,nonatomic) NSInteger prePos;
@property (assign,nonatomic) NSInteger pagePos;
/*!
 *  向上一个页面回传数据的接口
 */
@property (copy,nonatomic) void (^ pageCallback)(NSDictionary*);
@end


@implementation DMPageHolder
-(void) setPageParams:(NSDictionary *)pageParams {
    self->_pageParams = pageParams;
    if ([self.pageInstance respondsToSelector:@selector(setPageParams:)]) {
        [((id<DMPageAware>)self.pageInstance) setPageParams:pageParams];
    }
}
- (void)setPageContext:(NSDictionary *)pageContext {
    self->_pageContext = pageContext;
    if ([self.pageInstance respondsToSelector:@selector(setPageContext:)]) {
        [((id<DMPageAware>)self.pageInstance) setPageContext:pageContext];
    }
}
-(void) setFrameworkParams:(NSDictionary *)frameworkParams {
    self->_frameworkParams = frameworkParams;
    if ([self.pageInstance respondsToSelector:@selector(setFrameworkParams:)]) {
        [((id<DMPageAware>)self.pageInstance) setFrameworkParams:frameworkParams];
    }
}
-(void) setPageUrl:(NSString *)pageUrl {
    self->_pageUrl = pageUrl;
    if ([self.pageInstance respondsToSelector:@selector(setPageUrl:)]) {
        [((id<DMPageAware>)self.pageInstance) setPageUrl:pageUrl];
    }
}
- (void)setPagePos:(NSInteger)pagePos {
    self->_pagePos = pagePos;
    if ([self.pageInstance respondsToSelector:@selector(setPagePos:)]) {
        [((id<DMPageAware>)self.pageInstance) setPagePos:pagePos];
    }
}
- (void)setPrePageUrl:(NSString *)prePageUrl {
    self->_prePageUrl = prePageUrl;
    if ([self.pageInstance respondsToSelector:@selector(setPrePageUrl:)]) {
        [((id<DMPageAware>)self.pageInstance) setPrePageUrl:prePageUrl];
    }
}
- (void)setPrePos:(NSInteger)prePos {
    self->_prePos = prePos;
    if ([self.pageInstance respondsToSelector:@selector(setPrePos:)]) {
        [((id<DMPageAware>)self.pageInstance) setPrePos:prePos];
    }
}
-(void) setPageCallback:(void (^)(NSDictionary *))pageCallback {
    self->_pageCallback = pageCallback;
    if ([self.pageInstance respondsToSelector:@selector(setPageCallback:)]) {
        [((id<DMPageAware>)self.pageInstance) setPageCallback:pageCallback];
    }
}

-(void) setPageName:(NSString *)pageName {
    self->_pageName = pageName;
    if ([self.pageInstance respondsToSelector:@selector(setPageName:)]) {
        [((id<DMPageAware>)self.pageInstance) setPageName:pageName];
    }
}

@end


@interface DMNavigator()
/*!
 *  单个页面的堆栈
 *  注意： 页面堆栈中存储的不直接是page实例，而是DMPageHolder对象
 *        存储了关于页面的更多信息
 */
@property (strong,nonatomic) NSMutableArray* pageStack;
/*!
 *  业务流程堆栈（每个对象代表一个业务流程的起点页面）
 */
@property (strong,nonatomic) NSMutableArray* pageFlowStack;
@property (strong,nonatomic) DMCacheObject* pageCache;

@property (assign,nonatomic) BOOL pageAnimationForward;
@property (strong,nonatomic) id<DMPageAnimate> pageAnimation;
@property (strong,nonatomic) DMPage* pageAnimationFrom;
@property (strong,nonatomic) DMPage* pageAnimationTo;



/** 存放每一个控制器的全屏截图 */
@property (nonatomic, strong) NSMutableArray *screenImages;
@property (nonatomic, strong) UIImageView    *lastPageView;




@end

@implementation DMNavigator


DMLOG_DEFINE(DMNavigator)

#pragma mark - lazy property
- (UIImageView *)lastPageView
{
    if (self->_lastPageView==nil) {
        UIImageView *lastPageView = [[UIImageView alloc] init];
        lastPageView.frame = CGRectMake(- [UIScreen mainScreen].bounds.size.width/2.0, 0,  [UIScreen mainScreen].bounds.size.width,  [UIScreen mainScreen].bounds.size.height);
        self->_lastPageView = lastPageView;
    }
    return self->_lastPageView;
}

- (NSMutableArray *)screenImages
{
    if (self->_screenImages==nil) {
        self->_screenImages = [[NSMutableArray alloc] init];
    }
    return self->_screenImages;
}

-(DMCacheObject*) pageCache {
    if (self->_pageCache == nil) {
        self->_pageCache = [[DMCacheObject alloc] initWithCap:12];
    }
    return self->_pageCache;
}

-(NSMutableArray*) pageStack {
    if(self->_pageStack == nil) {
        self->_pageStack = [[NSMutableArray alloc] init];
    }
    return self->_pageStack;
}

-(NSMutableArray*) pageFlowStack {
    if(self->_pageFlowStack == nil) {
        self->_pageFlowStack = [[NSMutableArray alloc] init];
    }
    return self->_pageFlowStack;
}

NSMutableDictionary* DMNavigator_pageRegistry;

+(NSMutableDictionary*) pageRegistry {
    if(DMNavigator_pageRegistry == nil) {
        DMNavigator_pageRegistry = [[NSMutableDictionary alloc] init];
    }
    return DMNavigator_pageRegistry;
}

NSMutableDictionary* DMNavigator_pageAnimationRegistry;
+(NSMutableDictionary*) pageAnimationRegistry {
    if(DMNavigator_pageAnimationRegistry == nil) {
        DMNavigator_pageAnimationRegistry = [[NSMutableDictionary alloc] init];
    }
    return DMNavigator_pageAnimationRegistry;
}

NSMutableDictionary* DMNavigator_redirectRegistry;
+(NSMutableDictionary*) redirectRegistry {
    if (DMNavigator_redirectRegistry == nil) {
        DMNavigator_redirectRegistry = [[NSMutableDictionary alloc] init];
    }
    return DMNavigator_redirectRegistry;
}

#pragma mark - init method
static DMNavigator *_shareInstance = nil;

-(instancetype) init {
    if(self = [super init]) {}
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [super allocWithZone:zone];
    });
    return _shareInstance;
}

- (id)copy {
    return _shareInstance;
}

- (id)mutableCopy {
    return _shareInstance;
}

-(instancetype) initWithUrl:(NSString*)url {
    self = [DMNavigator getInstance];
    if(self) {
        [self forward:url];
    }
    return self;
}

+(DMNavigator*) getInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[self alloc] init];
    });
    return _shareInstance;
}

-(void) loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor whiteColor];
    self.isSlideBack = true;
    self.isSlideAddShadow= true;
    // 拖拽手势
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragging:)];
    [self.view addGestureRecognizer:recognizer];
    
    if (self.isSlideBack&&self.isSlideAddShadow) {
        self.view.layer.shadowColor = [UIColor blackColor].CGColor;
        self.view.layer.shadowOpacity = 0.3f;
        self.view.layer.shadowRadius = 4.f;
        self.view.layer.shadowOffset = CGSizeMake(-4,-4);
    }
}

+(void) initialize {

    [[DMNavigator pageAnimationRegistry] setObject:[DMPageAnimatePushLeft class] forKey:@"pushleft"];
    [[DMNavigator pageAnimationRegistry] setObject:[DMPageAnimatePopRight class] forKey:@"popright"];
    [[DMNavigator pageAnimationRegistry] setObject:[DMPageAnimatePushTop class] forKey:@"pushtop"];
    [[DMNavigator pageAnimationRegistry] setObject:[DMPageAnimatePopBottom class] forKey:@"popbottom"];
    [[DMNavigator pageAnimationRegistry] setObject:[DMPageAnimateMagicMove class] forKey:@"magicmove"];
}

-(DMPage*) resolvePage:(NSString*)url {
    DMPage* page       = nil;
    Class clazz        = nil;
    DMUrlInfo* urlInfo = [DMUrlDecoder decodeUrl:url];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:shouldOverridePageClass:)]) {
        clazz = [self.delegate navigator:self shouldOverridePageClass:url];
        if (clazz != nil) {
            DMDebug(@"Navigator will use custom class '%@' return by delegate for url '%@'",NSStringFromClass(clazz),url);
        }
    }
    
    if (clazz == nil) {
        if ([@"app" isEqualToString:urlInfo.protocol]) {
            clazz = [[DMNavigator pageRegistry] objectForKey:[urlInfo.appPageName lowercaseString]];
            // 如果该名称的页面未注册，则直接将名称当做类型名称
            if(clazz == nil) {
                clazz = NSClassFromString(urlInfo.appPageName);
            }
        }
        else if([@"http" isEqualToString:urlInfo.protocol]
                  || [@"https" isEqualToString:urlInfo.protocol]
                  || [@"file" isEqualToString:urlInfo.protocol]
                  ) {
            if (urlInfo.appH5PageName.length>0) {
                clazz = NSClassFromString(urlInfo.appH5PageName);
            }else{
                clazz = [DMWebPage class];
            }
        }
        else if([@"rn" isEqualToString:urlInfo.protocol]){
            if (urlInfo.appH5PageName.length>0) {
                clazz = NSClassFromString(urlInfo.appH5PageName);
            }else{
                clazz = [DMRNPage class];
            }
            
        }
    }
    
    if (clazz) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(navigator:shouldCachePage:)] && [self.delegate navigator:self shouldCachePage:url]) {
            page = [self.pageCache objectForKey:NSStringFromClass(clazz)];
        }
        
        if (page == nil) {
            page = [[clazz alloc] init];
            if ([page respondsToSelector:@selector(pageInit)]) {
                [((id<DMPageLifeCircle>)page) pageInit];
            }
        } else {
            [self.pageCache remove:NSStringFromClass(clazz)];
        }
//        NSLog(@"😂page:%@",page);
        if ([page respondsToSelector:@selector(setNavigator:)]) {
            [((id<DMPageAware>)page) setNavigator:self];
        }
    }
    
    return page;
}

-(id<DMPageAnimate>) resolveAnimation:(NSMutableDictionary*)frameworkParams
                              forward:(BOOL)forward{
    NSString* animateRegistKey = [frameworkParams objectForKey:@"animate"];
    if (animateRegistKey == nil) {
        if(forward) {
            animateRegistKey = @"pushleft";
        } else {
            animateRegistKey = @"popright";
        }
    }
    
    if ([@"null" isEqualToString:animateRegistKey]) {
        return (id)@"null";
    }
    
    Class animateClass = [[DMNavigator pageAnimationRegistry] objectForKey:animateRegistKey];
    return [[animateClass alloc] init];
}

#pragma mark - forward
/*!
 *  跳转到指定的页面
 *
 *  @param url 页面资源定位
 *     可能为app，h5或者RN页面
 *  @param url      页面资源定位
 *  @param callback 页面回调结果
 */
-(void) forward:(NSString*) url {
    [self forward:url context:nil callback:nil];
}

- (void)forward:(NSString *)url context:(NSDictionary *)context {
    [self forward:url context:context callback:nil];
}

-(void) forward:(NSString*)url
       callback:(void(^)(NSDictionary*)) callback {
    
    [self forward:url context:nil callback:callback];
}

- (void)forward:(NSString *)url context:(NSDictionary *)context callback:(void (^)(NSDictionary *))callback {
    if (url == nil || url.length < 1) {
        return;
    }
    __block NSString *blockUrl = url;
    __block NSDictionary *blockContext = context;
    @weakify_self
    galleon_main_async_safe((^{
        @strongify_self
        [self createScreenShot];
        DMUrlInfo* info = [DMUrlDecoder decodeUrl:blockUrl];
        
        // 重定向
        NSString* redirectUrlPath = [[DMNavigator redirectRegistry] objectForKey:info.urlPath];
        if (redirectUrlPath != nil) {
            NSString *paramString = [blockUrl substringFromIndex:info.urlPath.length];
            
            if ([redirectUrlPath rangeOfString:@"#"].location != NSNotFound) {
                if ([paramString rangeOfString:@"?"].location == 0 &&
                    paramString.length > 1) {
                    paramString = [@":" stringByAppendingString:[paramString substringFromIndex:1]];
                }
            }else {
                if ([paramString rangeOfString:@":"].location == 0 &&
                    paramString.length > 1) {
                    paramString = [@"?" stringByAppendingString:[paramString substringFromIndex:1]];
                }
            }
            
            blockUrl = [NSString stringWithFormat:@"%@%@",redirectUrlPath,paramString];
            
            info = [DMUrlDecoder decodeUrl:blockUrl];
        }
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(navigator:shouldForwardTo:)]) {
            BOOL shouldForward = [self.delegate navigator:self shouldForwardTo:blockUrl];
            if (!shouldForward) {
                DMDebug(@"Navigator should not forward to url according to delegate : %@",blockUrl);
                return;
            }
        }
        
        if ([self isJumpEnable:info]) {
            [self jump:blockUrl context:blockContext callback:callback];
            return;
        }
        
        DMDebug(@"Navigator will forward to url : %@",blockUrl)
        
        DMPage* from    = (DMPage*)[self topPage];
        DMPage* to      = (DMPage*)[self resolvePage:blockUrl];
        id<DMPageAnimate> animate = [self resolveAnimation:info.frameworkParams forward:YES];
        
        if (to == nil || animate == nil) {
            if ([from respondsToSelector:@selector(canNotForwardUrl:)]) {
                [from canNotForwardUrl:blockUrl];
            }
            return;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(initPageArguments:toPage:)]) {
            [self.delegate initPageArguments:from toPage:to];
        }
        info.pageContext = blockContext;
        info.prePageUrl = from.pageUrl;
        info.pagePos = [self.pageStack count]+1;
        info.prePos = [self.pageStack count];
        
        DMPageHolder* page = [self prepareNewPage:to withUrl:info andCallback:callback];
        
        [self pushPageToStack:page];
        
        if ([from respondsToSelector:@selector(pageWillBeHidden)]) {
            [((id<DMPageLifeCircle>)from) pageWillBeHidden];
        }
        if ([from respondsToSelector:@selector(pageWillForwardFromMe)]) {
            [((id<DMPageLifeCircle>)from) pageWillForwardFromMe];
        }
        if ([to respondsToSelector:@selector(pageWillBeShown)]) {
            [((id<DMPageLifeCircle>)to) pageWillBeShown];
        }
        if ([to respondsToSelector:@selector(pageWillForwardToMe)]) {
            [((id<DMPageLifeCircle>)to) pageWillForwardToMe];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:willChangePageTo:)]) {
            [self.delegate navigator:self willChangePageTo:to.pageUrl];
        }
        
        BOOL isRealAnimateClass = YES;
        if ([animate isKindOfClass:[NSString class]] && [(NSString *)animate isEqualToString:@"null"]) {
            isRealAnimateClass = NO;
        }
        
        if (from != nil && to != nil && isRealAnimateClass) {
            self.pageAnimationForward = YES;
            self.pageAnimation = animate;
            if (self.pageAnimationFrom == nil) {
                self.pageAnimationFrom = from;
            }
            self.pageAnimationTo = to;
            
            [self performPageAnimation];
        } else {
            [self removeAllFromTree];
            [self addPageToTree:to];
            if ([from respondsToSelector:@selector(pageDidHidden)]) {
                [((id<DMPageLifeCircle>)from) pageDidHidden];
            }
            if ([from respondsToSelector:@selector(pageDidForwardFromMe)]) {
                [((id<DMPageLifeCircle>)from) pageDidForwardFromMe];
            }
            
            if ([to respondsToSelector:@selector(pageDidShown)]) {
                [((id<DMPageLifeCircle>)to) pageDidShown];
            }
            if ([to respondsToSelector:@selector(pageDidForwardToMe)]) {
                [((id<DMPageLifeCircle>)to) pageDidForwardToMe];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:didChangedPageTo:)]) {
                [self.delegate navigator:self didChangedPageTo:to.pageUrl];
            }
        }
    }));
}

-(DMPageHolder*) prepareNewPage:(DMPage*) page withUrl:(DMUrlInfo*)info andCallback:(void(^)(NSDictionary*)) callback{
    DMPageHolder* holder = [[DMPageHolder alloc] init];
    holder.pageInstance = page;
    holder.pageUrl = info.url;
    holder.pageName = info.appPageName;
    holder.pagePos = info.pagePos;
    holder.prePageUrl = info.prePageUrl;
    holder.prePos = info.prePos;
    holder.pageParams = info.params;
    holder.pageContext = info.pageContext;
    holder.frameworkParams = info.params;
    holder.pageCallback = callback;
    
    [self autoWareParams:info.params forPage:page];
    return holder;
}

-(void) autoWareParams:(NSDictionary*)params forPage:(UIViewController*)page {
    DMDebug(@"try autoware params to page : %@ ",NSStringFromClass([page class]));
    for (NSString *key in params) {
        NSString* value = params[key];
        DMDebug(@"try autoware param key:%@ value:%@",key,value);
        if ([page isKindOfClass:[DMPage class]]) {
            [((DMPage*)page) warePageParam:value byKey:key];
        }
    }
}

-(BOOL) isJumpEnable:(DMUrlInfo*) info {
    if (info != nil) {
        NSString* value = [info.frameworkParams objectForKey:@"jump"];
        if (value != nil && [@"true" isEqualToString:value]) {
            return YES;
        }
    }
    return NO;
}

-(void) performPageAnimation {
    if (self.pageAnimation != nil) {
        
        DMPage* from = self.pageAnimationFrom;
        DMPage* to = self.pageAnimationTo;
        id<DMPageAnimate> animate = self.pageAnimation;
        
        [self removeAllFromTree];
        if (self.pageAnimationForward) {
            [self addPageToTree:from];
            [self addPageToTree:to];
        } else {
            [self addPageToTree:to];
            [self addPageToTree:from];
        }
        
        from.view.userInteractionEnabled = NO;
        to.view.userInteractionEnabled = NO;
        self.view.userInteractionEnabled=NO;
        @weakify_self
        @weakify(from)
        @weakify(to)
        
        [animate animateFrom:from to:to callback:^{
            @strongify_self
            @strongify(from)
            @strongify(to)
            [self removePageFromTree:strong_from];
            strong_from.view.userInteractionEnabled = YES;
            strong_to.view.userInteractionEnabled = YES;
            self.view.userInteractionEnabled=YES;
            
            if ([strong_from respondsToSelector:@selector(pageDidHidden)]) {
                [((id<DMPageLifeCircle>)strong_from) pageDidHidden];
            }
            if ([strong_from respondsToSelector:@selector(pageDidForwardFromMe)]) {
                if (self.pageAnimationForward) {
                    [((id<DMPageLifeCircle>)strong_from) pageDidForwardFromMe];
                } else {
                    [((id<DMPageLifeCircle>)strong_from) pageDidBackwardFromMe];
                }
            }
            if ([strong_to respondsToSelector:@selector(pageDidShown)]) {
                [((id<DMPageLifeCircle>)strong_to) pageDidShown];
            }
            if ([strong_to respondsToSelector:@selector(pageDidForwardToMe)]) {
                if (self.pageAnimationForward) {
                    [((id<DMPageLifeCircle>)strong_to) pageDidForwardToMe];
                } else {
                    [((id<DMPageLifeCircle>)strong_to) pageDidBackwardToMe];
                }
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:didChangedPageTo:)]) {
                [self.delegate navigator:self didChangedPageTo:to.pageUrl];
            }
            
            self.pageAnimationFrom = nil;
        }];
        self.pageAnimation = nil;
    }
}

- (void)dragging:(UIPanGestureRecognizer *)recognizer
{
    NSLog(@"调用滑动手势");
    if(!self.isSlideBack){
        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
        return;};
    if(self.pageStack.count <= 1){
        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
        return;};
    CGFloat tx = [recognizer translationInView:self.view].x;
    if(tx < 0)
    {
        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
        return;
    }
    CGRect mainScreen = [[UIScreen mainScreen]bounds];
    if(recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled|| recognizer.state == UIGestureRecognizerStateFailed) {
        
        @weakify_self
        CGFloat x = self.view.frame.origin.x;
        if (x >= mainScreen.size.width * 0.3) {
            [UIView animateWithDuration:0.25 animations:^{
                @strongify_self
                self.view.transform = CGAffineTransformMakeTranslation(mainScreen.size.width, 0);
                self.lastPageView.transform = CGAffineTransformMakeTranslation(-mainScreen.size.width/2.0, 0);
            } completion:^(BOOL finished) {
                @strongify_self
                [self backward:@"@animate=null"];
                
            }];
        }else{
            [UIView animateWithDuration:0.25 animations:^{
                @strongify_self
                self.view.transform = CGAffineTransformMakeTranslation(0, 0);
                self.lastPageView.transform = CGAffineTransformMakeTranslation(0, 0);
            }completion:^(BOOL finished) {
                @strongify_self
                [self removeScreenShot:NO];
            }];
        }
    }else if(recognizer.state == UIGestureRecognizerStateChanged){
        
        //tx(view移动的距离相对左屏幕)/mainSreen.siez.width(view最终移动的距离)=(lastPageView移动的距离相对左屏幕)/-（mainScreen.size.width/2.0）(lastPageView最终移动的距离)
        
        self.view.transform = CGAffineTransformMakeTranslation(tx, 0);
        [self addScreenShotToWindow];
        self.lastPageView.transform = CGAffineTransformMakeTranslation(-(tx/2.0), 0);
        
        
    }else if (recognizer.state==UIGestureRecognizerStateBegan){
        if (self.isSlideBack&&self.isSlideAddShadow) {
            [self topPage].view.layer.shadowColor = [UIColor blackColor].CGColor;
            [self topPage].view.layer.shadowOpacity = 0.3f;
            [self topPage].view.layer.shadowRadius = 4.f;
            [self topPage].view.layer.shadowOffset = CGSizeMake(-4,-4);
        }
    }
}

- (void)removeScreenShot:(BOOL)isRemoveImage{
    [self.lastPageView removeFromSuperview];
    self.lastPageView=nil;
    self.view.transform = CGAffineTransformMakeTranslation(0, 0);
    if (isRemoveImage) {
        [self.screenImages removeLastObject];
    }
}

- (void)removeAllScreenShot{
    NSRange range = NSMakeRange (1,self.screenImages.count-1);
    [self.screenImages removeObjectsInRange:range];
    [self.lastPageView removeFromSuperview];
    self.lastPageView=nil;
}

- (void)addScreenShotToWindow{
    self.lastPageView.image = self.screenImages[self.screenImages.count - 1];
    [self.view insertSubview:self.lastPageView atIndex:0];
}

- (void)createScreenShot
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIGraphicsBeginImageContextWithOptions(self.view.frame.size, YES, 0.0);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.screenImages addObject:image];
}

-(void) putToCache:(DMPage*)page {
    if ([page isKindOfClass:[DMWebPage class]]) {
        if (page && [page respondsToSelector:@selector(pageDestroy)]) {
            [((id<DMPageLifeCircle>)page) pageDestroy];
        }
        return;
    }
    
    // 如果无delegate不缓存任何页面
    if (self.delegate == nil) {
        return;
    }
    
    // 如果delegate明确返回不缓存此页面
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(navigator:shouldCachePage:)]
        && ![self.delegate navigator:self shouldCachePage:page.pageUrl]) {
        if (page && [page respondsToSelector:@selector(pageDestroy)]) {
            [((id<DMPageLifeCircle>)page) pageDestroy];
        }
        return;
    }
    
    [self.pageCache setObject:page forKey:NSStringFromClass(page.class)];
}

#pragma mark - jump
-(void) jump:(NSString*)url {
    [self jump:url context:nil callback:nil];
}

-(void) jumpStackTo:(DMPageHolder*) page {
    for (DMPageHolder* pageHolder in self.pageStack) {
        [self putToCache:pageHolder.pageInstance];
    }
    [self.pageFlowStack removeAllObjects];
    [self.pageStack removeAllObjects];
    [self.pageStack addObject:page];
    [self removeAllScreenShot];
}

-(void) jump:(NSString*)url
     context:(NSDictionary *)context
    callback:(void(^)(NSDictionary* ))callback {
    DMUrlInfo* info = [DMUrlDecoder decodeUrl:url];
    DMPage* from    = [self topPage];
    DMPage* to      = [self resolvePage:url];
    
    id<DMPageAnimate> animate = [self resolveAnimation:info.frameworkParams forward:YES];
    
    if (to == nil || animate == nil) {
        DMError(@"Navigator can not jump due to unresolved page instance for url: %@",url);
        if ([from respondsToSelector:@selector(canNotForwardUrl:)]) {
            [from canNotForwardUrl:url];
        }
        return;
    }
    
    DMDebug(@"Navigator will jump to url : %@",url);
    info.pageContext = context;
    info.prePageUrl = from.pageUrl;
    info.pagePos = [self.pageStack count]+1;
    info.prePos = [self.pageStack count];
    
    DMPageHolder* page = [self prepareNewPage:to withUrl:info andCallback:callback];
    
    [self pushPageToStack:page];
    
    if ([from respondsToSelector:@selector(pageWillBeHidden)]) {
        [((id<DMPageLifeCircle>)from) pageWillBeHidden];
    }
    if ([from respondsToSelector:@selector(pageWillForwardFromMe)]) {
        [((id<DMPageLifeCircle>)from) pageWillForwardFromMe];
    }
    if ([to respondsToSelector:@selector(pageWillBeShown)]) {
        [((id<DMPageLifeCircle>)to) pageWillBeShown];
    }
    if ([to respondsToSelector:@selector(pageWillForwardToMe)]) {
        [((id<DMPageLifeCircle>)to) pageWillForwardToMe];
    }
    
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:willChangePageTo:)]) {
        [self.delegate navigator:self willChangePageTo:to.pageUrl];
    }
    
    BOOL isRealAnimateClass = YES;
    if ([animate isKindOfClass:[NSString class]] && [(NSString *)animate isEqualToString:@"null"]) {
        isRealAnimateClass = NO;
    }
    if (from != nil && to != nil && isRealAnimateClass) {
        self.pageAnimationForward = YES;
        self.pageAnimation = animate;
        if (self.pageAnimationFrom == nil) {
            self.pageAnimationFrom = from;
        }
        self.pageAnimationTo = to;
        
        @weakify_self
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify_self
            [self performPageAnimation];
        });
        
    } else {
        @weakify_self
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify_self
            [self removeAllFromTree];
            [self addPageToTree:to];
            [self jumpStackTo:page];
            if ([from respondsToSelector:@selector(pageDidHidden)]) {
                [((id<DMPageLifeCircle>)from) pageDidHidden];
            }
            if ([from respondsToSelector:@selector(pageDidForwardFromMe)]) {
                [((id<DMPageLifeCircle>)from) pageDidForwardFromMe];
            }
            if ([to respondsToSelector:@selector(pageDidShown)]) {
                [((id<DMPageLifeCircle>)to) pageDidShown];
            }
            if ([to respondsToSelector:@selector(pageDidForwardToMe)]) {
                [((id<DMPageLifeCircle>)to) pageDidForwardToMe];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:didChangedPageTo:)]) {
                [self.delegate navigator:self didChangedPageTo:to.pageUrl];
            }
        });
    }
    
}

-(void) callback:(NSString*)param {
    DMPageHolder* topPage = [self topPageHolder];
    if(topPage.pageCallback != nil) {
        DMUrlInfo* info = [DMUrlDecoder decodeParams:param];
        topPage.pageCallback(info.params);
    }
}

#pragma mark - backward
-(void) backward {
    [self backward:nil pageCount:1 context:nil];
}

-(void) backward:(NSString *)param {
    [self backward:param pageCount:1 context:nil];
}

- (void)backward:(NSString *)param context:(NSDictionary *)context {
    [self backward:param pageCount:1 context:context];
}

- (void)backward:(NSString *)param pageCount:(NSInteger)count {
    [self backward:param pageCount:count context:nil];
}

- (void)backward:(NSString *)param pageCount:(NSInteger)count context:(NSDictionary *)context {
    if (count <= 0) {
        return;
    }
    __block NSString *blockParam = param;
    __block NSDictionary *blockContext = context;
    galleon_main_async_safe((^{
        DMPageHolder* from    = [self topPageHolder];
        DMPageHolder* to      = [self topPageHolder:count];
        
        if (to == nil) {
            DMDebug(@"Navigator can not backward due to empty page stack");
            return;
        }
        DMDebug(@"Navigator will backward with return param : %@",param);
        
        [self backwardFrom:from to:to param:blockParam context:blockContext];
    }));
}

-(void) backwardFrom:(DMPageHolder*)fromHolder to:(DMPageHolder*)toHolder param:(NSString*) param context:(NSDictionary *)context {
    DMDebug(@"backwardFrom %@ to %@",NSStringFromClass(fromHolder.pageInstance.class),NSStringFromClass(toHolder.pageInstance.class));
    
    if ([toHolder.pageInstance respondsToSelector:@selector(replaceStateUrl)] && toHolder.pageInstance.replaceStateUrl && toHolder.pageInstance.replaceStateUrl.length > 0) {
        //处理replace标记页面
        DMPage* toPage      = (DMPage*)[self resolvePage:toHolder.pageInstance.replaceStateUrl];
        if (toPage != nil) {
            //callback 在替换页面的时候可能会引出问题，如果被替换的页面到下一个页面存在回掉
            //后面会进行页面检查和回掉检查以避免出现问题
            DMUrlInfo* info = [DMUrlDecoder decodeUrl:toHolder.pageInstance.replaceStateUrl];
            info.pageContext = toHolder.pageContext;
            info.pagePos = toHolder.pagePos;
            info.prePageUrl = toHolder.prePageUrl;
            info.prePos = toHolder.prePos;
            
            NSInteger count = [self.pageStack indexOfObject:toHolder];
            toHolder = [self prepareNewPage:toPage withUrl:info andCallback:toHolder.pageCallback];
            
            [self putToCache:toHolder.pageInstance];
            [self.pageStack replaceObjectAtIndex:self.pageStack.count-1-count withObject:toHolder];
        }
    }
    
    toHolder.pageContext = context;
    DMUrlInfo* info = [DMUrlDecoder decodeParams:param];
    
    toHolder.prePos = fromHolder.pagePos;
    toHolder.prePageUrl = fromHolder.pageUrl;
    
    DMPage* from = fromHolder.pageInstance;
    DMPage* to = toHolder.pageInstance;
    
    /*
     * 此处用于处理前页的刷新
     */
    if (to != nil && [to respondsToSelector:@selector(pageReload)]) {
        [to pageReload];
    }
    
    id<DMPageAnimate> animate = [self resolveAnimation:info.frameworkParams forward:NO];
    
    /**
     * 确保在页面的事件通知之前将参数传递出去
     */
    if (from != nil
        && fromHolder.pageCallback != nil
        && info != nil
        && info.params != nil
        && info.params.count > 0) {
        fromHolder.pageCallback(info.params);
    }
    
    if ([to respondsToSelector:@selector(pageWillBeShown)]) {
        [((id<DMPageLifeCircle>)to) pageWillBeShown];
    }
    if ([to respondsToSelector:@selector(pageWillBackwardToMe)]) {
        [((id<DMPageLifeCircle>)to) pageWillBackwardToMe];
    }
    if ([from respondsToSelector:@selector(pageWillBeHidden)]) {
        [((id<DMPageLifeCircle>)from) pageWillBeHidden];
    }
    if ([from respondsToSelector:@selector(pageWillBackwardFromMe)]) {
        [((id<DMPageLifeCircle>)from) pageWillBackwardFromMe];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:willChangePageTo:)]) {
        [self.delegate navigator:self willChangePageTo:to.pageUrl];
    }
    
    BOOL isRealAnimateClass = YES;
    if ([animate isKindOfClass:[NSString class]] && [(NSString *)animate isEqualToString:@"null"]) {
        isRealAnimateClass = NO;
    }
    
    if (from != nil && to != nil && isRealAnimateClass) {
        self.pageAnimationForward = NO;
        self.pageAnimation = animate;
        if (self.pageAnimationFrom == nil) {
            self.pageAnimationFrom = from;
        }
        self.pageAnimationTo = to;
    
        [self performPageAnimation];
        [self removeScreenShot:YES];

    } else {
        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
        self.pageAnimationTo = nil;
        [self removeAllFromTree];
        [self addPageToTree:toHolder.pageInstance];
        
        if ([to respondsToSelector:@selector(pageDidShown)]) {
            [((id<DMPageLifeCircle>)to) pageDidShown];
        }
        if ([to respondsToSelector:@selector(pageDidBackwardToMe)]) {
            [((id<DMPageLifeCircle>)to) pageDidBackwardToMe];
        }
        if ([from respondsToSelector:@selector(pageDidHidden)]) {
            [((id<DMPageLifeCircle>)from) pageDidHidden];
        }
        if ([from respondsToSelector:@selector(pageDidBackwardFromMe)]) {
            [((id<DMPageLifeCircle>)from) pageDidBackwardFromMe];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:didChangedPageTo:)]) {
            [self.delegate navigator:self didChangedPageTo:to.pageUrl];
        }
        [self removeScreenShot:YES];
    }
    [self popPageFromStackTo:toHolder.pageInstance];
}

#pragma mark - replace
- (void)replace:(NSString *)url {
    [self replace:url callback:nil];
}

- (void)replace:(NSString *)url context:(NSDictionary *)context {
    [self replace:url context:context callback:nil];
}

- (void)replace:(NSString *)url callback:(void(^)(NSDictionary* ))callback {
    [self replace:url context:nil callback:callback];
}

- (void)replace:(NSString *)url context:(NSDictionary *)context callback:(void (^)(NSDictionary *))callback {
    __block NSString *blockUrl = url;
    __block NSDictionary *blockContext = context;
    
    @weakify_self
    galleon_main_async_safe((^{
        @strongify_self
        DMUrlInfo* info = [DMUrlDecoder decodeUrl:blockUrl];
        DMPageHolder *replacedHolder = [self topPageHolder];
        DMPage* from    = (DMPage*)[self topPage];
        DMPage* to      = (DMPage*)[self resolvePage:blockUrl];
        
        // 重定向
        NSString* redirectUrlPath = [[DMNavigator redirectRegistry] objectForKey:info.urlPath];
        if (redirectUrlPath != nil) {
            NSString *paramString = [blockUrl substringFromIndex:info.urlPath.length];
            
            if ([redirectUrlPath rangeOfString:@"#"].location != NSNotFound) {
                if ([paramString rangeOfString:@"?"].location == 0 &&
                    paramString.length > 1) {
                    paramString = [@":" stringByAppendingString:[paramString substringFromIndex:1]];
                }
            }else {
                if ([paramString rangeOfString:@":"].location == 0 &&
                    paramString.length > 1) {
                    paramString = [@"?" stringByAppendingString:[paramString substringFromIndex:1]];
                }
            }
            
            blockUrl = [NSString stringWithFormat:@"%@%@",redirectUrlPath,paramString];
            
            info = [DMUrlDecoder decodeUrl:blockUrl];
        }
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(navigator:shouldForwardTo:)]) {
            BOOL shouldForward = [self.delegate navigator:self shouldForwardTo:blockUrl];
            if (!shouldForward) {
                DMDebug(@"Navigator should not forward to url according to delegate : %@",blockUrl);
                return;
            }
        }
        
        if ([self isJumpEnable:info]) {
            [self jump:blockUrl context:blockContext callback:callback];
            return;
        }
        
        DMDebug(@"Navigator will forward to url : %@",blockUrl)
        info.pageContext = blockContext;
        info.prePageUrl = from.pageUrl;
        info.pagePos = [self.pageStack count]+1;
        info.prePos = [self.pageStack count];
        
        DMPageHolder* page = [self prepareNewPage:to withUrl:info andCallback:callback];
        
        [self pushPageToStack:page];
        
        id<DMPageAnimate> animate = [self resolveAnimation:info.frameworkParams forward:YES];
        
        if ([from respondsToSelector:@selector(pageWillBeHidden)]) {
            [((id<DMPageLifeCircle>)from) pageWillBeHidden];
        }
        if ([from respondsToSelector:@selector(pageWillForwardFromMe)]) {
            [((id<DMPageLifeCircle>)from) pageWillForwardFromMe];
        }
        if ([to respondsToSelector:@selector(pageWillBeShown)]) {
            [((id<DMPageLifeCircle>)to) pageWillBeShown];
        }
        if ([to respondsToSelector:@selector(pageWillForwardToMe)]) {
            [((id<DMPageLifeCircle>)to) pageWillForwardToMe];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:willChangePageTo:)]) {
            [self.delegate navigator:self willChangePageTo:to.pageUrl];
        }
        
        if (from != nil && to != nil && animate != nil) {
            self.pageAnimationForward = YES;
            self.pageAnimation = animate;
            if (self.pageAnimationFrom == nil) {
                self.pageAnimationFrom = from;
            }
            self.pageAnimationTo = to;
            
            [self performPageAnimation];
            
            if (replacedHolder != nil) {
                [self putToCache:replacedHolder.pageInstance];
                [self.pageStack removeObject:replacedHolder];
            }
        } else {
            [self removeAllFromTree];
            [self addPageToTree:to];
            if ([from respondsToSelector:@selector(pageDidHidden)]) {
                [((id<DMPageLifeCircle>)from) pageDidHidden];
            }
            if ([from respondsToSelector:@selector(pageDidForwardFromMe)]) {
                [((id<DMPageLifeCircle>)from) pageDidForwardFromMe];
            }
            
            if ([to respondsToSelector:@selector(pageDidShown)]) {
                [((id<DMPageLifeCircle>)to) pageDidShown];
            }
            if ([to respondsToSelector:@selector(pageDidForwardToMe)]) {
                [((id<DMPageLifeCircle>)to) pageDidForwardToMe];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(navigator:didChangedPageTo:)]) {
                [self.delegate navigator:self didChangedPageTo:to.pageUrl];
            }
        }
    }));
}

#pragma mark - push-pop
/*!
 *  开启一个子业务流程
 */
-(void) pushFlow {
    DMPageHolder* topPage = [self topPageHolder];
    if (topPage == nil) {
        DMError(@"push flow failed due to top page nil");
        return;
    }
    DMError(@"push flow => page : %@",NSStringFromClass(topPage.pageInstance.class));
    [self.pageFlowStack addObject:topPage];
}

/*!
 *  结束当前子业务流程，同时页面跳转回之前pushFlow的地方
 */
-(void) popFlow:(NSString*)param {
    [self popFlow:param context:nil];
}

- (void)popFlow:(NSString *)param context:(NSDictionary *)context {
    __block NSString *blockParam = param;
    __block NSDictionary *blockContext = context;
    
    @weakify_self
    galleon_main_async_safe((^{
        @strongify_self
        DMPageHolder* from    = [self topPageHolder];
        DMPageHolder* to      = [self topFlowPageHolder:0];
        if (from == nil || to == nil) {
            if (from == nil) {
                DMError(@"popFlow failed due to frompage nil");
            } else {
                DMError(@"popFlow failed due to topage nil");
            }
            return;
        }
        DMDebug(@"popFlow from %@ to %@",NSStringFromClass(from.pageInstance.class),NSStringFromClass(to.pageInstance.class));
        [self.pageFlowStack removeLastObject];
        [self backwardFrom:from to:to param:blockParam context:blockContext];
    }));
}

#pragma mark - control ui
-(void) removeAllFromTree {
    for (UIViewController* sub in self.childViewControllers) {
        [sub.view removeFromSuperview];
        [sub removeFromParentViewController];
    }
}

-(void) removePageFromTree:(UIViewController*) page {
    if (page == nil) {
        return;
    }
    [page.view removeFromSuperview];
    [page removeFromParentViewController];
}

-(void) addPageToTree:(UIViewController*) page {
    if(page == nil) {
        return;
    }
    [self addChildViewController:page];
    [self.view addSubview:page.view];
}

-(DMPageHolder*) topPageHolder {
    DMPageHolder* holder = [self.pageStack lastObject];
    return holder;
}

-(DMPageHolder*) topPageHolder:(int) deep {
    if (self.pageStack.count < deep + 1) {
        return nil;
    }
    DMPageHolder* holder = self.pageStack[self.pageStack.count-deep-1];
    return holder;
}

-(DMPage*) topPage {
    return self.topPageHolder.pageInstance;
}

-(DMPage*) topPage:(int) deep {
    return [self topPageHolder:deep].pageInstance;
}

-(void) rollup {
    DMPage* page = self.topPage;;
    if (page) {
        [page pageRollup];
    }
}

-(DMPage*) topFlowPage:(int) deep {
    return [self topFlowPageHolder:deep].pageInstance;
}

-(DMPageHolder*) topFlowPageHolder:(int) deep {
    if (self.pageFlowStack.count < deep + 1) {
        return nil;
    }
    return self.pageFlowStack[self.pageFlowStack.count-deep-1];
}

-(void) pushPageToStack : (DMPageHolder*) pageHolder {
    [self.pageStack addObject:pageHolder];
}

-(void) popPageFromStackTo: (UIViewController*) targetPage {
    while (self.topPage != targetPage && self.pageStack.count > 0) {
        DMPageHolder* pageHolder = self.pageStack.lastObject;
        [self putToCache:pageHolder.pageInstance];
        [self.pageStack removeLastObject];
    }
}

#pragma mark - register page-url
/*!
 *  注册本地页面
 *
 *  @param name      本地页面的标识符(例如标识符:Payment, 其他页面通过app://Payment来访问)
 *  @param pageClass 页面实现类的class属性(例如Payment如果实现类为DMPayment的话，通过[DMPayment class]来指定)
 */
+(void) registAppPage:(NSString*)name
            pageClass:(Class)pageClass {
    
    [self.pageRegistry setValue:pageClass forKey:[name lowercaseString]];
}

+(void) registRedirectFromUrl:(NSString*)fromUrl toUrl:(NSString*)toUrl {
    [[DMNavigator redirectRegistry] setObject:toUrl forKey:fromUrl];
}

@end
