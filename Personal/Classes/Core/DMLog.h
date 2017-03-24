//
//  DMLog.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DMLOG_DEFINE(className)\
DMLog* className##_logger = nil;\
+(DMLog*) logger {\
if(className##_logger == nil) {\
className##_logger = [[DMLog alloc] initWithClass:[className class]];\
}\
return className##_logger;\
}\
-(DMLog*) logger {\
return [className logger];\
}

#define DMDebugEnabled() \
[self.logger isEnable:DMLogLevelDebug]

#define DMInfoEnabled() \
[self.logger isEnable:DMLogLevelInfo]

#define DMWarnEnabled() \
[self.logger isEnable:DMLogLevelWarn]

#define DMErrorEnabled() \
[self.logger isEnable:DMLogLevelError]

#define DMFatalEnabled() \
[self.logger isEnable:DMLogLevelFatal]

#define DMDebug( ... ) \
if ([self.logger isEnable:DMLogLevelDebug]) {\
[self.logger debug:[NSString stringWithFormat:__VA_ARGS__]];\
}

#define DMInfo( ... ) \
if ([self.logger isEnable:DMLogLevelInfo]) {\
[self.logger info:[NSString stringWithFormat:__VA_ARGS__]];\
}

#define DMWarn( ... ) \
if ([self.logger isEnable:DMLogLevelWarn]) {\
[self.logger warn:[NSString stringWithFormat:__VA_ARGS__]];\
}

#define DMError( ... ) \
if ([self.logger isEnable:DMLogLevelError]) {\
[self.logger error:[NSString stringWithFormat:__VA_ARGS__]];\
}

#define DMFatal( ... ) \
if ([self.logger isEnable:DMLogLevelFatal]) {\
[self.logger fatal:[NSString stringWithFormat:__VA_ARGS__]];\
}


typedef NS_ENUM(NSInteger, DMLogLevel) {
    DMLogLevelDebug,//默认从0开始
    DMLogLevelInfo,
    DMLogLevelWarn,
    DMLogLevelError,
    DMLogLevelFatal,
    DMLogLevelSilent
};


@interface DMLog : NSObject


+ (BOOL)isLogEnable:(enum DMLogLevel) level;

- (instancetype)initWithClass:(Class)clazz;

@property (assign,nonatomic) enum DMLogLevel level;

- (BOOL)isEnable:(enum DMLogLevel) level;
- (void)debug:(NSString*)msg;
- (void)info:(NSString*)msg;
- (void)warn:(NSString*)msg;
- (void)error:(NSString*)msg;
- (void)fatal:(NSString*)msg;
@end
