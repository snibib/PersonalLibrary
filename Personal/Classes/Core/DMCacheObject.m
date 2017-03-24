//
//  DMCacheObject.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMCacheObject.h"

@interface DMCacheElement : NSObject

@property (strong,nonatomic) NSString               *key;
@property (strong,nonatomic) id                      value;

@end

@implementation DMCacheElement
@end

@interface DMCacheObject()

@property (strong,nonatomic) NSMutableDictionary    *objectDic;
@property (strong,nonatomic) NSMutableArray         *objectArray;
@property (assign,nonatomic) int                     cap;

@end

@implementation DMCacheObject

- (instancetype)initWithCap:(int)size {
    if(self = [super init]) {
        self.cap = size;
    }
    return self;
}

- (void)setObject:(id)value forKey:(NSString*)key {
    // 删除可能重复的数据
    [self remove:key];
    
    if (self.objectArray.count >= self.cap) {
        [self removeOldeast];
    }
    
    [self.objectDic setObject:value forKey:key];
    DMCacheElement* entry = [[DMCacheElement alloc] init];
    entry.key = key;
    entry.value = value;
    [self.objectArray addObject:entry];
}
- (id)objectForKey:(NSString*)key {
    return [self.objectDic objectForKey:key];
}

- (void)remove:(NSString*)key {
    [self.objectDic removeObjectForKey:key];
    for (int i = 0 ; i < self.objectArray.count ; i++) {
        DMCacheElement* entry = self.objectArray[i];
        if ([key isEqualToString:entry.key]) {
            [self.objectArray removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)removeOldeast {
    if (self.objectArray.count == 0) {
        return;
    }
    DMCacheElement* first = self.objectArray[0];
    [self remove:first.key];
}

- (NSMutableDictionary *)objectDic {
    if (_objectDic == nil) {
        _objectDic = [[NSMutableDictionary alloc] init];
    }
    return _objectDic;
}

- (NSMutableArray *)objectArray {
    if (_objectArray == nil) {
        _objectArray = [[NSMutableArray alloc] init];
    }
    return _objectArray;
}

@end
