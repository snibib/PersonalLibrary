//
//  WTUpdateUtil.h
//  Lookout
//
//  Created by 兵兵 刘 on 2016/11/28.
//  Copyright © 2016年 兵兵 刘. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WTChartsRequest.h"
typedef NS_OPTIONS(NSUInteger, WTLogFlag){
    /**
     *  0...00001 WTLogFlagError
     */
    WTLogFlagError      = (1 << 0),
    
    /**
     *  0...00010 WTLogFlagWarning
     */
    WTLogFlagWarning    = (1 << 1),
    
    /**
     *  0...00100 WTLogFlagInfo
     */
    WTLogFlagInfo       = (1 << 2),
    
    /**
     *  0...01000 WTLogFlagDebug
     */
    WTLogFlagDebug      = (1 << 3),
    
    /**
     *  0...10000 WTLogFlagVerbose
     */
    WTLogFlagVerbose    = (1 << 4)
};
typedef NS_ENUM(NSUInteger, WTLogLevel) {
    /**
     *  No logs
     */
    WTLogLevelOff       = 0,
    
    /**
     *  Error logs only
     */
    WTLogLevelError     = (WTLogFlagError),
    
    /**
     *  Error and warning logs
     */
    WTLogLevelWarning   = (WTLogLevelError   | WTLogFlagWarning),
    
    /**
     *  Error, warning and info logs
     */
    WTLogLevelInfo      = (WTLogLevelWarning | WTLogFlagInfo),
    
    /**
     *  Error, warning, info and debug logs
     */
    WTLogLevelDebug     = (WTLogLevelInfo    | WTLogFlagDebug),
    
    /**
     *  Error, warning, info, debug and verbose logs
     */
    WTLogLevelVerbose   = (WTLogLevelDebug   | WTLogFlagVerbose),
    
    /**
     *  All logs (1...11111)
     */
    WTLogLevelAll       = NSUIntegerMax
    
};

/**
 解压文件后回调的枚举

 - WTDoneAfterUnzipTypeGoHome: 回首页
 */
typedef NS_ENUM(NSInteger,WTDoneAfterUnzipType) {
    WTDoneAfterUnzipTypeGoHome=0,//回首页
    WTDoneAfterUnzipTypeRestartApp=1,//重启APP
    WTDoneAfterUnzipTypeNotDo=2,//不做任何操作
    WTDoneAfterUnzipTypeOther
};
//目录文件夹名字
static NSString *const SourceDic             = @"sourcedir";          //资源总目录，下面的资源都在这个目录下面
static NSString *const JonsLocalPath         = @"json";               //json资源对应Document主目录--document/SourceDic/JonsLocalPath
static NSString *const RNLocalPath           = @"rn";                 //RN对应Document主目录--document/SourceDic/RNLocalPath
static NSString *const H5LocalPath           = @"h5";                 //h5对应Document主目录--document/SourceDic/H5LocalPath
static NSString *const CustomLocalPath       = @"custom";             //custom(其他自定义目录)对应Document主目录--document/SourceDic/CustomLocalPath
static NSString *const ServerMapPath         = @"/sourcedir/json/galleon/map";                //服务器map 映射文件--document/SourceDic/JonsLocalPath/galleon/map
static NSString *const ServerHostPath        = @"/sourcedir/json/galleon/host";               //服务器host文件主目录--document/SourceDic/JonsLocalPath/gallon/host

static NSString *const LocalTmpPath          = @"WTTmpPath";            //zip，json包下载Document主目录--document/SourceDic/LocalTmpPath

//保存本地对应的key值
static NSString *const WTSourceDicVersion        = @"WTSourceDicVersion";           //所有资源的对应的APP 版本号 key
static NSString *const WTAvailableMapName        = @"WTAvailableMapJsonPath.json";  //可用map 映射文件 key
static NSString *const serverUpdateInfoName      = @"serverUpdateInfoName.json"; //服务器下载更新配置key  value WTChartsResponse 对象--保存在NSUserDefaults key
static NSString *const localUpdateInfoName       = @"localUpdateInfoName.json";  //保存本地的更新配置key  value WTChartsResponse 对象--保存在NSUserDefaults key

//一些预定义名字
static NSString *const localVersionInfoName    = @"localVersionInfo";  //打包的时候基础版本配置 json名字
static NSString *const WTAvailableMap          = @"map.json";          //可用map 映射文件名字  注意在打包更新map映射的时候，必须定义map.json
static NSString *const WTHostConfigName        = @"host.json";         //拦截域名设置，必须定义host.json
static NSInteger const WTReLoadingCount        = 3;         //下载失败重新请求次数

@interface WTUpdateUtil : NSObject
@property(nonatomic,strong) NSString *mapName;//打包初始化map文件名字
+ (instancetype)sharedInstance;
/**
 设置SDK中日志打印基本。默认不打印日志
 
 @param logLevel 日志级别枚举
 */
- (void)setLogLevel:(WTLogLevel)logLevel;


/**
 请求灯塔更新接口。阻塞的loading view 必须加载到window上面，不然滑动返回手势依然有效。

 @param updateJsonPath 请求灯塔地址
 @param showLoading 显示loading回调，会多次回调
 @param hiddenLoading 隐藏loading回调，会多次调用
 @param doAfterUnzip  隐藏解压包回调，会多次调用
 @param complete 下载完成后回调
 @param loadError 下载出错回调，如果在解压或者其它错误也会回调
 */
- (void)startUpdate:(WTChartsRequest *)chartsRequest
        showLoading:(void (^)())showLoading
      hiddenLoading:(void (^)())hiddenLoading
       doAfterUnzip:(void (^)(WTDoneAfterUnzipType type))doAfterUnzip
           complete:(void (^)())complete
          loadError:(void (^)(NSString *message))loadError;







- (NSString*)h5ResponsePath:(NSString*)url;

/**
 请求本地h5资源
 @param url 路径地址
 @param folder 资源查找路径
 @return 如果本地或者包中存在该地址，就会返回全路径；否则为null
 */
- (NSString*)h5ResponsePath:(NSString*)url folder:(NSString*)folder;

/*!
 * 返回本地react bundle 代码资源地址
 */
- (NSString *)bundleCodePath:(NSString*)bundlePath;

/*!
 * 返回本地react bundle 图片资源地址
 */
- (NSString *)bundleImagePath:(NSString*)bundlePath;

- (NSString*)getAppVersion;

/**
 清除本地资源
 */
- (void)cleanFile;
@end
