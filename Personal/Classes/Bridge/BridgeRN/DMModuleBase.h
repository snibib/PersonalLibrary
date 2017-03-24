//
//  DMModuleBase.h
//  Galleon
//
//  Created by 杨涵 on 2017/3/20.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import <React/RCTEventEmitter.h>

@class DMNavigator;
@class DKStorage;

@interface DMModuleBase : RCTEventEmitter

@property(weak, nonatomic)       DMNavigator        *navigator;
@property(weak, nonatomic)       DKStorage          *storage;
@property(nonatomic, assign)     BOOL               hasListener;

/*!
 * 获取module单例,需要子类复写
 */
+ (instancetype)getInstance;

/*!
 * 配置支持的调用事件,默认为空,子类可重写
 */
- (NSArray<NSString *> *)supportedEvents;

/*!
 * 原生调用rn方法(通过字典进行数据传递),默认不调用,子类可重写
 */
- (void)sendEventMessage:(NSDictionary *)message;

@end
