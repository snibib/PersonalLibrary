//
//  DMModuleBase.m
//  Galleon
//
//  Created by 杨涵 on 2017/3/20.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "DMModuleBase.h"
#import "DKStorage.h"
#import "DMNavigator.h"
#import <objc/runtime.h>

@implementation DMModuleBase

- (instancetype)init {
    self = [super init];
    if (self) {
        self.storage = [DKStorage getInstance];
        self.navigator = [DMNavigator getInstance];
    }
    return self;
}

+ (instancetype)getInstance {
    id instance = objc_getAssociatedObject(self, @"galleon_modulebase_instance");
    if (!instance) {
        instance = [[super allocWithZone:NULL] init];
        objc_setAssociatedObject(self, @"galleon_modulebase_instance", instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self getInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self class] getInstance];
}

- (void)startObserving {
    self.hasListener = YES;
}

- (void)stopObserving {
    self.hasListener = NO;
}

- (NSArray<NSString *> *)supportedEvents { return nil; }

- (void)sendEventMessage:(NSDictionary *)message {}

@end
