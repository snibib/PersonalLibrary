//
//  DMCacheObject.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMCacheObject : NSObject

/*!
 * 指定容量大小进行初始化，缓存超过容量则会自动删除就数据
 * @param size 容量
 */
- (instancetype)initWithCap:(int)size;

/*!
 * 通过关键字存储数据
 * @param value 存储对象
 * @param key 存储关键字
 */
- (void)setObject:(id)value forKey:(NSString*)key;

/*!
 * 获取存储对象
 * @param key 存储关键字
 */
- (id)objectForKey:(NSString*)key;

/*!
 * 删除指定存储对象
 * @param key 存储关键字
 */
- (void)remove:(NSString*)key;

@end
