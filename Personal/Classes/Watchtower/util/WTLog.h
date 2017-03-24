//
//  WTLog.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WTUpdateUtil.h"
#define WTDebug(frmt, ...) \
WTLog_GO(WTLogLevelDebug,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


#define WTInfo(frmt, ...) \
WTLog_GO(WTLogLevelInfo,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


#define WTWarn(frmt, ...) \
WTLog_GO(WTLogLevelWarning,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


#define WTError(frmt, ...) \
WTLog_GO(WTLogLevelError,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


#define WTVerbose(frmt, ...) \
WTLog_GO(WTLogLevelVerbose,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define WTLogAll(frmt, ...) \
WTLog_GO(WTLogLevelAll,   0, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)



#define WTLog_GO( lvl,ctx, fnct, frmt, ...) \
[WTLog log : lvl                                                \
   context : ctx                                                \
 className : __FILE__                                           \
  function : fnct                                               \
      line : __LINE__                                           \
    format : (frmt), ## __VA_ARGS__]





@interface WTLog : NSObject


@property (assign,nonatomic) WTLogLevel logLevel;

+ (instancetype)sharedInstance;


+ (void)log:(WTLogLevel)level
    context:(NSInteger)context
  className:(const char *)className
   function:(const char *)function
       line:(NSUInteger)line
     format:(NSString *)format, ...;

@end
