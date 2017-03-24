//
//  WTUpdateUtil2.m
//  Lookout
//
//  Created by 兵兵 刘 on 2016/11/28.
//  Copyright © 2016年 兵兵 刘. All rights reserved.
//

#import "WTUpdateUtil.h"
#import <UIKit/UIKit.h>
#import "WTLog.h"
#import "WTFileManager.h"
#import "DMNavigator.h"
#import "WTSourceSetting.h"
#import "WTSourceUpdate.h"
#import "WTSourceUnzip.h"
#import "WTUpdateListInfo.h"
#import "WTUpdateSource.h"
#import "WTChartsResponse.h"
#import "WTChartsSetting.h"
#import "WTDownloadUtil.h"
#import "WTPathUtil.h"
#import "DMUrlDecoder.h"
#import "DMBridgeHelper.h"
#import "DKHttpClient.h"
#import "DKStorageUtil.h"
#define WTUserDefaultsSet(data,key) [[NSUserDefaults standardUserDefaults] setObject:data forKey:key]
#define WTUserDefaultsGet(key) [[NSUserDefaults standardUserDefaults] objectForKey:key]
#define WTUserDefaultsRemove(key) [[NSUserDefaults standardUserDefaults] removeObjectForKey:key]

@interface WTUpdateUtil()
@property (nonatomic, copy ) void (^showLoadingBlock)();//m文件
@property (nonatomic, copy ) void (^hiddenLoadingBlock)();//m文件
@property (nonatomic, copy ) void (^completeBlock)();//m文件
@property (nonatomic, copy ) void (^doAfterUnZip)(WTDoneAfterUnzipType type);//解压之后需要做的事
@property (nonatomic, copy ) void (^loadErrorBlock)(NSString *message);//m文件
@property (nonatomic, strong) WTChartsRequest *request;//请求灯塔对象
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger reLoadCount;
@property (nonatomic, assign) BOOL isLoadDone;//本次下载是否下载完
@end


@implementation WTUpdateUtil
#pragma mark 实例化对象
static WTUpdateUtil *sharedInstance;

+ (instancetype)sharedInstance {
    static dispatch_once_t WTUpdateUtilOnceToken;
    dispatch_once(&WTUpdateUtilOnceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init {
    if (sharedInstance != nil) {
        return nil;
    }
    if ((self = [super init])) {
        _isLoadDone=true;
        _reLoadCount=0;
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

#pragma mark 前后台通知

/**
 进入后台，触发方法
 */
- (void)enterBackground{
    WTDebug(@"进入后台");
    [[WTUpdateUtil sharedInstance] scanLoadUnzip:WTUnzipTypeEnterBackground];
    [self isDoRequestLitghHose:WTRequestTypeEnterBackground];
}

/**
 回到前台，触发方法
 */
- (void)enterForeground{
    WTDebug(@"进入前台");
    [[WTUpdateUtil sharedInstance] scanLoadUnzip:WTUnzipTypeWakeup];
    [self isDoRequestLitghHose:WTRequestTypeEnterFore];
}



#pragma mark timer
/**
 创建请求灯塔接口，定时器，循环请求
 @param time 请求灯塔时间间隔，单位秒
 */
- (void)createTimer:(NSInteger)time{
    
    if ([WTUpdateUtil sharedInstance].timer==nil) {
        [WTUpdateUtil sharedInstance].timer = [NSTimer timerWithTimeInterval:time target:[WTUpdateUtil sharedInstance] selector:@selector(timerRequestLigtHose) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:[WTUpdateUtil sharedInstance].timer forMode:NSRunLoopCommonModes];
    }else{
        if (time==[WTUpdateUtil sharedInstance].timer.timeInterval) {
            return;
        }else{
            [[WTUpdateUtil sharedInstance].timer invalidate];
            [WTUpdateUtil sharedInstance].timer = nil;
            [WTUpdateUtil sharedInstance].timer = [NSTimer timerWithTimeInterval:time target:[WTUpdateUtil sharedInstance] selector:@selector(timerRequestLigtHose) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:[WTUpdateUtil sharedInstance].timer forMode:NSRunLoopCommonModes];
        }
    }
    
}

/**
 定时器触发方法
 */
- (void)timerRequestLigtHose{
    if ([WTUpdateUtil sharedInstance].isLoadDone) {
        WTDebug(@"定时器定时请求开始");
        [self doRequestLitghHose:[WTUpdateUtil sharedInstance].request];
    }
}



#pragma mark map映射

/**
 检查对应的跳转地址，是否存在。如果是网络请求不用检查（不存在可以抛到线上请求）
 
 @param url 请求，例如：app://DMHome  or  rn://detail/detail.ios.jsbundle/test  or http://baidu.com
 @return 资源存在返回YES ,否则NO
 */
-(BOOL)checkURL:(NSString*)url{
    DMUrlInfo *urlInfo = [DMUrlDecoder decodeUrl:url];
    Class clazz        = nil;
    if (clazz == nil) {
        if ([@"app" isEqualToString:urlInfo.protocol]) {
            clazz = NSClassFromString(urlInfo.appPageName);
            if (clazz) {
                return YES;
            }
            
        } else if([@"http" isEqualToString:urlInfo.protocol]
                  || [@"https" isEqualToString:urlInfo.protocol]
                  || [@"file" isEqualToString:urlInfo.protocol]
                  ) {
            return YES;
        }
        else if([@"rn" isEqualToString:urlInfo.protocol]){
            //rn://path/rnbundleName/bundleindex中的模块名对应的名字
            if ([[WTUpdateUtil sharedInstance ] bundleCodePath:[self sourcePath:urlInfo.appPageName]]) {
                return YES;
            }else{
                if ([self bundleUrl:urlInfo.appPageName]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}


/**
 检查rn资源在App包中存在不。注意在APP中大RN模块包的时候，都是bundle 方式。bundle里面就是 XXX.ios.jsbundle 和图片资源
 
 @param pageName 资源URL，一定是大于等于2级 例如：detail/detail.ios.jsbundle/test 或者 detail.ios.jsbundle/test
 @return 资源存在返回YES ,否则NO
 */
- (BOOL)bundleUrl:(NSString*)pageName {
    
    NSString *sourceName = nil;
    NSString *bundleName = nil;
    NSString *subdirectory = nil;
    NSMutableArray *paths = [NSMutableArray arrayWithArray:[[self sourcePath:pageName] componentsSeparatedByString:@"/"]];
    if (paths.count == 1) {
        sourceName = [paths lastObject];
    }else if (paths.count >= 2) {
        bundleName = [paths firstObject];
        sourceName = [paths lastObject];
        [paths removeObjectAtIndex:0];
        [paths removeLastObject];
        subdirectory = [paths componentsJoinedByString:@"/"];
    }
    
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"index.ios" withExtension:@"jsbundle"];
    if (sourceName && sourceName.pathExtension && sourceName.pathExtension.length > 0) {
        NSString *name = [sourceName stringByReplacingOccurrencesOfString:[@"." stringByAppendingString:sourceName.pathExtension] withString:@""];
        NSBundle *bundle = [NSBundle mainBundle];
        
        if (bundleName) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
            bundle = [NSBundle bundleWithPath:bundlePath];
        }
        
        if (subdirectory) {
            bundleURL = [bundle URLForResource:name withExtension:sourceName.pathExtension subdirectory:subdirectory];
        }else {
            bundleURL = [bundle URLForResource:name withExtension:sourceName.pathExtension];
        }
        
    }
    if (bundleURL) {
        return YES;
    }else{
        return NO;
    }
}
/**
 检查rn资源在下载本地中存在不
 
 @param pageName 资源URL，一定是大于等于2级 例如：detail/detail.ios.jsbundle/test 或者 detail.ios.jsbundle/test
 @return 资源存在返回YES ,否则NO
 */
- (NSString *)sourcePath:(NSString*)pageName {
    NSMutableArray *paths = [NSMutableArray arrayWithArray:[pageName componentsSeparatedByString:@"/"]];
    [paths removeLastObject];
    return [paths componentsJoinedByString:@"/"];
}

/**
 设置app 重定向，并立即生效
 */
- (void) checkRedirect{
    NSDictionary *result = [self getAvailableMap];
    WTDebug(@"生效的map映射：%@",result);
    for (NSString *key in result) {
        [DMNavigator registRedirectFromUrl:key toUrl:result[key]];
    }
    
}





#pragma mark 下载

/**
 是否请求灯塔接口
 
 @param type 请求灯塔接口频率枚举WTRequestType
 */
- (void)isDoRequestLitghHose:(NSInteger)type{
    WTChartsResponse *serverLocalversion = [[WTUpdateUtil sharedInstance]getServerUpdateObject];
    if (serverLocalversion!=nil) {
        if (serverLocalversion.setting.time==type) {
            [self doRequestLitghHose:[WTUpdateUtil sharedInstance].request];
        }
    }
}

-(void)setActResponse:(WTChartsResponse *)act{
    if (act.act) {
        [DKStorageUtil setResponseAct:act.act];
    }
    
}
//-()
/**
 请求灯塔数据方法
 @param url 灯塔请求连接
 */
- (void)doRequestLitghHose:(WTChartsRequest *)chartsRequest{
    [self cleanSource];
    [[DKHttpClient shareInstance]connectWithRequest:chartsRequest success:^(DKBaseResponse *response) {
        WTUserDefaultsSet([self getAppVersion],WTSourceDicVersion);
        WTChartsResponse *serverVersionObject = (WTChartsResponse*)response;
        [[WTUpdateUtil sharedInstance]setActResponse:serverVersionObject];
        WTChartsResponse *localVersionObject  = [[WTUpdateUtil sharedInstance]getLocalLKUpdateObject];
        localVersionObject.lastTime = [[NSDate new]timeIntervalSince1970];
        WTUserDefaultsSet(localVersionObject.toJSONData,localUpdateInfoName);
    
        NSMutableArray *newUpdateSourceList    = [[WTUpdateUtil sharedInstance] compareWithLocalVersion:serverVersionObject];
        //需要判断一下，如果返回的版本号一样的话，可以不做下一步请求
        WTUserDefaultsSet([serverVersionObject toJSONData],serverUpdateInfoName);
        if(serverVersionObject.setting.time==WTRequestTypeTime){
            //添加定时器，请求灯塔获取航海图
            [[WTUpdateUtil sharedInstance]createTimer:serverVersionObject.setting.timeInterval];
        }else{
            //移除定时器请求
            [[WTUpdateUtil sharedInstance].timer invalidate];
            [WTUpdateUtil sharedInstance].timer = nil;
        }
        [[WTUpdateUtil sharedInstance] downSources:newUpdateSourceList];
        
    } failure:^(DKBaseResponse *response) {
        WTError(@"更新模块错误：%@",response);
        [[WTUpdateUtil sharedInstance] error:[NSString stringWithFormat:@"请求灯塔接口失败：%@",response.result]];
    } error:^(NSError *error) {
        WTError(@"更新模块错误：网络请求失败");
        [[WTUpdateUtil sharedInstance] error:[NSString stringWithFormat:@"请求灯塔接口失败：%@",error]];
    }];
    
}
/**
 获取需要下载的模块信息
 
 @param serverVersionObject 服务器返回的模块信息全量
 @return 需要下载的模块信息集合
 */
- (NSMutableArray*)compareWithLocalVersion:(WTChartsResponse *)serverVersionObject{
    
    
    WTChartsResponse *localVersionObject = [self getLocalLKUpdateObject];
    if (!localVersionObject) {
        return nil;
    }
    NSMutableArray *newUpdateSourceList = [[NSMutableArray alloc]init];
    for (WTUpdateSource * serverListInfos in serverVersionObject.sources.list) {
        NSString          *serverUpdateVersion= serverListInfos.version;
        BOOL    isExitName = false;
        for (WTUpdateSource *localListInfos in localVersionObject.sources.list) {
            NSString          *localUpdateVersion= localListInfos.version;
            if ([serverListInfos isSameSouece:localListInfos]){
                //找到对应模块
                isExitName = true;
                if (![localUpdateVersion isEqualToString:serverUpdateVersion]){
                    NSString *file = [serverListInfos getUnzipFromFile];
                    if (![WTPathUtil isExistsFileAtPath:file]) {
                        WTUpdateSource *newUpdateSource = [serverListInfos copy];
                        if (newUpdateSource.setting==nil) {
                            newUpdateSource.setting = serverVersionObject.sources.setting;
                        }
                        newUpdateSource.wt_localPath = [serverListInfos getLoadLocalPath];
                        [newUpdateSourceList addObject:newUpdateSource];
                        break;
                    }
                }else{
                    continue;
                }
            }
            else{
                //这儿需要处理一下
            }
        }
        if (!isExitName) {
             NSString *file = [serverListInfos getUnzipFromFile];
            if (![WTPathUtil isExistsFileAtPath:file]) {
                //不存在，必须下载
                WTUpdateSource *newUpdateSource = [serverListInfos copy];
                if (newUpdateSource.setting==nil) {
                    newUpdateSource.setting = serverVersionObject.sources.setting;
                }
                newUpdateSource.wt_localPath = [serverListInfos getLoadLocalPath];
                [newUpdateSourceList addObject:newUpdateSource];
            }
            
        }
    }
    WTDebug(@"需要更新模块个数：%ld \n资源下载内容：%@",newUpdateSourceList.count,newUpdateSourceList);
    return newUpdateSourceList;
}

/**
 对需要下载的模块信息集合分为阻塞或者后台默默下载
 
 @param newUpdateSourceList 需要下载的模块集合
 @return 返回一个集合，集合只有2个对象都是集合。第一对象是需要阻塞下载的文件， 第二个对象是需要后台默默下载的文件
 */
- (NSMutableArray*)classifyUpdateSoureces:(NSMutableArray*)newUpdateSourceList{
    NSMutableArray *classifyUpdateSoureces = [[NSMutableArray alloc]init];
    NSMutableArray *nowUpdateSourceList = [[NSMutableArray alloc]init];
    NSMutableArray *laterUpdateSourceList = [[NSMutableArray alloc]init];
    for (WTUpdateSource *source in newUpdateSourceList) {
        if (source.setting.update.block) {
            [nowUpdateSourceList addObject:source];
        }else{
            [laterUpdateSourceList addObject:source];
        }
    }
    WTDebug(@"需要阻塞下载的文件（%ld个",nowUpdateSourceList.count);
    WTDebug(@"需要后台默默下载的文件（%ld个）",laterUpdateSourceList.count);
    [classifyUpdateSoureces addObject:nowUpdateSourceList];
    [classifyUpdateSoureces addObject:laterUpdateSourceList];
    return classifyUpdateSoureces;
}
-(void)loadError:(NSMutableArray *) newUpdateSourceList message:(NSString*)errorMessage{
    
    if (![[WTUpdateUtil sharedInstance] reDownSources:newUpdateSourceList]) {
        [[WTUpdateUtil sharedInstance] hiddenLoadView];
        [[WTUpdateUtil sharedInstance] error:errorMessage];
    };
    
}
-(void)loadDone{
    [WTUpdateUtil sharedInstance].reLoadCount=0;
    [WTUpdateUtil sharedInstance].isLoadDone = true;
    [[WTUpdateUtil sharedInstance] hiddenLoadView];
    if ([WTUpdateUtil sharedInstance].completeBlock) {
        [WTUpdateUtil sharedInstance].completeBlock();
    }
    
}
-(void)showLoadView{
    if ([WTUpdateUtil sharedInstance].showLoadingBlock) {
        [WTUpdateUtil sharedInstance].showLoadingBlock();
    }
    
    //    [DMNavigator getInstance].isSlideBack = false;
}
-(void)hiddenLoadView{
    if ([WTUpdateUtil sharedInstance].hiddenLoadingBlock) {
        [WTUpdateUtil sharedInstance].hiddenLoadingBlock();
    }
    
    //    [DMNavigator getInstance].isSlideBack = true;
}

-(void)error:(NSString*)message{
    if ([WTUpdateUtil sharedInstance].loadErrorBlock) {
        [WTUpdateUtil sharedInstance].loadErrorBlock(message);
    }
}
-(void)doAfterUnzip:(WTDoneAfterUnzipType)type{
    if ([WTUpdateUtil sharedInstance].doAfterUnZip) {
        [WTUpdateUtil sharedInstance].doAfterUnZip(type);
    }
}
/**
 下载资源失败，重新请求下载。重新下载次数为WTReLoadingCount 值。如果有请求航海图定时器的话，也需要重新请求。
 
 @param newUpdateSourceList 重新下载资源对象集合
 */
- (BOOL)reDownSources:(NSMutableArray *) newUpdateSourceList{
    if ([WTUpdateUtil sharedInstance].reLoadCount<=(WTReLoadingCount-1)) {
        [WTUpdateUtil sharedInstance].reLoadCount++;
        [[WTUpdateUtil sharedInstance]downSources:newUpdateSourceList];
        return YES;
    }
    [WTUpdateUtil sharedInstance].reLoadCount=0;
    [WTUpdateUtil sharedInstance].isLoadDone = true;
    return NO;
}
/**
 下载资源包封装的方法
 
 @param newUpdateSourceList 需要下载的模块信息集合
 */
- (void)downSources:(NSMutableArray *) newUpdateSourceList{
    
    if(newUpdateSourceList.count==0)
    {
        return;
    }
    NSMutableArray *classifyUpdateSoureces = [[WTUpdateUtil sharedInstance] classifyUpdateSoureces:newUpdateSourceList];
    NSMutableArray *nowUpdateSourceList   = classifyUpdateSoureces[0];
    NSMutableArray *laterUpdateSourceList = classifyUpdateSoureces[1];
    
    if (nowUpdateSourceList.count>0) {
        //阻塞下载---必然是阻塞解压
        //非阻塞下载--一般配置为唤醒或者重启阻塞解压，不会配置马上阻塞解压
        [[WTUpdateUtil sharedInstance]showLoadView];
        
        [WTDownloadUtil downLoadSources:nowUpdateSourceList
                               complete:^(WTUpdateSource *entity1){
                                   
                                   if (entity1==nil) {
                                       //判断是否解压--如果是马上下载，必然是阻塞解压
                                       BOOL isRetrun=false;
                                       BOOL isGoHome=false;
                                       for(WTUpdateSource *entity2 in nowUpdateSourceList){
                                           if ([[WTUpdateUtil sharedInstance] isNowUnzipTheLoadPackage:entity2 type:WTUnzipTypeNow]) {
                                               BOOL isUnzip= [[WTUpdateUtil sharedInstance] unzipTheLoadPackage:entity2 isGohome:NO];
                                               if (isUnzip) {
                                                   [[WTUpdateUtil sharedInstance] updateLocalVersion:entity2];
                                                   if (entity2.setting.unzip.unzipMethod==WTDoneAfterUnzipTypeGoHome) {
                                                       isGoHome = true;
                                                   }
                                               }else{
                                                   //解压失败
                                                   isRetrun = true;
                                               }
                                           }else{
                                               //不是马上解压，不用管
                                           }
                                       }
                                       if (isGoHome) {
                                           [[WTUpdateUtil sharedInstance]doAfterUnzip:WTDoneAfterUnzipTypeGoHome];
                                       }
                                       [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                       if (isRetrun) {
                                           
                                           [[WTUpdateUtil sharedInstance] error:@"解压失败"];
                                           //这儿如果有解压失败的文件，还有默默下载的资源不能结束下载 return ;
                                           if(laterUpdateSourceList.count==0)return;
                                       }
                                       
                                       if (laterUpdateSourceList.count>0) {
                                           [WTDownloadUtil downLoadSources:laterUpdateSourceList
                                                                  complete:^(WTUpdateSource *entity3){
                                                                      if (entity3) {
                                                                          if ([[WTUpdateUtil sharedInstance] isNowUnzipTheLoadPackage:entity3 type:WTUnzipTypeNow]) {
                                                                              if(entity3.setting.unzip.block){
                                                                                  //一般后台不会配置非阻塞下载，马上阻塞解压
                                                                                  //同步解压
                                                                                  [[WTUpdateUtil sharedInstance]showLoadView];
                                                                                  BOOL isUnzip= [[WTUpdateUtil sharedInstance] unzipTheLoadPackage:entity3 isGohome:YES];
                                                                                  if (isUnzip) {
                                                                                      [[WTUpdateUtil sharedInstance] updateLocalVersion:entity3];
                                                                                  }else{
                                                                                      //解压失败
                                                                                      [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                                    
                                                                                      [[WTUpdateUtil sharedInstance] error:@"解压失败"];
                                                                                      return ;
                                                                                  }
                                                                                  
                                                                              }else{
                                                                                  //异步解压
                                                                                  BOOL isUnzip= [[WTUpdateUtil sharedInstance] unzipTheLoadPackage:entity3 isGohome:YES];
                                                                                  if (isUnzip) {
                                                                                      [[WTUpdateUtil sharedInstance] updateLocalVersion:entity3];
                                                                                  }else{
                                                                                      //解压失败
                                                                                      [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                                                                      [[WTUpdateUtil sharedInstance] error:@"解压失败"];
                                                                                      return ;
                                                                                  }
                                                                              }
                                                                          }else{
                                                                              //不是马上解压，不用管
                                                                          }
                                                                          [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                                                      }else{
                                                                          
                                                                          [[WTUpdateUtil sharedInstance] loadDone];
                                                                          
                                                                      }
                                                                  }
                                                                 loadError:^(WTLoadErrorCode code,NSArray<WTUpdateSource *>*errorList) {
                                                                     [[WTUpdateUtil sharedInstance]loadError:newUpdateSourceList message:@"下载非阻塞资源失败"];
                                                                 }];
                                       }else{
                                           [[WTUpdateUtil sharedInstance] loadDone];
                                       }
                                   }
                               }
                              loadError:^(WTLoadErrorCode code,NSArray<WTUpdateSource *>*errorList) {
                                  //如果2次下载失败，就不会去下载非阻塞资源了。
                                  [[WTUpdateUtil sharedInstance]loadError:newUpdateSourceList message:@"下载阻塞资源失败"];
                              }];
        
    }else{
        
        if (laterUpdateSourceList.count>0) {
            //非阻塞下载
            [WTDownloadUtil downLoadSources:laterUpdateSourceList
                                   complete:^(WTUpdateSource *entity4){
                                       if (entity4) {
                                           if ([[WTUpdateUtil sharedInstance] isNowUnzipTheLoadPackage:entity4 type:WTUnzipTypeNow]) {
                                               if(entity4.setting.unzip.block){
                                                   //一般后台不会配置非阻塞下载，马上阻塞解压
                                                   //同步解压
                                                   [[WTUpdateUtil sharedInstance]showLoadView];
                                                   BOOL isUnzip= [[WTUpdateUtil sharedInstance] unzipTheLoadPackage:entity4 isGohome:YES];
                                                   if (isUnzip) {
                                                       [[WTUpdateUtil sharedInstance] updateLocalVersion:entity4];
                                                   }else{
                                                       //解压失败
                                                       [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                                       [[WTUpdateUtil sharedInstance] error:@"解压失败"];
                                                       return ;
                                                   }
                                               }else{
                                                   //异步解压
                                                   BOOL isUnzip= [[WTUpdateUtil sharedInstance] unzipTheLoadPackage:entity4 isGohome:YES];
                                                   if (isUnzip) {
                                                       [[WTUpdateUtil sharedInstance] updateLocalVersion:entity4];
                                                   }else{
                                                       //解压失败
                                                       [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                                      [[WTUpdateUtil sharedInstance] error:@"解压失败"];
                                                       return ;
                                                   }
                                               }
                                           }else{
                                               //不是马上解压，不用管
                                           }
                                           [[WTUpdateUtil sharedInstance] hiddenLoadView];
                                       }else{
                                           [[WTUpdateUtil sharedInstance] loadDone];
                                       }
                                       
                                   }
                                  loadError:^(WTLoadErrorCode code,NSArray<WTUpdateSource *>*errorList) {
                                      [[WTUpdateUtil sharedInstance]loadError:newUpdateSourceList message:@"下载非阻塞资源失败"];
                                  }];
        }
        [[WTUpdateUtil sharedInstance] hiddenLoadView];
    }
}

#pragma mark zip
/**
 解压下载的zip包
 @param source 资源对象
 @return
 */
- (BOOL)unzipTheLoadPackage:(WTUpdateSource *)source isGohome:(BOOL)isGoHome{
    NSString *result   =  [source getUnzipFromFile];
    NSString *toPath   =  [source getUnzipToPath];
    if (![WTPathUtil isExistsFileAtPath:result]) {
        WTError(@"解压的文件不存在%@",result);
        return  NO;
    }
    if (source.setting.unzip.deleteOrigin) {
        //这儿需要处理一下，如果删除了这个文件，而解压失败！！
        [WTFileManager removeFile:toPath];
    }
    BOOL isUnzip = [WTFileManager unzipfile:result toPath:toPath];
    if (isUnzip) {
        [WTFileManager removeFile:result];
        [[WTUpdateUtil sharedInstance] updateAvailableMap];
        [[WTUpdateUtil sharedInstance] setHost:[[WTUpdateUtil sharedInstance] getServerHost]];
        if (isGoHome) {
            if (source.setting.unzip.unzipMethod==WTDoneAfterUnzipTypeGoHome) {
                [[WTUpdateUtil sharedInstance] doAfterUnzip:WTDoneAfterUnzipTypeGoHome];
            }
        }
    }
    return  isUnzip;
    
}


/**
 扫描本地文件zip包是否需要解压
 
 @param type 解压类型
 */
-(void)scanLoadUnzip:(WTUnzipType)type{
    //疑点：在扫描需要解压的包时候，这个时候必定不能请求灯塔接口获取新的航海图。
    WTChartsResponse *serverLocalversion = [[WTUpdateUtil sharedInstance]getServerUpdateObject];
    if (serverLocalversion!=nil) {
        BOOL isExit = false;
        BOOL isNotUnzip = false;
        for (WTUpdateSource *soure in serverLocalversion.sources.list) {
            
            
            
            if ([self isNowUnzipTheLoadPackage:soure type:type]) {
                if (soure.setting.unzip.block) {
                    isExit= true;
                    [[WTUpdateUtil sharedInstance]showLoadView];
                }
                BOOL isUnzip= [[WTUpdateUtil sharedInstance] unzipTheLoadPackage:soure isGohome:YES];
                if (isUnzip) {
                    [[WTUpdateUtil sharedInstance] updateLocalVersion:soure];
                }else{
                    //解压失败
                    isNotUnzip = true;
                }
                
            }
        }
        if (isExit) {
            [[WTUpdateUtil sharedInstance] hiddenLoadView];
        }
        if (isNotUnzip) {
            [[WTUpdateUtil sharedInstance] error:@"存在解压失败的文件"];
        }
    }
}

/**
 检查下载的资源包是否马上解压
 
 @param source 资源信息对象
 @param type 解压时间
 @return
 */
- (BOOL)isNowUnzipTheLoadPackage:(WTUpdateSource*)source type:(WTUnzipType)type{
    
    if(![WTPathUtil isExistsFileAtPath:[source getUnzipFromFile]]){
        return NO;
    }
    
    long long nowTime = [[NSDate date]timeIntervalSince1970];
    if (source.setting.unzip.time<=nowTime) {
        
        if (type==WTUnzipTypeRestart) {
            return YES;
        }
        if(source.setting.unzip.type ==type){
            return YES;
        }
        
    }
    return NO;
}

#pragma mark get方法
/**
 获取服务器map映射
 @return 路由跳转规则
 */
-(NSDictionary*)getServerMap{
    NSString *path=[[WTPathUtil getDocumentPathStr:ServerMapPath] stringByAppendingPathComponent:WTAvailableMap];
    if ([WTPathUtil isExistsFileAtPath:path]) {
        NSData *jsonData= [[NSData alloc]initWithContentsOfFile:path];
        if (jsonData) {
            NSError *error=nil ;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
            if(error){
                WTError(@"服务器上的map映射文件配置出错，不是json格式文件，使用可用map 配置文件数据");
                return [self getAvailableMap];
            }else{
                return result;
            }
            
        }else{
            WTDebug(@"服务器上的map映射文件配置数据为空，使用可用map 配置文件数据");
            return [self getAvailableMap];
        }
    }else{
        WTDebug(@"服务器上的map映射文件不存在，使用可用map 配置文件数据");
        return [self getAvailableMap];
    }
}
/**
 获取app版本号
 
 @return 返回app版本号
 */
- (NSString*)getAppVersion{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString     *app_Version    = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    return app_Version;
}
/**
 获取本地保存的服务器航海图数据
 @return
 */
- (WTChartsResponse*)getServerUpdateObject
{
    NSData   *updateData = WTUserDefaultsGet(serverUpdateInfoName);
    if (updateData==nil) {
        return nil;
    }else{
        NSError  *error;
        WTChartsResponse *versionObject = [[WTChartsResponse alloc]initWithData:updateData error:&error];
        if (error) {
            WTError(@"服务器返回的航海图信息错误");
            return nil;
        }else{
            return versionObject;
        }
    }
}
/**
 获取本地各个模块版本号，如果本地路径下面没有的话返回的是最初始化的版本信息
 
 @return
 */
- (WTChartsResponse*)getLocalLKUpdateObject
{
    
    NSData   *localNewVersion  = WTUserDefaultsGet(localUpdateInfoName);
    NSError *error;
    WTChartsResponse *localVersionObject;
    if (localNewVersion) {
        localVersionObject = [[WTChartsResponse alloc]initWithData:localNewVersion error:&error];
        
    }else{
        NSString *localVersionPath = [[NSBundle mainBundle] pathForResource:localVersionInfoName ofType:@"json"];
        localVersionObject = [[WTChartsResponse alloc]initWithData:[NSData dataWithContentsOfFile:localVersionPath] error:&error];
        if (localVersionObject.sources==nil) {
            WTUpdateListInfo *info = [WTUpdateListInfo new];
            WTSourceSetting  *setting = [WTSourceSetting new];
            info.setting = setting;
            info.list = [[NSMutableArray alloc]init];
            localVersionObject.sources = info;
        }
        
        WTUserDefaultsSet([localVersionObject toJSONData], localUpdateInfoName);
    }
    
    if(error)
    {
        WTError(@"本地版本version初始化失败：%@",error);
        return nil;
    }
    return localVersionObject;
}

/**
 重本地下载文件中获取域名词典
 
 @return 返回域名词典，正确结果例如：
 {
	"localHosts" : {
 "i.dmall.com" : "H",
 "img.dmall.com" : "H/img"
	},
	"trustHosts" : ["i.dmall.com", "static.dmall.com"],
 }
 */
-(NSDictionary*)getServerHost{
    NSString *path=[[WTPathUtil getDocumentPathStr:ServerHostPath] stringByAppendingPathComponent:WTHostConfigName];
    if ([WTPathUtil isExistsFileAtPath:path]) {
        NSData *jsonData= [[NSData alloc]initWithContentsOfFile:path];
        if (jsonData) {
            NSError *error=nil ;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
            if(error){
                WTError(@"服务器上的host文件配置出错，不是json格式文件");
                return nil;
            }else{
                return result;
            }
            
        }else{
            WTDebug(@"服务器上的host文件配置数据为空,请求不做任何拦截");
            return nil;
        }
    }else{
        WTDebug(@"服务器上的host文件没有,请求不做任何拦截");
        return nil;
    }
}
/**
 获取本地map映射
 @return 路由跳转规则
 */
-(NSDictionary*)getLocalMap{
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"localMapInfo" ofType:@"json"];
    if(self.mapName.length>0){
        path = [[NSBundle mainBundle]pathForResource:self.mapName ofType:@"json"];
    }
    if (path.length>0) {
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:path];
        if (jsonData) {
            NSError *error=nil ;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
            if(error){
                WTError(@"本地map映射文件配置出错，不是json格式文件");
                return nil;
            }else{
                return result;
            }
            
        }else{
            WTDebug(@"本地map映射文件配置数据为空");
            return nil;
        }
        
    }
    WTError(@"本地没有map映射文件");
    return nil;
}
/**
 获取本地可用映射
 @return 路由跳转规则
 */
-(NSDictionary*)getAvailableMap{
    NSDictionary *dic= WTUserDefaultsGet(WTAvailableMapName);
    if (dic) {
        return dic;
    }else{
        WTDebug(@"可用的map映射文件不存在，使用本地map 配置文件数据");
        return [self getLocalMap];
    }
}


/**
 获取域名对应的本地查找文件根目录
 
 @param host 域名 例如： dmall.com
 @return 请求域名对应的根目录名字
 */
-(NSString*)getHostFolder:(NSString*)host{
    NSDictionary *hostDic=[self getServerHost];
    if (hostDic) {
        NSDictionary *localHosts = hostDic[@"localHosts"];
        for (NSString *key in [localHosts allKeys]) {
            if ([host isEqualToString:key]) {
                NSString *value = localHosts[key];
                return value;
            }
        }
        return nil;
    }else{
        return nil;
    }
}



#pragma mark set方法
/**
 更新本地包中已经存在的模块信息版本号
 
 @param newVersion 需要更新的模块信息对象
 */
-(void)updateLocalVersion:(WTUpdateSource*)newVersion{
    WTChartsResponse * localObject = [self getLocalLKUpdateObject];
    if (newVersion) {
        Boolean isExit= false;
        for (int i=0;i<localObject.sources.list.count;i++) {
            WTUpdateSource *source = localObject.sources.list [i];
            if ([source isSameSouece:newVersion]) {
                [localObject.sources.list replaceObjectAtIndex:i withObject:newVersion];
                isExit = true;
                break;
            }
        }
        if (!isExit) {
            [localObject.sources.list addObject:newVersion];
        }
        WTUserDefaultsSet([localObject toJSONData], localUpdateInfoName);
    }
}

/**
 设置galleon 拦截的本地域名和需要跨域的域名
 
 @param host 域名词典,例如：
 {
	"localHosts" : {
 "i.dmall.com" : "H",
 "img.dmall.com" : "H/img"
	},
	"trustHosts" : ["i.dmall.com", "static.dmall.com"],
 }
 */
-(void)setHost:(NSDictionary*)host{
    NSDictionary *localHosts = host[@"localHosts"];
    NSArray       *trustHost = host[@"trustHosts"];
    if (localHosts) {
        [[DMBridgeHelper getInstance]setNativeSourceHosts:localHosts];
    }
    if (trustHost) {
         [[DMBridgeHelper getInstance]setAccessControlOrigin:trustHost];
    }
   
}

/**
 更新可用的重定向map
 */
-(void)updateAvailableMap{
    NSDictionary *serverMap       = [self getServerMap];//服务器每次都返回的全量map
    NSMutableDictionary *newAvailableMap = [[NSMutableDictionary alloc]init];
    for (NSString *key in [serverMap allKeys]) {
        //一样的key 和 Value 不需要检查是否存在了，上一次已经检查过这个。不能这么想，因为有些模块包，覆盖了一些文件。但是map 并没有改变
        NSString *value = serverMap[key];
        //检查Value 页面是否存在
        if(value.length==0){
            [newAvailableMap setObject:value forKey:key];
            [DMNavigator registRedirectFromUrl:key toUrl:value];
        }else{
            if ([self checkURL:value]) {
                [newAvailableMap setObject:value forKey:key];
                [DMNavigator registRedirectFromUrl:key toUrl:value];
            }
        }
    }
    
    WTUserDefaultsSet(newAvailableMap , WTAvailableMapName);
    WTDebug(@"可用的map映射地址：%@",newAvailableMap);
}

#pragma mark delete方法
/**
 清除本地下载的资源和持久化数据
 */
- (void)cleanSource{
    NSString     *soureVersion = WTUserDefaultsGet(WTSourceDicVersion);
    if (![soureVersion isEqualToString:[self getAppVersion]]) {
        //清楚资源包和本地文件
        [self cleanFile];
    }
    
}
- (void)cleanFile{
    //清楚资源包和本地文件
    [WTFileManager removeFile:[WTPathUtil getDocumentPathStr:SourceDic]];
    WTUserDefaultsRemove(WTSourceDicVersion);
    WTUserDefaultsRemove(WTAvailableMapName);
    WTUserDefaultsRemove(serverUpdateInfoName);
    WTUserDefaultsRemove(localUpdateInfoName);
}
#pragma mark 外部暴露方法
- (NSString *)bundleCodePath:(NSString*)bundlePath {
    if (bundlePath.length==0) {
        return nil;
    }
    NSString  *path= [[WTPathUtil getDocumentPathFromPaths:@[SourceDic,RNLocalPath]] stringByAppendingPathComponent:bundlePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }
    WTDebug(@"请求RN页面的bundlePath：%@",path);
    return nil;
}
- (NSString *)bundleImagePath:(NSString*)bundlePath {
    
    NSString  *path= [[WTPathUtil getDocumentPathFromPaths:@[SourceDic,RNLocalPath]] stringByAppendingPathComponent:bundlePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }
    return nil;
}
- (void)startUpdate:(WTChartsRequest *)chartsRequest
        showLoading:(void (^)())showLoading
      hiddenLoading:(void (^)())hiddenLoading
       doAfterUnzip:(void (^)(WTDoneAfterUnzipType type))doAfterUnzip
           complete:(void (^)())complete
          loadError:(void (^)(NSString *message))loadError{
    
    
    
    if(chartsRequest.url.length==0){
        loadError(@"请求链接不能为空");
        WTError(@"请求链接不能为空");
        return;
    }
    [WTUpdateUtil sharedInstance].showLoadingBlock = showLoading;
    [WTUpdateUtil sharedInstance].hiddenLoadingBlock = hiddenLoading;
    [WTUpdateUtil sharedInstance].completeBlock = complete;
    [WTUpdateUtil sharedInstance].loadErrorBlock= loadError;
    [WTUpdateUtil sharedInstance].doAfterUnZip = doAfterUnzip;
    [[WTUpdateUtil sharedInstance] cleanSource];
    [[WTUpdateUtil sharedInstance] setHost:[[WTUpdateUtil sharedInstance] getServerHost]];
    [[WTUpdateUtil sharedInstance] scanLoadUnzip:WTUnzipTypeRestart];
    [[WTUpdateUtil sharedInstance] checkRedirect];
    
    [WTUpdateUtil sharedInstance].request = chartsRequest;
    
    //每次启动的时候，必须调用一次航海图。不管上次调用的策略是什么。
    [[WTUpdateUtil sharedInstance]doRequestLitghHose:chartsRequest];
}


- (NSString*)h5ResponsePath:(NSString*)url{
    return [self h5ResponsePath:url folder:nil];
}

- (NSString*)h5ResponsePath:(NSString*)url folder:(NSString*)folder{
    if (!url) {
        return nil;
    }
    NSString *documentPath = [WTPathUtil getDocumentPath];
    NSString *retrunUrl = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@/%@",SourceDic,H5LocalPath,url]];
    if (folder.length>0) {
        [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@/%@",SourceDic,folder,url]];
    }
    
    if ([WTPathUtil isExistsFileAtPath:retrunUrl]) {
        return retrunUrl;
    }else{
        NSString *kayakPath = [[NSBundle mainBundle] pathForResource:@"kayak" ofType:@"bundle"];
        if (kayakPath) {
            NSString *fileFullPath = [kayakPath stringByAppendingPathComponent:url];
            if ([WTPathUtil isExistsFileAtPath:fileFullPath]) {
                return fileFullPath;
            }else{
                return nil;
            }
            
        }else{
            return nil;
        }
    }
}
#pragma mark 日志设置
/**
 设置watchTower中日志级别
 @param logLevel 日志级别枚举
 */
- (void)setLogLevel:(WTLogLevel)logLevel{
    [WTLog sharedInstance].logLevel= logLevel;
}
@end
