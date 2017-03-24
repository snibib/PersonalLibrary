//
//  DMUrlDecoder.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMUrlDecoder.h"
#import "DMUrlEncoder.h"
#import "DMStringUtils.h"


@implementation DMUrlInfo
-(NSMutableDictionary*) params {
    if (self->_params == nil) {
        self->_params = [[NSMutableDictionary alloc] init];
    }
    return self->_params;
}
- (NSMutableDictionary *)pageContext {
    if (self->_pageContext == nil) {
        self->_pageContext = [[NSMutableDictionary alloc] init];
    }
    return self->_pageContext;
}
-(NSMutableDictionary*) frameworkParams {
    if (self->_frameworkParams == nil) {
        self->_frameworkParams = [[NSMutableDictionary alloc] init];
    }
    return self->_frameworkParams;
}
@end

@implementation DMUrlDecoder
/*!
 *  将url解析成模型
 *
 *  @param url 待解析的url
 *
 *  @return 解析后的信息
 */
+(DMUrlInfo*) decodeUrl:(NSString*)url {
    DMUrlInfo* info = nil;
    url             = [DMStringUtils trim:url];
    NSRange hashkey = [url rangeOfString:@"#"];
    
    if (hashkey.location != NSNotFound) {
        NSString *urlTemp = [url stringByReplacingOccurrencesOfString:@"://" withString:@"^//"];
        NSRange colons = [urlTemp rangeOfString:@":"];
        
        if (colons.location != NSNotFound) {
            NSString *paramUrl = [url substringFromIndex:colons.location+1];
            info               = [DMUrlDecoder decodeParams:paramUrl];
            info.urlPath       = [url substringToIndex:colons.location];
        }else {
            info               = [[DMUrlInfo alloc] init];
            info.urlPath       = url;
        }
    }else {
        NSRange stub    = [url rangeOfString:@"?"];
        
        if(stub.location != NSNotFound) {
            NSString* paramUrl  = [url substringFromIndex:stub.location + 1];
            info                = [DMUrlDecoder decodeParams:paramUrl];
            info.urlPath        = [url substringToIndex:stub.location];
        } else {
            info            = [[DMUrlInfo alloc] init];
            info.urlPath    = url;
        }
    }
    
    info.urlOrigin = url;
    
    NSRange protocolStub = [url rangeOfString:@"://"];
    if (protocolStub.location != NSNotFound) {
        info.protocol = [url substringToIndex:protocolStub.location];
        NSCharacterSet *characterSet = nil;
        if (hashkey.location != NSNotFound) {
            characterSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
        }else {
            characterSet = [NSCharacterSet characterSetWithCharactersInString:@"?"];
        }
        NSArray* pathComponents = [[url substringFromIndex:protocolStub.location+3] componentsSeparatedByCharactersInSet:characterSet];
        info.appPageName = pathComponents[0];
        NSString *appH5PageName = [info.params objectForKey:@"appH5PageName"];
        if (appH5PageName.length>0) {
            info.appH5PageName = appH5PageName;
        }
    }
    
    NSMutableString* buffer = [[NSMutableString alloc] init];
    [buffer appendString:info.urlPath];
    if (info.params.count > 0) {
        if (hashkey.location != NSNotFound) {
            [buffer appendString:@":"];
        }else {
            [buffer appendString:@"?"];
        }
        
        NSEnumerator *enumerator    = [info.params keyEnumerator];
        id key                      = nil;
        BOOL first                  = YES;
        
        while ((key = [enumerator nextObject])) {
            if (first) {
                first = NO;
            } else {
                [buffer appendString:@"&"];
            }
            id value = [info.params objectForKey:key];
            if([DMStringUtils isEmpty:value]) {
                [buffer appendString:[DMUrlEncoder escape:key]];
            } else {
                [buffer appendFormat:@"%@=%@",[DMUrlEncoder escape:key],[DMUrlEncoder escape:value]];
            }
        }
    }
    info.url = buffer;
    return info;
}
/*!
 *  只解析url中参数的部分
 *
 *  @param paramUrl 待解析的url
 *
 *  @return 解析后的模型
 */
+(DMUrlInfo*) decodeParams:(NSString*)paramUrl {
    if([DMStringUtils isEmpty:paramUrl]) {
        return nil;
    }
    
    DMUrlInfo* info = [[DMUrlInfo alloc] init];
    paramUrl        = [DMStringUtils trim:paramUrl];
    info.urlOrigin  = paramUrl;
    info.url        = paramUrl;
    
    NSArray* components = [paramUrl componentsSeparatedByString:@"&"];
    for (NSString* element in components) {
        //为了能兼容url中的数组或者字典，顾不能直接以=进行分隔
        //获取第一个 =
        //为了安全，参数建议进行编码
        NSRange separaLocation = [element rangeOfString:@"="];
        if (separaLocation.location != NSNotFound) {
            NSString *elementBuf = [element stringByReplacingCharactersInRange:separaLocation withString:@"!="];
            NSArray* keyValuePair   =  [elementBuf componentsSeparatedByString:@"!="];
            if (keyValuePair.count < 2) {
                [info.params setObject:@"" forKey:element];
                continue;
            }
            NSString* key           =  [DMStringUtils trim:[DMUrlEncoder unescape:keyValuePair[0]]];
            NSString* value         =  [DMStringUtils trim:[DMUrlEncoder unescape:keyValuePair[1]]];
            if ([key rangeOfString:@"@"].location == 0) {
                [info.frameworkParams setObject:value forKey:[key substringFromIndex:1]];
            } else {
                [info.params setObject:value forKey:key];
            }
        }
    }
    return info;
}


@end
