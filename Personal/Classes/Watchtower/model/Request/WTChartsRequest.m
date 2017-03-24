//
//  WTChartsRequest.m
//  dmall
//
//  Created by 兵兵 刘 on 2017/3/13.
//  Copyright © 2017年 dmall. All rights reserved.
//

#import "WTChartsRequest.h"
#import "WTUpdateUtil.h"
@interface WTChartsRequest()
@property(nonatomic,strong) NSString *app_version;
@property(nonatomic,strong) NSString *platform;//平台 0Android 1ios
@end
@implementation WTChartsRequest
-(NSString *)app_version{
    return [[WTUpdateUtil sharedInstance]getAppVersion];
}

-(NSString *)platform{
    
    return @"1";
}

@end
