//
//  WTDownLoadEntity.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/13.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
@interface WTDownLoadEntity : JSONModel

/**
 下载地址
 */
@property(nonatomic,strong) NSString *wt_url;

/**
 资源大小
 */
@property(nonatomic,strong) NSString *wt_size;
/**
 资源名字
 */
@property(nonatomic,strong) NSString *wt_name;

/**
 下载到本地地址目录
 */
@property(nonatomic,strong) NSString *wt_localPath;


@end
