//
//  WTChartsResponse.m
//  dmall
//
//  Created by 兵兵 刘 on 2017/3/13.
//  Copyright © 2017年 dmall. All rights reserved.
//

#import "WTChartsResponse.h"

@implementation WTChartsResponse
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    
    return YES;
}
-(NSString*)getChartsVerion{
    return self.act[@"storage"][@"lighthouse"][@"add"][@"version"];
}
@end
