//
//  DMBridgeProtocol.h
//  Deck
//
//  Created by 杨涵 on 2016/12/14.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * 此协议定义暴露给js调用的接口
 */
@protocol DMBridgeProtocol <NSObject>

/*!
 * 提供当前bridge在js中调用的对象名称
 */
@required
- (NSString *)javascriptObjectName;

@end
