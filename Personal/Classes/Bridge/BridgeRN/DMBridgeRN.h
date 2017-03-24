//
//  DMBridgeRN.h
//  DMAppNavigator
//
//  Created by 杨涵 on 16/8/9.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>

@interface DMBridgeRN : NSObject

@property(nonatomic, strong)    RCTBridge       *innerBridge;
@property(nonatomic, strong)    NSURL           *sourceUrl;

/*!
 * 获得bridge实例
 */
+ (instancetype) rnBridge;

@end
