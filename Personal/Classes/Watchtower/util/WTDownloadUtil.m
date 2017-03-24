//
//  WTDownloadUtil.m
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/13.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import "WTDownloadUtil.h"
#import "WTPathUtil.h"
#import <UIKit/UIKit.h>
#import "WTLog.h"
#import "AFNetworking.h"
@implementation WTDownloadUtil


+ (void)downLoadSource:(NSString *)source
              complete:(void (^)(NSData *data))complete
             loadError:(void (^)(WTLoadErrorCode code))loadError{
    if (source == nil || source.length == 0) {
        loadError(WTLoadErrorCodeNull);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:source];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[UIDevice currentDevice].systemVersion doubleValue] < 9.0) {
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                if (connectionError) {
                    WTError(@"更新模块错误 = %@",connectionError);
                    loadError(WTLoadErrorCodeNet);
                    return;
                }
                if (data.length==0) {
                    
                    loadError(WTLoadErrorCodeContentNull);
                    return;
                }
                if (complete) {
                    complete(data);
                }
            }];
        }
        else {
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:0.0];
            NSURLSessionTask *tast = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    WTError(@"更新模块错误 = %@",error);
                    loadError(WTLoadErrorCodeNet);
                    return;
                }
                if (data.length==0) {
                    loadError(WTLoadErrorCodeContentNull);
                    return;
                }
                
                if (complete) {
                    complete(data);
                }
            }];
            [tast resume];
        }
    });
}

+ (void)downLoadSources:(NSArray<WTUpdateSource *>*)sources
               complete:(void (^)(WTUpdateSource *))complete
              loadError:(void (^)(WTLoadErrorCode code,NSArray<WTUpdateSource *>*))loadError{
    if (sources.count>0) {
        __block WTLoadErrorCode errorCode=WTLoadDefaultSuccessCode;
        __block NSMutableArray<WTUpdateSource *> *errorList=[[NSMutableArray alloc]init];
        //DISPATCH_QUEUE_SERIAL 单行 DISPATCH_QUEUE_CONCURRENT 并行
        dispatch_queue_t loadQueue = dispatch_queue_create("loadServerSourceQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_group_t loadQueueGroup = dispatch_group_create();
        for (WTUpdateSource *updateSource in sources) {
            if (updateSource.wt_url.length>0&&updateSource.wt_size.length>0&&updateSource.wt_localPath.length>0) {
                NSString *doucmentFilePath = [WTPathUtil getDocumentPathStr:updateSource.wt_localPath];
                NSString *filePath = [doucmentFilePath stringByAppendingString:updateSource.wt_name];
                //判断这个文件在目录下面是否存在
                if (![WTPathUtil isExistsFileAtPath:filePath]) {
                    dispatch_group_async(loadQueueGroup, loadQueue, ^{
                        long long time =  [[NSDate new]timeIntervalSince1970];
                        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?time=%lld",updateSource.wt_url,time]];
                        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:180];
                        NSError *error = nil;
                        NSURLResponse *respond = nil;
                        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&respond error:&error];
                        //http://www.cnblogs.com/DeasonGuan/articles/Hanami.html 相应状态码
                        //http://blog.csdn.net/itpinpai/article/details/47950615
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)respond;
                        NSInteger statusCode = [httpResponse statusCode];
                        if (statusCode>=200&&statusCode<300) {
                            WTDebug(@"下载保存的路径：%@",filePath); 
                            WTDebug(@"文件大小：%lu",(unsigned long)data.length);
                            if(error){
                                [errorList addObject:updateSource];
                                WTDebug(@"下载失败：%@",[error localizedDescription]);
                                errorCode = WTLoadErrorCodeNet;
                            }
                            if (data!=nil) {
                                BOOL isCreate=[data writeToFile:filePath atomically:YES];
                                if (isCreate) {
                                    WTDebug(@"下载成功：%@",request.URL);
                                    complete(updateSource);
                                }else{
                                    errorCode = WTLoadErrorCodeNet;
                                    WTDebug(@"写入文件失败：%@",request.URL);
                                }
                            }else{
                                NSString *messageError = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                                WTError(@"返回数据为null失败，检查网络(%@,%@)",request.URL,messageError);
                                errorCode = WTLoadErrorCodeNet;
                                [errorList addObject:updateSource];
                            }
                        }else{
                            NSString *messageError = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
                            WTError(@"请求失败，检查网络(%@,%@)",request.URL,messageError);
                            errorCode = WTLoadErrorCodeNet;
                            [errorList addObject:updateSource];
                        }
                        
                    });
                }
            }else{
                WTError(@"下载地址大小、储存地址为空：%@-%@-%@",updateSource.wt_url,updateSource.wt_size,updateSource.wt_localPath);
                errorCode = WTLoadErrorCodeSource;
                break;
            }
            
        }
        dispatch_group_notify(loadQueueGroup, loadQueue, ^{
            if (errorCode!=WTLoadDefaultSuccessCode) {
                loadError(errorCode,errorList);
            }else{
                WTDebug(@"下载完成");
                complete(nil);
            }
            
        });
    }else{
        loadError(WTLoadErrorCodeNull,nil);
        
    }
    
}
@end
