//
//  WTLog.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "WTLog.h"


#define NSLog(FORMAT, ...) do {fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);} while(0)

@interface WTLog()
@property (strong,nonatomic) NSString* name;

@end

@implementation WTLog

static WTLog *sharedInstance;

+ (instancetype)sharedInstance {
    
    static dispatch_once_t DDTTYLoggerOnceToken;
    
    dispatch_once(&DDTTYLoggerOnceToken, ^{
        
        sharedInstance = [[[self class] alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if (sharedInstance != nil) {
        return nil;
    }
    if ((self = [super init])) {
        _logLevel = WTLogLevelOff;
    }
    return self;
}

+ (void)log:(WTLogLevel)level
    context:(NSInteger)context
  className:(const char *)className
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ...{
    va_list args;
    if (format) {
        va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    [self.sharedInstance log:message level:level context:context className:className function:function line:line];
        va_end(args);
    }
}
- (void)log:(NSString *)message
      level:(WTLogLevel)level
    context:(NSInteger)context
  className:(const char *)className
   function:(const char *)function
       line:(NSUInteger)line
{
    
    
    switch (level) {
        case WTLogLevelOff:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelOff) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];
            }else{
                return;
            }
            break;
        }
        case WTLogLevelError:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelError) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];
            }else{
                return;
            }
            break;
        }
        case WTLogLevelWarning:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelWarning) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];
            }else{
                return;
            }
            break;
        }
        case WTLogLevelInfo:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelInfo) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];
            }else{
                return;
            }
            break;
        }
        case WTLogLevelDebug:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelDebug) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];
            }else{
                return;
            }
            break;
        }
        case WTLogLevelVerbose:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelVerbose) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];
            }else{
                return;
            }
            break;
        }
        case WTLogLevelAll:
        {
            if ([WTLog sharedInstance].logLevel>=WTLogLevelAll) {
                [[WTLog sharedInstance] printLog:message  level:level context:context className:className function:function line:line];            }else{
                return;
            }
            break;
        }
        
        default:
            break;
    }
}

-(void)printLog:(NSString*)message
          level:(WTLogLevel)level
        context:(NSInteger)context
      className:(const char *)className
       function:(const char *)function
           line:(NSUInteger)line{
    NSString *str=[NSString stringWithCString:className encoding:NSUTF8StringEncoding];
    NSLog(@"[Watchtower_%@:%ld %@]\n%@ \n",[str lastPathComponent],(long)line,[[WTLog sharedInstance]levelToString:level],message);
//    NSLog(@"[Watchtower_%s:%ld %@]%@ \n",className,(long)line,[[WTLog sharedInstance]levelToString:level],message);
}


-(NSString*) levelToString:(enum WTLogLevel)level {
    if (level == WTLogLevelDebug) {
        return @"debug";
    }
    if (level == WTLogLevelInfo) {
        return @"info";
    }
    if (level == WTLogLevelWarning) {
        return @"warn";
    }
    if (level == WTLogLevelError) {
        return @"error";
    }
    if (level == WTLogLevelVerbose) {
        return @"verbose";
    }
    return @"log";
}







@end
