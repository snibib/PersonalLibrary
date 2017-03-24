//
//  DKBaseResponse.h
//  DKall
//
//  Created by chris on 15/4/28.
//  Copyright (c) 2015年 wintech. All rights reserved.
//

#import "JSONModel.h"

@interface DKBaseResponse : JSONModel

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *result;
@property (nonatomic, copy) NSString *action;


@end
