//
//  DKBaseRequest.m
//  DKall
//
//  Created by chris on 15/4/28.
//  Copyright (c) 2015年 wintech. All rights reserved.
//

#import "DKBaseRequest.h"
#import "DKBaseResponse.h"
#import "WTLog.h"


@implementation DKBaseRequest

+ (BOOL) propertyIsIgnored:(NSString *)propertyName{
    
    if([propertyName isEqualToString:@"url"]||
       [propertyName isEqualToString:@"path"]||
       [propertyName isEqualToString:@"method"]||
       [propertyName isEqualToString:@"timeoutInterval"])
        
        return YES;
    
    return NO;
    
}


- (DKBaseResponse*) responseFromObject:(id)object{
    
    NSString *className = NSStringFromClass([self class]);
    className = [className stringByReplacingOccurrencesOfString:@"Request" withString:@"Response"];
    Class class = NSClassFromString(className);
    
    NSError *error;
    DKBaseResponse *response = [[class alloc] initWithDictionary:object error:&error];
    if(error || !response)
    {
        WTWarn(@"base responses error = %@",error);
        response = [[DKBaseResponse alloc] initWithDictionary:object error:&error];
    }
    
    return response;
}

- (NSDictionary*)parameters{
    
    return [self toDictionary];
}

- (NSString*)jsonString{
    
    return [self toJSONString];
}

- (NSDictionary*)customParameters{
    
    NSString *json = [self jsonString];
	WTDebug(@"请求参数：%@", json);
    if (json.length < 3) {
        return nil;
    } else {
        return @{@"param":json};
    }
}

- (NSDictionary *)uploadParameters {
    return @{@"path":self.path};
}

- (NSString*) method{
    
    return @"POST";
}

- (NSTimeInterval) timeoutInterval{
    
    if(_timeoutInterval>0.0)
        return _timeoutInterval;
    else
        return 20.0;
}


@end
