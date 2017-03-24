//
//  DKUpdateSource.h
//  Deck
//
//  Created by 兵兵 刘 on 16/9/21.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "WTSourceSetting.h"
#import "WTDownLoadEntity.h"
typedef NS_ENUM(NSInteger,WTUpdateSourceType) {
    WTUpdateSourceTypeRN=0,//RN
    WTUpdateSourceTypeH5=1,//H5
    WTUpdateSourceTypeJson=2,//配置
    WTUpdateSourceTypeCustom=3,//自定义资源
    WTUpdateSourceTypeOther//其他
};
@protocol  WTUpdateSource<NSObject>
@end
@interface WTUpdateSource : WTDownLoadEntity
@property(nonatomic,strong) NSString *dir;
@property(nonatomic,assign) WTUpdateSourceType type;
@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSString *link;
@property(nonatomic,strong) NSString *version;
@property(nonatomic,strong) WTSourceSetting *setting;
@property(nonatomic,assign) BOOL isUnZip;//是否解压
@property(nonatomic,strong) NSString *typeStr;
@property(nonatomic,strong) NSString *idstr;
/**
 获取解压到本地的地址
 
 @return 返回解压地址全路径
 */
-(NSString*)getUnzipToPath;

/**
 获取解压文件全路径

 @return 返回解压全路径地址
 */
-(NSString*)getUnzipFromFile;

/**
 获取下载到本地零时目录

 @return 返回目录全路径
 */
-(NSString*)getLoadLocalPath;

/**
 判断是否是相同的soure模块资源

 @param source 比较的模块资源
 @return 相同返回true。不相同返回flase
 */
-(BOOL) isSameSouece:(WTUpdateSource*)source;
@end
