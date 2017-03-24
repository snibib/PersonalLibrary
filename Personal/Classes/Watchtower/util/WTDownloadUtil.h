//
//  WTDownloadUtil.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/13.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WTUpdateSource.h"
typedef NS_ENUM(NSInteger,WTLoadErrorCode) {
    WTLoadDefaultSuccessCode,         //默认成功code
    WTLoadErrorCodeNull,       //下载地址为空
    WTLoadErrorCodeNonMatch,   //下载大小不匹配
    WTLoadErrorCodeNet,        //网络出错
    WTLoadErrorCodeSource,     //下载资源出错，包括没有下载连接、下载大小、下载本地地址
    WTLoadErrorCodeContentNull     //下载资源内容为空
};
@interface WTDownloadUtil : NSObject

/**
 下载资源，并保存在document目录下指定位置

 @param sources 资源信息集合对象
 @param complete 全部下载完成回调
 @param loadError 只有有资源下载失败的回调函数
 */
+ (void)downLoadSources:(NSArray<WTUpdateSource *>*)sources
              complete:(void (^)(WTUpdateSource *))complete
             loadError:(void (^)(WTLoadErrorCode code,NSArray<WTUpdateSource *>*))loadError;

/**
 下载资源但是不保存在本地，返回data数据

 @param path 下载链接地址
 @param complete 下载完成回调函数
 @param loadError 下载失败回调
 */
+ (void)downLoadSource:(NSString *)source
              complete:(void (^)(NSData *data))complete
             loadError:(void (^)(WTLoadErrorCode code))loadError;
@end
