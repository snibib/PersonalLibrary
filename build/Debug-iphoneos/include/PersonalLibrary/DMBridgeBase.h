//
//  DMBridgeBase.h
//  Dmall
//
//  Created by 杨涵 on 16/8/1.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ResponseCallback)(id responseData);
typedef void (^Handler)(id data, ResponseCallback responseCallback);
typedef NSDictionary Message;

@protocol DMBridgeBaseDelegate <NSObject>

- (NSString *) _evaluateJavascript:(NSString *)javascriptCommand;

@end

@interface DMBridgeBase : NSObject

@property (weak, nonatomic) id <DMBridgeBaseDelegate> delegate;
@property (strong, nonatomic) NSMutableArray    *startupMessageQueue;
@property (strong, nonatomic) NSMutableDictionary *responseCallbacks;
@property (strong, nonatomic) NSMutableDictionary *messageHandlers;
@property (strong, nonatomic) Handler              messageHandler;

+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;
- (void)reset;
- (void)sendData:(id)data responseCallback:(ResponseCallback)responseCallback handlerName:(NSString *)handlerName;
- (void)flushMesageQueue:(NSString *)messageQueueString;
- (void)injectJavascriptFile;
- (BOOL)isCorrectProtocolScheme:(NSURL *)url;
- (BOOL)isQueueMessageUrl:(NSURL *)url;
- (BOOL)isBridgeLoadedUrl:(NSURL *)url;
- (void)logUnkownMessage:(NSURL *)url;
- (NSString *)webViewJavascriptCheckCommand;
- (NSString *)webViewJavascriptFetchQueryCommand;
- (void)disableJavascriptAlertBoxSafetyTimeout;

@end
