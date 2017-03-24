//
//  DKUpdateListInfo.h
//  Deck
//
//  Created by 兵兵 刘 on 16/9/21.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "WTUpdateSource.h"
#import "WTSourceSetting.h"
@protocol  WTUpdateListInfo<NSObject>
@end
@interface WTUpdateListInfo : JSONModel
@property(nonatomic,strong) WTSourceSetting *setting;
@property(nonatomic,strong) NSMutableArray<WTUpdateSource> *list;
@end
