//
//  WTSorucesSetting.h
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/21.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "WTSourceUnzip.h"
#import "WTSourceUpdate.h"
@interface WTSourceSetting : JSONModel
@property(nonatomic,strong)WTSourceUnzip *unzip;
@property(nonatomic,strong)WTSourceUpdate*update;
@end
