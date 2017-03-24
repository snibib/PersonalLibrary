//
//  DMSafeThread.h
//  Galleon
//
//  Created by 杨涵 on 2017/3/9.
//  Copyright © 2017年 yanghan. All rights reserved.
//

//主线程安全检查
#ifndef galleon_main_sync_safe
#define galleon_main_sync_safe(block)\
if([NSThread isMainThread]) {\
    block();\
}else {\
    dispatch_sync(dispatch_get_main_queue(), block);\
}
#endif

#ifndef galleon_main_async_safe
#define galleon_main_async_safe(block)\
if([NSThread isMainThread]) {\
    block();\
}else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}
#endif
