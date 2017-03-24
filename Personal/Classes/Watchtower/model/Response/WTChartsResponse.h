//
//  WTChartsResponse.h
//  dmall
//
//  Created by 兵兵 刘 on 2017/3/13.
//  Copyright © 2017年 dmall. All rights reserved.
//

#import "DKBaseResponse.h"
#import "WTUpdateListInfo.h"
#import "WTChartsSetting.h"
@interface WTChartsResponse : DKBaseResponse
@property(nonatomic,strong) WTChartsSetting   *setting;
@property(nonatomic,strong) WTUpdateListInfo  *sources;
@property(nonatomic,strong) NSDictionary      *act;
@property(nonatomic,assign) long long lastTime;//上一次请求时间；
-(NSString*)getChartsVerion;
@end
