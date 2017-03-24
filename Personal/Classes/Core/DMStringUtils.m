//
//  DMStringUtils.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMStringUtils.h"

@implementation DMStringUtils
+(NSString*) trim : (NSString*) str {
    if (str == nil) {
        return nil;
    }
    NSString *cleanString = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return cleanString;
}
+(BOOL) isEmpty : (NSString*) str {
    NSString* cleanStr = [DMStringUtils trim:str];
    if (cleanStr == nil || cleanStr.length == 0) {
        return YES;
    }
    return NO;
}
+(NSString*) firstToUpper : (NSString*) str {
    if (str == nil || str.length == 0) {
        return str;
    }
    return [NSString stringWithFormat:@"%@%@",[[str substringToIndex:1] uppercaseString],[str substringFromIndex:1]];
}
@end
