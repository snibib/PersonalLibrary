//
//  WTChartsSetting.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/20.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <JSONModel/JSONModel.h>
typedef NS_ENUM(NSInteger,WTRequestType) {
    WTRequestTypeTime=0,//间隔时间段
    WTRequestTypeEnterFore=1,//进了前台
    WTRequestTypeRestart=2,//重启
    WTRequestTypeEnterBackground=3,//进了后台
    WTRequestTypeOther//其他
};
@interface WTChartsSetting : JSONModel
@property(nonatomic,assign) WTRequestType time;
@property(nonatomic,assign) NSInteger timeInterval;//间隔时间


@end
