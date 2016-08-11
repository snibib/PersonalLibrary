//
//  DMBridge.m
//  Dmall
//
//  Created by 杨涵 on 16/8/1.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridge.h"

@implementation DMBridge
{
    __weak UIWebView *_webView;
    __weak id _webViewDelegate;
    long _uniqueId;
    DMBridgeBase *_base;
}

+ (void)enableLogging {
    [DMBridgeBase enableLogging];
}

+ (void)setLogMaxLength:(int)length {
    [DMBridgeBase setLogMaxLength:length];
}

+ (instancetype)bridgeForWebView:(UIWebView *)webView {
    DMBridge *bridge = [[self alloc] init];
    bridge->_webView = webView;
    bridge->_webView.delegate = bridge;
    bridge->_base = [[DMBridgeBase alloc] init];
    bridge->_base.delegate = bridge;
    return bridge;
}

- (void)setWebViewDelegate:(NSObject<UIWebViewDelegate> *)webViewDelegate {
    _webViewDelegate = webViewDelegate;
}

- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(ResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:handlerName];
}

- (void)registerHandler:(NSString *)handlerName handler:(Handler)handler{
    _base.messageHandlers[handlerName] = [handler copy];
}

- (void)disableJavaScriptAlertBoxSafetyTimeout {
    [_base disableJavascriptAlertBoxSafetyTimeout];
}

- (void)dealloc {
    _webView.delegate = nil;
    _base = nil;
    _webView = nil;
    _webViewDelegate = nil;
}

- (NSString *)_evaluateJavascript:(NSString *)javascriptCommand {
    return [_webView stringByEvaluatingJavaScriptFromString:javascriptCommand];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView != _webView) {
        return;
    }
    
    __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [strongDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (webView != _webView) {
        return;
    }
    
    __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [strongDelegate webView:webView didFailLoadWithError:error];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (webView != _webView) {
        return YES;
    }
    
    __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
    NSURL *url = [request URL];
    if ([_base isCorrectProtocolScheme:url]) {
        if ([_base isBridgeLoadedUrl:url]) {
            [_base injectJavascriptFile];
        }else if ([_base isQueueMessageUrl:url]) {
            NSString *messageQueueString = [self _evaluateJavascript:[_base webViewJavascriptFetchQueryCommand]];
            [_base flushMesageQueue:messageQueueString];
        }else {
            [_base logUnkownMessage:url];
        }
        return NO;
    }else if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [strongDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (webView != _webView) {
        return;
    }
    
    __strong NSObject<UIWebViewDelegate> *strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [strongDelegate webViewDidStartLoad:webView];
    }
}

@end
