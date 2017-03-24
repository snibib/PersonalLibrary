//
//  DMBridgeObject.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMBridgeProtocol.h"

@class DMNavigator;
@class DKStorage;
@interface DMBridgeObject : NSObject <DMBridgeProtocol>

@property (nonatomic, weak) DMNavigator                 *navigator;
@property (nonatomic, weak) DKStorage                   *storage;

@end
