//
//  WTChartsSetting.m
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/21.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import "WTChartsSetting.h"

@implementation WTChartsSetting

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    
    return YES;
}
-(NSInteger)timeInterval{
    if (_timeInterval<10) {
        return 60;
    }else{
        return _timeInterval;
    }
}

@end
