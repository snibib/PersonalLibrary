//
//  UIWebView+CheckGalleonExist.m
//  Galleon
//
//  Created by 杨涵 on 2017/3/9.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "UIWebView+CheckGalleonExist.h"

@implementation UIWebView (CheckGalleonExist)

- (BOOL)checkGalleonAnchorExist {
    return [[self stringByEvaluatingJavaScriptFromString:
                    @"(function (){ \
                                    if (galleon && galleon.anchor && galleon.anchor.back)            \
                                    {                                               \
                                        return true;                                \
                                    }                                               \
                                    return false;                                   \
                    })();"
     ] boolValue];
}

- (void)galleonAnchorBack {
    [self stringByEvaluatingJavaScriptFromString:@"galleon.anchor.back && galleon.anchor.back()"];
}
@end
