//
//  DKStorage.h
//  Deck
//
//  Created by 杨涵 on 16/8/2.
//  Copyright © 2016年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKStorage : NSObject

+ (instancetype) getInstance;


/**
 保存、更新、修改数据，注意：如果key是链式形式的话，保存的objectData必须为JSON 类型的字符串。否则不会成功
 如果是字符串链式：需要这样转换NSData *data = [NSJSONSerialization dataWithJSONObject:@"大大大多大" options:NSJSONReadingAllowFragments error:nil]; 不能这么定义：NSData *data = [@"大师傅" dataUsingEncoding:NSUTF8StringEncoding];
 
 @param objectData 对象值
 @param key 关键字,前后不能存在.如（.liu.liu.）,不能出现连续..如（liu..liu）。正确方式 例如 @“test” , @“test.liu”, @“test.liu.liu.liu.liu”
 @return 存储成功
 */
- (BOOL) set:(NSData *)objectData forKey:(NSString *)key;

/*!
 *  @method 取值
 *  @param key:关键字
 */
- (NSData *) get:(NSString *)key;

/*!
 *  @method 删除数据
 *  @param key:关键字
 */
- (BOOL) remove:(NSString *)key;

/**
 json对象转 NSData数据格式
 如果转换失败返回nil
 @param object json对象
 @return NSData数据
 */
-(NSData*)dataWithJSONObject:(id)object;

@end
