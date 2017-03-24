//
//  DMBridgeHelper.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DMBridgeProtocol.h"

@interface DMBridgeHelper : NSURLProtocol

+ (DMBridgeHelper *)getInstance;

/*!
 *  注册桥接对象
 *
 *  @param bridgeObject 桥接对象
 *  此时是以brigeObject的对象名字作为key进行存储
 */
- (void)registBridge:(id<DMBridgeProtocol>)bridgeObject;

/*!
 *  绑定webView
 *  需要在绑定webView之前将所有的桥接对象注册到DMBridgeHelper中去
 *
 *  @param webView 待绑定的webView
 */
- (void)bindWebView:(UIWebView *)webView;

/*!
 *  注册桥接对象
 */
- (void)registBridge:(id<DMBridgeProtocol>)bridgeObject forWebView:(UIWebView *)webView;
/*!
 * 设置host，用于判断请求是否希望从本地获得数据
 */
- (void)setNativeSourceHosts:(NSDictionary *)hostMap;

/*!
 * 设置url，添加对该url的信任，让url的请求能获得本地的数据，以解决跨域问题
 */
- (void)setAccessControlOrigin:(NSArray *)urls;

@end
