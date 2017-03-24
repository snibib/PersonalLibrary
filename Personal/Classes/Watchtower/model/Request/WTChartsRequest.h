//
//  WTChartsRequest.h
//  dmall
//
//  Created by 兵兵 刘 on 2017/3/13.
//  Copyright © 2017年 dmall. All rights reserved.
//

#import "DKBaseRequest.h"

@interface WTChartsRequest : DKBaseRequest

/**
 app唯一标识符
 */
@property(nonatomic,strong) NSString *clientId;

/**
 引用标识符 APP(0,"多点App"),POP(1,"地推App"),WMS(2,"拣货App");
 */
@property(nonatomic,strong) NSString *app_id;
@property(nonatomic,strong) NSString *user_id;
@property(nonatomic,strong) NSString *extend;

@end
