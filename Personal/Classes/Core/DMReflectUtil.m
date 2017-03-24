//
//  DMReflectUtil.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/12/21.
//  Copyright © 2015年 dmall. All rights reserved.
//

#import "DMReflectUtil.h"

@implementation DMReflectUtil

+(NSNumber*) numberFromString:(NSString*)value signature:(const char*)type {
    if (strcmp(type, "c") == 0) {
        char v = 0;
        if ([value hasPrefix:@"'"] && [value hasSuffix:@"'"] && value.length == 3) {
            v = [value characterAtIndex:1];
        } else {
            v = [value intValue];
        }
        if ([@"true" isEqualToString:value] || [@"YES" isEqualToString:value]) {
            v = 1;
        }
        if ([@"false" isEqualToString:value] || [@"NO" isEqualToString:value]) {
            v = 0;
        }
        return [NSNumber numberWithChar:v];
    }
    if (strcmp(type, "i") == 0) {
        return @([value intValue]);
    }
    if (strcmp(type, "I") == 0) {
        return @((unsigned int)[value intValue]);
    }
    if (strcmp(type, "s") == 0) {
        return @([value intValue]);
    }
    if (strcmp(type, "S") == 0) {
        return @([value intValue]);
    }
    if (strcmp(type, "l") == 0) {
        return @([value longLongValue]);
    }
    if (strcmp(type, "L") == 0) {
        return @([value longLongValue]);
    }
    if (strcmp(type, "f") == 0) {
        return @([value floatValue]);
    }
    if (strcmp(type, "d") == 0) {
        return @([value doubleValue]);
    }
    if (strcmp(type, "B") == 0) {
        return @([value boolValue]);
    }
    if (strcmp(type, "q") == 0) {
        return @([value longLongValue]);
    }
    return nil;
}

@end
