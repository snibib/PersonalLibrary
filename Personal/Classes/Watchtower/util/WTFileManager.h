//
//  WTFileManager.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/20.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WTFileManager : NSObject

/**
 判断数据是否是zip文件

 @param data 文件数据
 @return 是返回YES，否则NO
 */
+ (BOOL)isZip:(NSData*)data;
/**
 *  文件拷贝
 *  @param fromPath 拷贝文件目录
 *  @param toPath   拷贝到目录
 */
+ (BOOL)copyFile:(NSString*)fromPath toPath:(NSString*)toPath;
/**
 *  解压
 *  @param fromPath 解压文件目录
 *  @param toPath   解压到目录
 */
+ (BOOL)unzipfile:(NSString*)fromPath toPath:(NSString*)toPath ;

/**
 移除文件

 @param path 文件地址
 @return 移除成功返回YES，否则NO
 */
+(BOOL)removeFile:(NSString*)path;
@end
