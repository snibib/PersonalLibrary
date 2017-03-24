//
//  DMBridgeObject.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridgeObject.h"
#import "DMNavigator.h"
#import "DKStorage.h"

@implementation DMBridgeObject

- (instancetype)init {
    if (self = [super init]) {
        self.navigator = [DMNavigator getInstance];
        self.storage = [DKStorage getInstance];
    }
    return self;
}

- (NSString *)javascriptObjectName {
    return @"window.bridge";
}

@end
