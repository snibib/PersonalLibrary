//
//  WTPathUtil.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/13.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WTPathUtil : NSObject
/**
 *  否存在对应文件
 *  @return 存在YES，否则NO
 */
+ (BOOL)isExistsFileAtPath:(NSString*)path;

/**
 是否存在文件夹

 @param path 文件夹路径
 @return 存在YES，否则NO
 */
+ (BOOL)isExistsFolderAtPath:(NSString*)path;


/**
 获取document目录下的目录全路径，如果有这个目录不存在会创建对应的目录
 目录创建失败或者其他失败返回nil
 @param path 例如： /folder1/folder2/folder3
 @return docoment全路径/folder1/folder2/folder3
 */
+ (NSString *)getDocumentPathStr:(NSString*)path;

/**
 获取Document目录

 @return 返回全路径
 */
+(NSString*)getDocumentPath;

/**
 分割路径，获取对应的文件夹名字

 @param path 带/的路径全名
 @return 文件夹名字集合
 */
+(NSArray*)segmentationPath:(NSString*)path;

/**
 根据文件夹名字生成路径地址（不生成文件）
 @param pathNames 文件夹名字
 @return 包含document全路径（不生成文件）
 */
+ (NSString *)getDocumentPathFromPaths:(NSArray*)paths;

/**
 获取文件加下的所有文件

 @param path 文件夹全路径
 @return 文件名字
 */
+ (NSArray*) getFilesFromFolder:(NSString*)path;
@end
