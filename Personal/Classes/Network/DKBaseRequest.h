//
//  DKBaseRequest.h
//  DKall
//
//  Created by chris on 15/4/28.
//  Copyright (c) 2015年 wintech. All rights reserved.
//

#import "JSONModel.h"
@class DKBaseResponse;

@interface DKBaseRequest : JSONModel

@property(nonatomic, copy)      NSString        *url;
@property(nonatomic, copy)      NSString        *path;
@property(nonatomic, copy)      NSString        *method;
@property(nonatomic, assign)    NSTimeInterval  timeoutInterval;



- (DKBaseResponse *)responseFromObject:(id)object;
- (NSDictionary *)parameters;
- (NSString *)jsonString;
- (NSDictionary *)customParameters;
- (NSDictionary *)uploadParameters;

@end
