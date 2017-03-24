//
//  DMLog.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMLog.h"
#import "DMStringUtils.h"

@interface DMLog()
@property (strong,nonatomic) NSString* name;
@end

@implementation DMLog

int DMLog_level = DMLogLevelInfo;
NSString* DMLog_filter = nil;
NSString* DMLog_msgFilter = nil;

+(void) setLogLevel:(enum DMLogLevel) level {
    DMLog_level = level;
}
+(void) setNameFilter:(NSString*)filter {
    DMLog_filter = filter;
}
+(void) setMessageFilter:(NSString*)filter {
    DMLog_msgFilter = filter;
}
+(void) setClassFilter:(Class)filter {
    DMLog_filter = NSStringFromClass(filter);
}
+(BOOL) isLogEnable:(enum DMLogLevel) level {
    return level >= DMLog_level;
}

+(NSString*) levelToString:(enum DMLogLevel)level {
    if (level == DMLogLevelDebug) {
        return @"debug";
    }
    if (level == DMLogLevelInfo) {
        return @" info";
    }
    if (level == DMLogLevelWarn) {
        return @" warn";
    }
    if (level == DMLogLevelError) {
        return @"error";
    }
    if (level == DMLogLevelFatal) {
        return @"fatal";
    }
    return @"log";
}

+(enum DMLogLevel) levelFromString:(NSString*) level {
    level = [DMStringUtils trim:level];
    if ([@"debug" isEqualToString:level]) {
        return DMLogLevelDebug;
    }
    if ([@"info" isEqualToString:level]) {
        return DMLogLevelInfo;
    }
    if ([@"warn" isEqualToString:level]) {
        return DMLogLevelWarn;
    }
    if ([@"error" isEqualToString:level]) {
        return DMLogLevelError;
    }
    if ([@"fatal" isEqualToString:level]) {
        return DMLogLevelFatal;
    }
    return DMLogLevelInfo;
}

+(NSString*) colorForLevel:(enum DMLogLevel) level {
    if (level == DMLogLevelFatal) {
        return @"255,0,0";
    }
    if (level == DMLogLevelError) {
        return @"255,97,0";
    }
    if (level == DMLogLevelWarn) {
        return @"255,215,0";
    }
    if (level == DMLogLevelInfo) {
        return @"0,255,0";
    }
    return @"255,255,255";
}

+(void) log:(NSString*)msg name:(NSString*)name level:(enum DMLogLevel)level {
    if (msg == nil) {
        return;
    }
    
    if (![DMLog isLogEnable:level]) {
        return;
    }
    
    if (DMLog_filter != nil && name != nil) {
        NSRange range = [name rangeOfString:DMLog_filter options:NSRegularExpressionSearch];
        if (range.location == NSNotFound) {
            return;
        }
    }
    
    if (DMLog_msgFilter != nil) {
        NSRange range = [msg rangeOfString:DMLog_msgFilter options:NSRegularExpressionSearch];
        if (range.location == NSNotFound) {
            return;
        }
    }
    
    NSLog(@"\033[fg65,105,225;[%@ %@]\033[; \033[fg%@; %@ \033[;\n",name,[DMLog levelToString:level],[DMLog colorForLevel:level],msg);
    
    if(level >= DMLogLevelWarn) {
        NSString* callstack = [[NSThread callStackSymbols] description];
        NSLog(@"\033[fg%@;%@\033[;\n",[DMLog colorForLevel:level],callstack);
    }
}


-(instancetype) initWithClass:(Class)clazz {
    if (self = [super init]) {
        self.name = NSStringFromClass(clazz);
        self.level = DMLogLevelDebug; // 默认由全局的开关控制, 因此此处全开，在全局打开的情况下，单个logger可以更细的设置级别
    }
    return self;
}

-(BOOL) isEnable:(enum DMLogLevel) level {
    return level >= self.level && [DMLog isLogEnable:level];
}

-(void) debug:(NSString*)msg {
    if (![self isEnable:DMLogLevelDebug]) {
        return;
    }
    [DMLog log:msg name:self.name level:DMLogLevelDebug];
}
-(void) info:(NSString*)msg {
    if (![self isEnable:DMLogLevelInfo]) {
        return;
    }
    [DMLog log:msg name:self.name level:DMLogLevelInfo];
}
-(void) warn:(NSString*)msg {
    if (![self isEnable:DMLogLevelWarn]) {
        return;
    }
    [DMLog log:msg name:self.name level:DMLogLevelWarn];
}
-(void) error:(NSString*)msg {
    if (![self isEnable:DMLogLevelError]) {
        return;
    }
    [DMLog log:msg name:self.name level:DMLogLevelError];
}
-(void) fatal:(NSString*)msg {
    if (![self isEnable:DMLogLevelFatal]) {
        return;
    }
    [DMLog log:msg name:self.name level:DMLogLevelFatal];
}


+(void) initialize {
    NSString* propertyFile = [[NSBundle mainBundle] pathForResource:@"DMLog.plist" ofType:nil];
    if (propertyFile) {
        NSDictionary* propertyDic = [NSDictionary dictionaryWithContentsOfFile:propertyFile];
        NSString* logLevel = [propertyDic objectForKey:@"LogLevel"];
        if (![DMStringUtils isEmpty:logLevel]) {
            [DMLog setLogLevel:[DMLog levelFromString:logLevel]];
        }
        NSString* nameFilter = [propertyDic objectForKey:@"NameFilter"];
        if (![DMStringUtils isEmpty:nameFilter]) {
            [DMLog setNameFilter:nameFilter];
        }
        NSString* messageFilter = [propertyDic objectForKey:@"MessageFilter"];
        if (![DMStringUtils isEmpty:messageFilter]) {
            [DMLog setMessageFilter:messageFilter];
        }
    }
}

@end
