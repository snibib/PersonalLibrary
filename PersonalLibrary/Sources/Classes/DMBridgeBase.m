//
//  DMBridgeBase.m
//  Dmall
//
//  Created by 杨涵 on 16/8/1.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridgeBase.h"
#import "DMJavascript_js.h"

@implementation DMBridgeBase
{
    __weak id _webViewDelegate;
    long _uniqueId;
}

static bool logging = false;
static int logMaxLength = 500;

+ (void)enableLogging { logging = true; }
+ (void)setLogMaxLength:(int)length { logMaxLength = length; }

- (instancetype)init {
    self = [super init];
    self.messageHandlers = [NSMutableDictionary dictionary];
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    _uniqueId = 0;
    return (self);
}

- (void)dealloc {
    self.startupMessageQueue = nil;
    self.responseCallbacks = nil;
    self.messageHandlers = nil;
}

- (void)reset {
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    _uniqueId = 0;
}

- (void)sendData:(id)data responseCallback:(ResponseCallback)responseCallback handlerName:(NSString *)handlerName {
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString *callbackId = [NSString stringWithFormat:@"objc_cb_%ld",++_uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    
    [self _queueMessage:message];
}

- (void)flushMesageQueue:(NSString *)messageQueueString {
    if (messageQueueString == nil || messageQueueString.length == 0) {
        NSLog(@"如果bridge的js并未注入webview，那么oc从webview中查询消息json的时候会得到nil，例如webview加载了一个新页面");
        return;
    }
    
    id messages = [self _deserializeMessageJSON:messageQueueString];
    for (Message *message in messages) {
        if (![message isKindOfClass:[Message class]]) {
            NSLog(@"无效类 %@ 收到消息 %@", [message class],message);
            continue;
        }
        [self _log:@"received" json:message];
        
        NSString *responseId = message[@"responseId"];
        if (responseId) {
            ResponseCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        }else {
            ResponseCallback responseCallback = NULL;
            NSString *callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    Message *msg = @{ @"responseId":callbackId, @"responseData":responseData };
                    [self _queueMessage:msg];
                };
            }else {
                responseCallback = ^(id ignoreResponseData) {
                    
                };
            }

            Handler handler = self.messageHandlers[message[@"handlerName"]];
            if (!handler) {
                NSLog(@"并未从js获得消息句柄: %@",message);
                continue;
            }
            handler(message[@"data"], responseCallback);
        }
    }
}

- (void)injectJavascriptFile {
    NSString *jscode = JavascriptCodeString();
    [self _evaluateJavascript:jscode];
    if (self.startupMessageQueue) {
        NSArray *queue = self.startupMessageQueue;
        self.startupMessageQueue = nil;
        for (id queueMessage in queue) {
            [self _dispatchMessage:queueMessage];
        }
    }
}

- (BOOL)isCorrectProtocolScheme:(NSURL *)url {
    if ([[url scheme] isEqualToString:@"personal"]) {
        return YES;
    }else {
        return NO;
    }
}

- (BOOL)isQueueMessageUrl:(NSURL *)url {
    if ([[url host] isEqualToString:@"__queue_message__"]) {
        return  YES;
    }else {
        return NO;
    }
}

- (BOOL)isBridgeLoadedUrl:(NSURL *)url {
    return ([[url scheme] isEqualToString:@"personal"] && [[url host] isEqualToString:@"__bridge_loaded"]);
}

- (void)logUnkownMessage:(NSURL *)url {
    NSLog(@"收到未定义指令:%@://%@",@"personal",[url path]);
}

- (NSString *)webViewJavascriptCheckCommand {
    return @"typeof WebViewJavaScriptBridge == \'object\';";
}

- (NSString *)webViewJavascriptFetchQueryCommand {
    return @"WebViewJavaScriptBridge._fetchQueue();";
}

- (void)disableJavascriptAlertBoxSafetyTimeout {
    [self sendData:nil responseCallback:nil handlerName:@"_disableJavascriptAlertBoxSafetyTimeout"];
}

#pragma mark - private
- (void)_evaluateJavascript:(NSString *)javascriptCommand {
    if (self.delegate && [self.delegate respondsToSelector:@selector(_evaluateJavascript:)]) {
        [self.delegate _evaluateJavascript:javascriptCommand];
    }
}

- (void)_queueMessage:(Message *)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    }else {
        [self _dispatchMessage:message];
    }
}

- (void)_dispatchMessage:(Message *)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    [self _log:@"send" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString *javascriptCommand = [NSString stringWithFormat:@"WebViewJavaScriptBridge._handleMessageFromObjc('%@');",messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evaluateJavascript:javascriptCommand];
    }else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evaluateJavascript:javascriptCommand];
        });
    }
}

- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

- (NSArray *)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

- (void)_log:(NSString *)action json:(id)json {
    if (!logging) {
        return;
    }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json pretty:YES];
    }
    if ([json length] > logMaxLength) {
        NSLog(@"%@: %@[...]",action,[json substringToIndex:logMaxLength]);
    }else {
        NSLog(@"%@: %@",action, json);
    }
}

@end
