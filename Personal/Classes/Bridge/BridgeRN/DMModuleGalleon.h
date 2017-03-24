//
//  DMModuleGalleon.h
//  Galleon
//
//  Created by 杨涵 on 2017/3/14.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "DMModuleBase.h"
#import <React/RCTBridgeModule.h>

@interface DMModuleGalleon : DMModuleBase <RCTBridgeModule>

/*!
 * 配置支持的调用事件
 */
- (NSArray<NSString *> *)supportedEvents;

/*!
 * 原生调用rn方法(通过字典进行数据传递)
 */
- (void)sendEventMessage:(NSDictionary *)message;

@end
