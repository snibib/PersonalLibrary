//
//  DMCache.h
//  dmall
//
//  Created by chenxinxin on 2015-11-16.
//  Copyright (c) 2014 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @header DMCache.h
            KV缓存,基于leveldb实现的KV数据库缓存,支持本地持久化存储数据,提供高效高性能的KV存取服务
*/

/*!
    @class DMCache
           KV缓存,基于leveldb实现的KV数据库缓存,支持本地持久化存储数据,提供高效高性能的KV存取服务
 */

@interface DMCache : NSObject
/*!
 *  @method putData:forKey:
 *          向缓存中存数数据
 *  @param  data
 *          将缓存的字节数据
 *  @param  key
 *          缓存的key
 */
-(void) setData:(NSData*) data forKey:(NSString*) key;
/*!
 *  @method getDataByKey:
 *          从缓存中读取指定key的字节数据
 *  @param  key
 *          缓存key
 *  @return 返回缓存的数据
 */
-(NSData*) dataForKey:(NSString*) key;
/*!
 *  @method remove:
 *          从缓存中删除指定key的字符串
 */
-(void) removeDataForKey:(NSString*) key;

/*!
 *  获取缓存实例
 *
 *  @return 缓存实例
 */
+(DMCache*) getInstance;
@end
