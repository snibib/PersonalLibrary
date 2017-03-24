//
//  DMJSPageBridge.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMJSPageBridge.h"
#import "DMPage.h"
#import "DMUrlEncoder.h"
#import "DMNavigator.h"
#import "DKStorage.h"

@implementation DMJSPageBridge

- (NSString *)javascriptObjectName {
    return @"window.pageBridge";
}

- (void)forward:(NSString *)url {
    [self.navigator forward:url callback:^(NSDictionary *param) {
        NSString* str = [DMUrlEncoder encodeParams:param];
        [self.jsPage stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"com.dmall.Bridge.appPageCallback(\"%@\")",str]];
    }];
}

- (void)backward:(NSString *)param {
    [self.navigator backward:param];
}

- (void)pushFlow {
    [self.navigator pushFlow];
}

- (void)popFlow:(NSString *)param {
    [self.navigator popFlow:param];
}

- (void)callback:(NSString *)param {
    [self.navigator callback:param];
}

- (void)registRedirect:(NSString *)fromUrl :(NSString *)toUrl {
    [DMNavigator registRedirectFromUrl:fromUrl toUrl:toUrl];
}

- (NSString *)topPage:(int)deep {
    return [((DMPage *)[[DMNavigator getInstance] topPage:deep]) pageUrl];
}

- (void)rollup {
    [self.navigator rollup];
}

- (void)set:(NSString *)dataStr :(NSString *)key {
    if (dataStr == nil || dataStr.length == 0 || key == nil || key.length == 0) {
        return;
    }
    NSData *valueData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.storage set:valueData forKey:key];
}

- (NSString *)get:(NSString *)key {
    
    if (key == nil || key.length == 0) {
        return @"[[nil]]";
    }
    NSData *valueData = [self.storage get:key];
    if (valueData == nil) {
        return @"[[nil]]";
    }
    
    NSString *str = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
    return str;
}

- (void)remove:(NSString *)key {
    [self.storage remove:key];
}

- (void)setContext:(NSString *)context {
    DMPage *currentPage = self.navigator.topPage;
    if (context == nil || context.length == 0) {
        currentPage.pageContext = nil;
        return;
    }
    NSData *valueData = [context dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *contextDic = [NSJSONSerialization JSONObjectWithData:valueData options:NSJSONReadingAllowFragments error:nil];
    currentPage.pageContext = contextDic;
}

- (NSString *)getContext {
    DMPage *currentPage = self.navigator.topPage;
    if (currentPage.pageContext) {
        NSData *valueData = [NSJSONSerialization dataWithJSONObject:currentPage.pageContext options:NSJSONReadingAllowFragments error:nil];
        return [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
    }
    return @"[[nil]]";
}

@end
