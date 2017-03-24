//
//  WTSourceUnzip.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/21.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "WTUpdateUtil.h"
typedef NS_ENUM(NSInteger,WTUnzipType) {
    WTUnzipTypeNow=0,//马上
    WTUnzipTypeWakeup=1,//进了前台
    WTUnzipTypeRestart=2,//重启
    WTUnzipTypeEnterBackground=3,//进了后台
    WTUnzipTypeOther//其他
    
    
};
@interface WTSourceUnzip : JSONModel
@property(nonatomic,assign) long long time;
@property(nonatomic,assign) WTDoneAfterUnzipType unzipMethod;
@property(nonatomic,assign) BOOL deleteOrigin;
@property(nonatomic,assign) BOOL block;
@property(nonatomic,assign) WTUnzipType type;
@end
