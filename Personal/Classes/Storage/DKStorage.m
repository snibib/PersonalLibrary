//
//  DKStorage.m
//  Deck
//
//  Created by 杨涵 on 16/8/2.
//  Copyright © 2016年 dmall. All rights reserved.
//

#import "DKStorage.h"
#import "DMCache.h"
#import "WTLog.h"
@implementation DKStorage
{
    DMCache *dataCache;
}
+ (instancetype)getInstance {
    static DKStorage *instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        instance = [[DKStorage alloc] init];
        instance->dataCache = [DMCache getInstance];
    });
    
    return instance;
}


- (NSArray*)checkKey:(NSString*)key{
    if (key.length==0) {
        WTError(@"失败，key值不能为空");
        return nil;
    }
    
    BOOL retrun = true;
    if([key hasPrefix:@"."]){
        WTError(@"失败，key值不能以.开头");
        retrun = false;
    }
    if([key hasSuffix:@"."]){
        WTError(@"失败，key值不能以.结尾");
        retrun = false;
    }
    if([key containsString:@".."]){
        WTError(@"失败，key值不能包含..");
        retrun = false;
    }
    
    NSRange _range = [key rangeOfString:@" "];
    if (_range.location != NSNotFound) {
        WTError(@"失败，key值不能包含空格");
        retrun = false;
    }
    if (retrun) {
        NSArray *keys = [key componentsSeparatedByString:@"."];
        if (keys.count==0) {
            WTError(@"失败，key格式不对");
            return nil;
        }else{
            return keys;
        }
    }else{
        return nil;
    }
    
}
-(BOOL)onlyIncludeCharacters:(NSString*)characters noRepeatChar:(NSString*)character str:(NSString*)str
{
    NSArray *separatedStr = [str componentsSeparatedByString:character];
    if (separatedStr.count>=3) {
        return NO;
    }
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:characters] invertedSet];
    NSString *filtered = [[str componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    BOOL     basicTest = [str isEqualToString:filtered];
    if(!basicTest) {
        return NO;
    }
    return YES;
}

/**
 检查key值是否是xxx[index]模式的字符串.[1]或者home[a]返回false。xxx[][1]返回true
 @param key 字符串
 @return 如果是xxx[index]模式的字符串返回True，否则返回NO；
 */
-(BOOL)checkListKey:(NSString*)key{
    if ([key containsString:@"["]&&[key containsString:@"]"]){
        NSRange range = [key rangeOfString:@"[" options:NSBackwardsSearch];
        NSRange rangeLast =NSMakeRange(range.location,key.length-range.location);
        NSString *lastValue = [key substringWithRange:rangeLast];
        if ([key isEqualToString:lastValue]){
            return NO;
        }
        if ([lastValue hasPrefix:@"["]&&[lastValue hasSuffix:@"]"]){
            lastValue = [lastValue stringByReplacingOccurrencesOfString:@"[" withString:@""];
            lastValue = [lastValue stringByReplacingOccurrencesOfString:@"]" withString:@""];
            if ([self onlyIncludeCharacters:@"0123456789" noRepeatChar:@"." str:lastValue ]){
                return YES;
            }else{
                return NO;
            }
        }
        return NO;
    }else{
        return NO;
    }
}



/**
 获取key[index]字符串中对应的index
 @param key key[index]类型的字符串
 @return index中的值
 */
-(long long)getIndexNumber:(NSString*)key{
    NSRange range = [key rangeOfString:@"[" options:NSBackwardsSearch];
    NSRange rangeLast =NSMakeRange(range.location,key.length-range.location);
    NSString *lastValue = [key substringWithRange:rangeLast];
    lastValue = [lastValue stringByReplacingOccurrencesOfString:@"[" withString:@""];
    lastValue = [lastValue stringByReplacingOccurrencesOfString:@"]" withString:@""];
    long long returnLong = [lastValue longLongValue];
    return returnLong;
}

/**
 如果key==XXXX直接返回XXXX。如果是key==list[0]返回list
 @param key 字符串
 @return 如果key==XXXX直接返回XXXX。如果是key==list[0]返回list
 */
-(NSString*)getTrueKey:(NSString*)key{
    if ([self checkListKey:key]) {
        NSRange range = [key rangeOfString:@"[" options:NSBackwardsSearch];
        NSRange rangeLast =NSMakeRange(0,range.location);
        return [key substringWithRange:rangeLast];
    }else{
        return key;
    }
}
/**
 获取key对应的值的value，对应的Value值类型为List。key 可以传key[xxx]
 @param key key值中不能包含.
 @return 集合
 */
-(NSArray*)getListFromDataCahe:(NSString*)key{
    if([key containsString:@"."]){
        WTError(@"调用这个方法中key不能包含.(%@)",key);
        return nil;
    }
    NSData *data = [self get:key];
    if (data==nil) {
        WTDebug(@"没有保存key(%@)数据",key);
        return [[NSArray alloc]init];
    }
    NSError *error = nil;
    NSArray *object= [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error) {
        WTError(@"数据格式不对，不是json对象");
        return nil;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        return object;
    }else{
        WTError(@"数据格式不对，不是list的json对象（%@）",[object class]);
        return nil;
    }
}

- (BOOL)set:(NSData *)objectData forKey:(NSString *)key {
    if (!objectData) {
        WTError(@"储存的数据为空==key=%@",key);
        return NO;
    }
    NSArray *keys = [self checkKey:key];
    if (keys.count==0) {
        return NO;
    }
    if(keys.count==1){
        if ([self checkListKey:key]) {
            long long listIndex   = [self getIndexNumber:key];
            NSString   *trueKey   = [self getTrueKey:key];
            NSArray     *valueList= [self getListFromDataCahe:trueKey];
            if (valueList) {
                
                NSMutableArray *newValueList = [[NSMutableArray alloc]initWithArray:valueList];
                id object=[self jsonObjectWithData:objectData];
                if (!object) {
                    return NO;
                }
                if (valueList.count>listIndex) {
                    //小于当前count,替换数据；
                    if (object) {
                        [newValueList replaceObjectAtIndex:listIndex withObject:object];
                    }
                    
                }else if(valueList.count==listIndex){
                    //等于当前count,插入新的数据；
                    [newValueList addObject:object];
                }else{
                    //大于当前cont，set失败；
                    WTError(@"存储失败:key=(%@)对应集合数大小为%ld。而更新或者添加的count为%ld,大于了现有count值%ld",key,valueList.count,listIndex,valueList.count);
                    return NO;
                }
                [self set:[self dataWithJSONObject:newValueList] forKey:trueKey];
                return YES;
            }else{
                return NO;
            }
            
            return [self getDataFromListKey:key];
        }else{
            [self->dataCache setData:objectData forKey:key];
            return YES;
        }
    }else{
        NSDictionary   *updateData = [self jsonObjectWithData:objectData];
        if (!updateData) {
            return NO;
        }
        NSDictionary *object= [self jsonFromDataCache:keys[0] isNull:YES];
        NSMutableDictionary *newDic=nil;
        for (NSInteger i=(keys.count-2); i>=0; i--) {
            NSString *key = keys[i+1];
            NSDictionary *getDic = [self getDicFromIndex:object keys:keys index:i];
            //这儿getDic 不可能是集合。如果是集合的话key一定是错误的
            if (getDic==nil) {
                if (i==keys.count-2) {
                    NSString *lastKey = keys[keys.count-1];
                    if ([self checkListKey:lastKey]) {
                        long long listIndex = [self getIndexNumber:lastKey];
                        if (listIndex==0) {
                            NSString   *trueKey = [self getTrueKey:lastKey];
                            NSDictionary *next = [[NSDictionary alloc]initWithObjectsAndKeys:@[updateData],trueKey,nil];
                            newDic = next;
                        }else{
                            //大于当前cont，set失败；
                            WTError(@"存储失败:key=(%@)对应集合数大小为0。而更新或者添加的count为%ld,大于了现有count值0",lastKey,listIndex);
                            return NO;
                        }
                        
                    }else{
                        NSDictionary *next = [[NSDictionary alloc]initWithObjectsAndKeys:updateData,lastKey,nil];
                        newDic = next;
                    }
                    
                }else{
                    if ([self checkListKey:key]) {
                        long long listIndex = [self getIndexNumber:key];
                        NSString *trueKey = [self getTrueKey:key];
                        if (listIndex==0) {
                            NSDictionary *next = [[NSDictionary alloc]initWithObjectsAndKeys:@[newDic],trueKey,nil];
                            newDic = next;
                        }else{
                            //大于当前cont，set失败；
                            WTError(@"存储失败:key=(%@)对应集合数大小为0。而更新或者添加的count为%ld,大于了现有count值0",key,listIndex);
                            return NO;
                        }
                    }else{
                        newDic = [[NSDictionary alloc]initWithObjectsAndKeys:newDic,key,nil];
                    }
                }
            }else if ([getDic isKindOfClass: [NSDictionary class]]) {
                NSMutableDictionary *oldDic = [[NSMutableDictionary alloc] initWithDictionary:getDic];
                if (i==keys.count-2) {
                    NSString *lastKey = keys[keys.count-1];
                    if ([self checkListKey:lastKey]) {
                        long long listIndex = [self getIndexNumber:lastKey];
                        NSString   *trueKey = [self getTrueKey:lastKey];
                        if ([self checkIsListValue:oldDic[trueKey]] ) {
                            NSArray *valueList = oldDic[trueKey];
                            NSMutableArray *newValueList = [[NSMutableArray alloc]initWithArray:valueList];
                            if (valueList.count>listIndex) {
                                //小于当前count,替换数据；
                                [newValueList replaceObjectAtIndex:listIndex withObject:updateData];
                                [oldDic setValue:newValueList forKey:trueKey];
                            }else if(valueList.count==listIndex){
                                //等于当前count,插入新的数据；
                                [newValueList addObject:updateData];
                                [oldDic setValue:newValueList forKey:trueKey];
                            }else{
                                //大于当前cont，set失败；
                                WTError(@"存储失败:key=(%@)对应集合数大小为%ld。而更新或者添加的count为%ld,大于了现有count值%ld",lastKey,valueList.count,listIndex,valueList.count);
                                return NO;
                            }
                        }else{
                            //替换lastKey 对应的Value为新的listValue
                            [oldDic setObject:@[updateData] forKey:trueKey];
                        }
                        
                    }else{
                        //替换lastKey 对应的Value为新的DicValue
                        [oldDic setValue:updateData forKey:lastKey];
                    }
                    
                    
                    newDic = oldDic;
                }else{
                    if ([self checkListKey:key]) {
                        long long listIndex = [self getIndexNumber:key];
                        NSString *trueKey = [self getTrueKey:key];
                        
                        
                        if ([self checkIsListValue:oldDic[trueKey]] ) {
                            NSArray *valueList = oldDic[trueKey];
                            if (valueList.count>listIndex) {
                                NSMutableArray *newValueList = [[NSMutableArray alloc]initWithArray:valueList];
                                [newValueList replaceObjectAtIndex:listIndex withObject:newDic];
                                [oldDic setValue:newValueList forKey:trueKey];
                            }else{
                                WTError(@"失败%@对应的数据是list数组,但是count为（%ld）",key,valueList.count);
                                return NO;
                            }
                        }else{
                            WTError(@"失败：不是list数组(%@)",[oldDic[trueKey] class]);
                            return NO;
                        }
                        
                    }else{
                        [oldDic setValue:newDic forKey:key];
                    }
                    newDic = oldDic;
                }
            }
            else if([getDic isKindOfClass:[NSArray class]]){
                
                NSLog(@"===============");
                NSString *nextKey = keys[i];
                if ([self checkListKey:nextKey]) {
                }else{
                    WTError(@"key=%@,对应的数据格式是集合。而key不是%@[xx]形式的key",nextKey,nextKey);
                    return NO;
                }
                
            }
        }
        NSData  *data = [self dataWithJSONObject:newDic];
        if (data) {
            WTDebug(@"链式修改数据为(key=%@)：%@",key,newDic);
            [self->dataCache setData:data forKey:keys[0]];
            return YES;
        }else{
            WTError(@"存储失败:更新的对象转换成NSData出错（%@）",[newDic class]);
            return NO;
        }
    }
}




/**
 判断data数据格式是不是json类型的数据。是返回
 
 @param data 任意数据类型
 @return 返回NSDictionary字典
 */
-(NSDictionary*)jsonObjectWithData:(NSData*)data{
    if(data){
        NSError *error=nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (!error) {
            return result;
        }else{
            WTError(@"objectData格式错误，不是json字符串格式");
            return result;
        }
    }else{
        WTError(@"objectData 数据为空");
        return nil;
    }
    
    
}


/**
 json对象转 NSData数据格式
 
 @param object json对象
 @return NSData数据
 */
-(NSData*)dataWithJSONObject:(id)object{
    if(object){
        NSError *error = nil;
        NSData  *data  = [NSJSONSerialization dataWithJSONObject:object options:NSJSONReadingAllowFragments error:&error];
        if (!error) {
            return data;
        }else{
            WTError(@"对象转换成NSData出错（%@）",[object class]);
            return data;
        }
        
    }else{
        WTError(@"对象转换成NSData出错，数据为空");
        return nil;
    }
    
}

/**
 判断链式除了最后一个key,是不是json数据格式对象（数组或者NSDictionary）。只有有一个不是就不是
 @param object 验证的NSDictionary对象
 @param keys 链式key集合 如startag.a.b.c.d
 @return 只有有一个不是就不是返回false，否则返回true。
 */
-(BOOL)isJsonObject:(NSDictionary*)object keys:(NSArray*)keys{
    if (object) {
        BOOL isJson = true;
        for (int i=1;i<keys.count;i++)
        {
            if(i==keys.count-1){
                //最后一个key
            }else{
                NSDictionary *dic = [self getDicFromIndex:object keys:keys index:i];
                if ([dic isKindOfClass:[NSDictionary class]]||[dic isKindOfClass:[NSArray class]]) {
                    WTInfo(@"链式对象(key=%@)(%@)(%@)",[dic class],keys[i],dic);
                }else{
                    WTError(@"链式对象中存在不是json数据格式对象（数组或者NSDictionary）(%@)(key=%@)(%@)",[dic class],keys[i],dic);
                    isJson = false;
                    break;
                }
            }
        }
        return isJson;
    }else{
        return NO;
    }
}
/**
 链式获取字典中对应key的value
 @param dic 获取Value的字典
 @param keys 链式key
 @param index 获取字典链式中第几个key对应的值，index不能大于keys集合的count-1，切index不能小于0
 @return 返回对应的值
 */
-(NSDictionary*)getDicFromIndex:(NSDictionary*)dic keys:(NSArray*)keys index:(NSInteger)index {
    if (dic==nil) {
        WTError(@"获取错误，字典为空");
        return nil;
    }
    if (index>keys.count-1) {
        WTError(@"获取错误，index>key.count-1");
        return nil;
    }
    if (index<0) {
        WTError(@"获取错误，index<0");
        return nil;
    }
    if(index==0){
        WTDebug(@"获取的数据====%@",dic);
        return dic;
    }
    
    id  returnDic = nil;
    for (int i=0;i<index; i++) {
        if (i==0) {
            NSString *key = keys[i+1];
            if ([self checkListKey:key]) {
                long long listIndex = [self getIndexNumber:key];
                NSString *trueKey = [self getTrueKey:key];
                if ([self checkIsListValue:dic[trueKey]] ) {
                    NSArray *valueList = dic[trueKey];
                    if (valueList.count>listIndex) {
                        returnDic = valueList[listIndex];
                    }else{
                        WTError(@"失败:%@对应的数据是list数组,但是count为（%ld）",key,valueList.count);
                        return nil;
                    }
                }else{
                    WTError(@"失败：%@不是list数组(%@)",key,[dic[trueKey] class]);
                    return nil;
                }
                
            }else{
                returnDic = dic[key];
            }
        }else{
            NSString *key = keys[i+1];
            if ([self checkListKey:key]) {
                
                long long listIndex = [self getIndexNumber:key];
                NSString *trueKey = [self getTrueKey:key];
                if ([self checkIsListValue:returnDic[trueKey]] ) {
                    NSArray *valueList = returnDic[trueKey];
                    if (valueList.count>listIndex) {
                        returnDic = valueList[listIndex];
                    }else{
                        WTError(@"失败:%@对应的数据是list数组,但是count为（%ld）",key,valueList.count);
                        return nil;
                    }
                }else{
                    WTError(@"失败：%@不是list数组(%@)",key,[dic[trueKey] class]);
                    return nil;
                }
                
                
            }else{
                returnDic = returnDic[key];
            }
        }
        
    }
    return returnDic;
}
-(BOOL)checkIsListValue:(id)checkObject{
    if (checkObject) {
        if ([checkObject isKindOfClass:[NSArray class]]) {
            return YES;
        }else{
            return NO;
        }
    }else{
        WTWarn(@"检查的checkObject是否是list数组，传入为空");
        return NO;
    }
    
}

/**
 获取key对应的值的value，对应的Value值类型为List。key 可以传key[xxx]
 @param key key值中不能包含.
 @return 集合
 */
-(NSArray*)listFromDataCahe:(NSString*)key{
    
    if([key containsString:@"."]){
        WTError(@"调用这个方法中key不能包含.(%@)",key);
        return nil;
    }
    NSData *data = [self get:key];
    if (data==nil) {
        WTDebug(@"没有保存key(%@)数据",key);
        return nil;
    }
    NSError *error = nil;
    NSArray *object= [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error) {
        WTError(@"数据格式不对，不是json对象");
        return nil;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        return object;
    }else{
        WTError(@"数据格式不对，不是list的json对象（%@）",[object class]);
        return nil;
    }
    
    
}


/**
 key 可以传key[xxx]
 
 @param key <#key description#>
 @return <#return value description#>
 */
-(NSDictionary *)jsonFromDataCache:(NSString*)key isNull:(BOOL)isNull{
    if ([key containsString:@"."]) {
        WTError(@"调用jsonFromDataCache方法失败，key(%@)不能包含.",key);
        return nil;
    }
    NSData *data = [self get:key];
    if (data==nil) {
        
        WTError(@"没有保存key(%@)数据",key);
        return nil;
    }
    NSError *error = nil;
    NSDictionary *object= [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error) {
        WTError(@"数据格式不对，不是json对象");
        return nil;
    }
    return object;
}



-(NSData*)getDataFromListKey:(NSString*)listKey{
    NSData *jsonData = nil;
    NSString   *trueKey = [self getTrueKey:listKey];
    NSArray       *list = [self listFromDataCahe:trueKey];
    if (list.count==0) {
        return jsonData;
    }else{
        long long listIndex = [self getIndexNumber:listKey];
        if (list.count>listIndex) {
            jsonData = [self dataWithJSONObject:list[listIndex]];
            return jsonData;
        }else{
            WTError(@"key=(%@)对应的count(%ld)<=%ld",listKey,list.count,listIndex);
            return jsonData;
        }
    }
    return jsonData;
}



-(NSData *)get:(NSString *)key {
    NSArray *keys = [self checkKey:key];
    if (keys.count==0) {
        return nil;
    }
    NSData *jsonData = nil;
    if(keys.count==1){
        if ([self checkListKey:key]) {
            return [self getDataFromListKey:key];
        }else{
            jsonData = [self->dataCache dataForKey:key];
        }
    }else{
        NSDictionary *object= [self jsonFromDataCache:keys[0] isNull:NO];
        if([self isJsonObject:object keys:keys]){
            NSDictionary *dic = [self getDicFromIndex:object keys:keys index:keys.count-1];
            jsonData = [self dataWithJSONObject:dic];
            if (jsonData) {
                return jsonData;
            }else{
                return nil;
            }
        }else{
            return nil;
        }
    }
    
    return jsonData;
}

- (BOOL)remove:(NSString *)key {
    NSArray *keys = [self checkKey:key];
    if (keys.count==0) {
        return NO;
    }
    if (keys.count==1) {
        if ([self checkListKey:key]) {
            return [self removeDataFromListKey:key oldDic:nil newDic:nil isMove:YES];
        }else{
            [self->dataCache removeDataForKey:key];
            WTDebug(@"删除成功，key=%@",key);
            return YES;
        }
    }else{
        NSDictionary *object= [self jsonFromDataCache:keys[0] isNull:NO];
        if(object){
            return  [self delteData:object keys:keys];
        }else{
            WTDebug(@"删除失败");
            return NO;
        }
        
    }
}


-(BOOL)removeDataFromListKey:(NSString*)listKey oldDic:(NSMutableDictionary*)oldDic newDic:(NSMutableDictionary*)newDic isMove:(BOOL)isMove{
    NSString   *trueKey = [self getTrueKey:listKey];
    NSArray       *list =nil;
    if (oldDic) {
        list = [oldDic objectForKey:trueKey];
    }else{
        list = [self listFromDataCahe:trueKey];
    }
    if (list==nil) {
        WTError(@"删除失败%@",list.count,listKey);
        return NO;
    }
    else{
        long long listIndex = [self getIndexNumber:listKey];
        if (list.count>listIndex) {
            NSMutableArray *newList = [[NSMutableArray alloc]initWithArray:list];
            if (isMove) {
                [newList removeObjectAtIndex:listIndex];
                
            }else{
                [newList replaceObjectAtIndex:listIndex withObject:newDic];
            }
            if (oldDic) {
                if (newList.count==0) {
                    [self remove:trueKey];
                }else{
                    [oldDic setObject:newList forKey:trueKey];
                }
            }else{
                if (newList.count==0) {
                    [self remove:trueKey];
                }else{
                    NSData *newData = [self dataWithJSONObject:newList];
                    [self set:newData forKey:trueKey];
                }
            }
            WTDebug(@"删除成功，key=%@",listKey);
            return YES;
            
        }else{
            WTWarn(@"删除失败list.count(%ld)<=key(%@)",list.count,listKey);
            return NO;
        }
    }
}

-(BOOL)delteData:(NSDictionary*)dic keys:(NSArray*)keys{
    if(dic==nil){
        return NO;
    }
    NSMutableDictionary *newDic=nil;
    for (NSInteger i=keys.count-2; i>=0; i--) {
        NSString *key = keys[i+1];
        NSDictionary *getDic = [self getDicFromIndex:dic keys:keys index:i];
        if ([getDic isKindOfClass: [NSDictionary class]]) {
            NSMutableDictionary *oldDic = [[NSMutableDictionary alloc] initWithDictionary:getDic];
            if (i==keys.count-2) {
                
                NSString *keyRemove = keys[keys.count-1];
                if ([self checkListKey:keyRemove]) {
                    BOOL isRemove=[self removeDataFromListKey:keyRemove oldDic:oldDic  newDic:nil isMove:YES];
                    if (!isRemove) {
                        return NO;
                    }
                    
                }else{
                    [oldDic removeObjectForKey:keyRemove];
                }
                
                newDic = oldDic;
            }else{
                if ([self checkListKey:key]) {
                    BOOL isRemove=[self removeDataFromListKey:key oldDic:oldDic newDic:newDic isMove:NO];
                    if (!isRemove) {
                        return NO;
                    }
                    
                }else{
                    [oldDic setValue:newDic forKey:key];
                }
                newDic = oldDic;
            }
        }else{
            WTError(@"删除失败:objectData格式错误，不是json或者字符串格式");
            newDic = nil;
            break;
        }
    }
    if (newDic) {
        NSData  *data = [self dataWithJSONObject:newDic];
        if (data) {
            BOOL success= [self set:data forKey:keys[0]];
            if (success) {
                WTDebug(@"删除成功，key(%@)删除后数据为：%@",keys[0],newDic);
                
                return YES;
            }else{
                WTError(@"删除失败");
                return NO;
            }
            
        }else{
            WTError(@"删除失败:删除的对象转换成NSData出错（%@）",[newDic class]);
            return NO;
        }
    }else{
        WTError(@"删除失败");
        return NO;
    }
    
}
@end
