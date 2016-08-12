//
//  DMBridge.h
//  Dmall
//
//  Created by 杨涵 on 16/8/1.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DMBridgeBase.h"
#import <JSONModel/JSONModel.h>

@interface DMBridge : NSObject <UIWebViewDelegate, DMBridgeBaseDelegate>

+ (instancetype)bridgeForWebView:(UIWebView *)webView;
+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;

- (void)registerHandler:(NSString *)handlerName handler:(Handler)handler;
- (void)callHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName data:(id)data;
- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(ResponseCallback)responseCallback;
- (void)setWebViewDelegate:(NSObject<UIWebViewDelegate> *)webViewDelegate;
- (void)disableJavaScriptAlertBoxSafetyTimeout;

@end
