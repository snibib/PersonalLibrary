//
//  DKStorageUtil.m
//  Galleon
//
//  Created by 兵兵 刘 on 2017/3/10.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "DKStorageUtil.h"
#import "DKStorage.h"
#import "WTLog.h"
@implementation DKStorageUtil
//先删后设置
+(BOOL)setResponseAct:(NSDictionary*)act{
    NSDictionary *storage = act[@"storage"];
    if(storage){
        BOOL retrunBool= true;
        //先删除
        NSMutableArray *deleteKeys = [[NSMutableArray alloc]init];
        for(NSString *key in storage.allKeys){
            if ([key isEqualToString:@"delete"]) {
                id removeKeys = storage[@"delete"];
                if (removeKeys) {
                    if ([removeKeys isKindOfClass:[NSArray class]]) {
                        
                        for (NSString *removeKey in removeKeys) {
                            BOOL done=[[DKStorage getInstance]remove:removeKey];
                            if (!done) {
                                retrunBool = false;
                                WTError(@"删除key（%@）失败",removeKey);
                            }
                        }
                        
                    }else{
                        retrunBool = false;
                        WTError(@"删除keys（%@）失败,格式不是集合数据，请联系后台",[removeKeys class]);
                    }
                    
                }else{
                    WTWarn(@"删除的key值对应的value为空");
                }

            }else if ([key isEqualToString:@"set"]){
                [deleteKeys addObject:key];
            }
        }
        //后设置
        for(NSString *key in deleteKeys){
            if ([key isEqualToString:@"set"]) {
                id setValue = storage[@"set"];
                if ([setValue isKindOfClass:[NSDictionary class]]) {
                    //先处理具有链式的数据xxx.xxx.xxx
                    for(NSString *setKey in [setValue allKeys]){
                        id setKeyValue = storage[@"set"][setKey];
                        NSData *data = [[DKStorage getInstance]dataWithJSONObject:setKeyValue];
                        BOOL setBool = [[DKStorage getInstance]set:data forKey:setKey];
                        if (!setBool) {
                            retrunBool = false;
                            WTError(@"set key（%@）失败",setKey);
                        }
                    }
                }else{
                    retrunBool = false;
                    WTError(@"set keys（%@）失败,格式不是词典Dictionary数据，请联系后台",[setValue class]);

                }
                retrunBool = true;
            }
        }
        return retrunBool;
    }else{
        return NO;
    }
    
}

@end
