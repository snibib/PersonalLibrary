//
//  DKHttpClient.m
//  DKall
//
//  Created by chris on 15/4/28.
//  Copyright (c) 2015年 wintech. All rights reserved.
//

#import "DKHttpClient.h"
#import "AFNetworking.h"
#import "WTLog.h"
#import <libkern/OSSpinLockDeprecated.h>

@interface DKHttpClient()
@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic) OSSpinLock spinLock;
@end

@implementation DKHttpClient
+ (DKHttpClient*) shareInstance{
    
    static DKHttpClient *instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[DKHttpClient alloc] initSingleton];
    });
    return instance;
}

- (id) init{
    
    NSAssert(YES, @"can't call init for singleton class");
    return nil;
}

- (id) initSingleton{
    
    if(self = [super init]){
        self.httpSessionManager = [AFHTTPSessionManager manager];
        self.httpSessionManager.operationQueue.maxConcurrentOperationCount =  NSOperationQueueDefaultMaxConcurrentOperationCount;
        _spinLock = OS_SPINLOCK_INIT;
    }
    return self;
}

#pragma mark - public method
- (NSURLSessionDataTask *)connectWithRequest:(DKBaseRequest *)req
                                       success:(DKResultSuccessHandler)succesHandler
                                       failure:(DKResultFailureHandler)failureHandler
                                         error:(DKResultErrorHandler)errorHandler{
    self.httpSessionManager.requestSerializer.timeoutInterval = req.timeoutInterval;
    self.httpSessionManager.securityPolicy = [self customSecurityPolicy:req.url];
    self.startDate = [NSDate date];
    if ([req.method isEqualToString:@"POST"]) {
        return [self commonPostRequest:req success:succesHandler failure:failureHandler error:errorHandler];
    }
    if ([req.method isEqualToString:@"GET"]) {
        return [self commonGetRequest:req success:succesHandler failure:failureHandler error:errorHandler];
    }
    return nil;
}

- (void)cancelAllRequest {
    for (NSURLSessionTask *task in self.httpSessionManager.tasks) {
        [task cancel];
    }
}

#pragma mark - private method
- (AFSecurityPolicy*)customSecurityPolicy:(NSString *) url
{
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    if ([url hasPrefix:@"https"] && ([url rangeOfString:@"dmall.com"].location != NSNotFound || [url rangeOfString:@"pay.dmall.com"].location != NSNotFound || [url rangeOfString:@"testpay.dmall.com"].location != NSNotFound || [url rangeOfString:@"pre.pay.dmall.com"].location != NSNotFound)) {
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        securityPolicy.allowInvalidCertificates = NO;
        securityPolicy.validatesDomainName = NO;
    }
    return securityPolicy;
}



- (NSURLSessionDataTask *)commonPostRequest:(DKBaseRequest *)req
                  success:(DKResultSuccessHandler)succesHandler
                  failure:(DKResultFailureHandler)failureHandler
                    error:(DKResultErrorHandler)errorHandler {
    OSSpinLockLock(&_spinLock);
    NSURLSessionDataTask * task = [self.httpSessionManager POST:req.url parameters:req.customParameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        DKBaseResponse *response = [req responseFromObject:responseObject];
        [self printRequest:task.currentRequest];
        [self printParam:req];
        [self printResponse:responseObject startDate:self.startDate];
        if(succesHandler) succesHandler(response);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:task.currentRequest];
        [self printParam:req];
        if (error.code != NSURLErrorCancelled) {
            if(errorHandler) errorHandler(error);
        }
    }];
    OSSpinLockUnlock(&_spinLock);
    return task;
}

- (NSURLSessionDataTask *)commonGetRequest:(DKBaseRequest *)req
                  success:(DKResultSuccessHandler)succesHandler
                  failure:(DKResultFailureHandler)failureHandler
                    error:(DKResultErrorHandler)errorHandler {
    OSSpinLockLock(&_spinLock);
    
    NSURLSessionDataTask * task = [self.httpSessionManager GET:req.url parameters:req.customParameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self printRequest:task.currentRequest];
        [self printParam:req];
        DKBaseResponse *response = [req responseFromObject:responseObject];
        [self printResponse:responseObject startDate:self.startDate];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (error.code != NSURLErrorCancelled) {
            if(errorHandler) errorHandler(error);
        }
    }];
    OSSpinLockUnlock(&_spinLock);
    return task;
}

#pragma mark print log
- (void)printRequest:(NSURLRequest *)request{
    WTDebug(@"请求地址:%@",request.URL);
    WTDebug(@"请求头信息:%@",request.allHTTPHeaderFields);
    WTDebug(@"请求类型:%@",request.HTTPMethod);
}

- (void) printParam: (DKBaseRequest *) req {
    WTDebug(@"请求参数：%@", [req description]);
}

- (void)printResponse:(id)response startDate:(NSDate*)startDate{
	WTDebug(@"响应内容:%@", [self responseJson:response]);
    WTDebug(@"请求用时:%f",[[NSDate date] timeIntervalSinceDate:startDate]);
}

- (id)responseJson:(id)response
{
	if ([NSJSONSerialization isValidJSONObject:response]) {
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:NSJSONWritingPrettyPrinted error:nil];
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		response = jsonString;
	}
	return response;
}

@end
