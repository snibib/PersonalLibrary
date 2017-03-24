//
//  DMPage.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMPage.h"
#import "DMLog.h"
#import "DMStringUtils.h"
#import "DMReflectUtil.h"

@interface DMPage ()

@end

@implementation DMPage

@synthesize navigator;
@synthesize pageCallback;
@synthesize pageParams;
@synthesize pageContext;
@synthesize frameworkParams;
@synthesize pageUrl;
@synthesize pageName;
@synthesize replaceStateUrl;
@synthesize pagePos;
@synthesize prePos;
@synthesize prePageUrl;

DMLOG_DEFINE(DMPage)

-(NSDictionary*) magicMoveSet {return nil;}


-(void) warePageParam:(NSString*)value byKey:(NSString*)key {
    NSString* setterName = [NSString stringWithFormat:@"set%@:",[DMStringUtils firstToUpper:key]];
    SEL setterMethod = NSSelectorFromString(setterName);
    if([self respondsToSelector:setterMethod]) {
        NSMethodSignature* methodSign = [[self class] instanceMethodSignatureForSelector:setterMethod];
        const char * argType = [methodSign getArgumentTypeAtIndex:2];
        DMDebug(@"autoware param key:%@ value:%@ type:%s",key,value,argType);
        NSNumber* number = [DMReflectUtil numberFromString:value signature:argType];
        if (number) {
            [self setValue:number forKey:key];
        } else {
            [self setValue:value forKey:key];
        }
    } else {
        DMDebug(@"skip param key:%@ value:%@",key,value);
    }
}


-(void) log:(NSString*)msg {
    DMDebug(@"%@ => %@",msg,NSStringFromClass(self.class))
}

-(void) pageInit {
    [self log:@"pageInit"];
}

-(void) pageDestroy {
    [self log:@"pageDestroy"];
}
/*!
 *  当页面即将向前切换到当前页面时调用
 */
-(void) pageWillForwardToMe {
    [self log:@"pageWillForwardToMe"];
}
/*!
 *  当页面已经向前切换到当前页面时调用
 */
-(void) pageDidForwardToMe{
    [self log:@"pageDidForwardToMe"];
}
/*!
 *  当页面即将向前离开当前页面时调用
 */
-(void) pageWillForwardFromMe{
    [self log:@"pageWillForwardFromMe"];
}
/*!
 *  当页面已经向前切换离开当前页面时调用
 */
-(void) pageDidForwardFromMe{
    [self log:@"pageDidForwardFromMe"];
}
/*!
 *  当页面即将向后回退到当前页面时调用
 */
-(void) pageWillBackwardToMe{
    [self log:@"pageWillBackwardToMe"];
}
/*!
 *  当页面已经向后回退到当前页面时调用
 */
-(void) pageDidBackwardToMe{
    [self log:@"pageDidBackwardToMe"];
}
/*!
 *  当页面即将后退离开当前页面时调用
 */
-(void) pageWillBackwardFromMe{
    [self log:@"pageWillBackwardFromMe"];
}

/*!
 *  当页面已经后退离开当前页面时调用
 */
-(void) pageDidBackwardFromMe{
    [self log:@"pageDidBackwardFromMe"];
}
/*!
 *  当页面即将展示时调用(包含页面前进和回退)
 */
-(void) pageWillBeShown{
    [self log:@"pageWillBeShown"];
    
    NSLog(@"%@",[self.navigator pageStack]);
}
/*!
 *  当页面已经展示时调用(包含页面前进和后退)
 */
-(void) pageDidShown{
    [self log:@"pageDidShown"];
}
/*!
 *  当页面即将隐藏(包含页面前进和后退)
 */
-(void) pageWillBeHidden{
    [self log:@"pageWillBeHidden"];
}

/*!
 *  当页面已经隐藏(包含前进和后退)
 */
-(void) pageDidHidden{
    [self log:@"pageDidHidden"];
}

-(void) pageRollup {
    [self log:@"pageRollup"];
}

-(void) anchorBack {
    [self log:@"anchorBack"];
}

-(void)pageReload {
    [self log:@"pageReload"];
}

/*!
 *  跳转到指定的页面
 *
 *  @param url 页面资源路径
 *     可能为app，h5或者RN页面
 */
-(void) forward:(NSString*)url {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator forward:url];
}

- (void)forward:(NSString *)url context:(NSDictionary *)context {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator forward:url context:context];
}
/*!
 *  跳转到指定的页面
 *
 *  @param url      页面资源路径
 *  @param callback 页面回调接口
 */
-(void) forward:(NSString* )url
       callback:(void(^)(NSDictionary* ))callback {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator forward:url callback:callback];
}

- (void)forward:(NSString *)url contetxt:(NSDictionary *)context callback:(void (^)(NSDictionary *))callback {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator forward:url context:context callback:callback];
}
/**
 * 触发页面回退
 * @param param 可选返回参数，允许携带框架参数(参数名以@开头)。（例如"param=value&param2=value2&@animate=popright"）
 *     如果不传此参数，框架将在页面回退的同时不向上一个页面的回传数据。
 *     这样做的目的，是允许开发者在当前页面其他时机去主动调用callback回传数据，
 *     避免页面传参和页面回退动作绑死。
 */

-(void) backward {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator backward];
}

-(void) backward:(NSString*)param {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator backward:param];
}

- (void)backward:(NSString *)param context:(NSDictionary *)context {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator backward:param context:context];
}

- (void)backward:(NSString *)param pageCount:(NSInteger)count {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator backward:param pageCount:count];
}

- (void)backward:(NSString *)param pageCount:(NSInteger)count context:(NSDictionary *)context {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator backward:param pageCount:count context:context];
}

- (void)replace:(NSString *)url {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator replace:url];
}

- (void)replace:(NSString *)url context:(NSDictionary *)context {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator replace:url context:context];
}

- (void)replace:(NSString *)url callback:(void (^)(NSDictionary *))callback {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator replace:url callback:callback];
}

- (void)replace:(NSString *)url context:(NSDictionary *)context callback:(void (^)(NSDictionary *))callback {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator replace:url context:context callback:callback];
}
/**
 * 单独向上一个页面回传参数的接口
 * @param param 参数 （例如"param=value&param2=value2"）
 */
-(void) callback:(NSString*)param {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator callback:param];
}

/*!
 *  开启一个子业务流程
 */
-(void) pushFlow {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator pushFlow];
}
/*!
 *  结束当前子业务流程，同时页面跳转回之前pushFlow的地方
 */
-(void) popFlow:(NSString*)param {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator popFlow:param];
}

- (void)popFlow:(NSString *)param context:(NSDictionary *)context {
    if (self != self.navigator.topPage) {
        return;
    }
    [self.navigator popFlow:param context:context];
}

@end
