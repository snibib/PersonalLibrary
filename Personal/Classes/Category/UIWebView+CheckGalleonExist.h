//
//  UIWebView+CheckGalleonExist.h
//  Galleon
//
//  Created by 杨涵 on 2017/3/9.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (CheckGalleonExist)

/*!
 * 校验galleon是否存在于webview中
 */
- (BOOL)checkGalleonAnchorExist;

/*!
 * 执行anchor.back进行跳转
 */
- (void)galleonAnchorBack;
@end
