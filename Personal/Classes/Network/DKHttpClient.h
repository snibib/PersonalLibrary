//
//  DKHttpClient.h
//  DKall
//
//  Created by chris on 15/4/28.
//  Copyright (c) 2015年 wintech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "DKBaseRequest.h"
#import "DKBaseResponse.h"
typedef void(^DKResultSuccessHandler)(DKBaseResponse *response);
typedef void(^DKResultFailureHandler)(DKBaseResponse *response);
typedef void(^DKResultErrorHandler)(NSError *error);


@interface DKHttpClient : NSObject

+ (DKHttpClient*) shareInstance;

- (NSURLSessionDataTask *)connectWithRequest:(DKBaseRequest*)req
                                       success:(DKResultSuccessHandler)succesHandler
                                       failure:(DKResultFailureHandler)failureHandler
                                         error:(DKResultErrorHandler)errorHandler;



- (void)cancelAllRequest;
@end
