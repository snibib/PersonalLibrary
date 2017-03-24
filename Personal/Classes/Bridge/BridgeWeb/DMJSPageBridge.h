//
//  DMJSPageBridge.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridgeObject.h"
#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol DMDeckNavigatorJSExport <JSExport>

- (void)forward:(NSString *)url;
- (void)backward:(NSString *)param;
- (void)pushFlow;
- (void)popFlow:(NSString *)param;
- (void)callback:(NSString *)param;
- (void)registRedirect:(NSString *)fromUrl :(NSString *)toUrl;
- (NSString *)topPage:(int)deep;
- (void)rollup;

@end

@protocol DMDeckStorageJSExport <JSExport>

- (void)set:(NSString *)dataStr :(NSString *)key;
- (NSString *)get:(NSString *)key;
- (void)remove:(NSString *)key;

/*!
 * 上下文转json字符串后存取
 */
- (void)setContext:(NSString *)context;
- (NSString *)getContext;

@end

@interface DMJSPageBridge : DMBridgeObject <DMDeckNavigatorJSExport, DMDeckStorageJSExport>

@property (nonatomic, weak) UIWebView                   *jsPage;

@end
