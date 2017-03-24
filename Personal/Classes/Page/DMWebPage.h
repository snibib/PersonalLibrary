//
//  DMWebPage.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMPage.h"
#import <UIKit/UIKit.h>

@interface DMWebPage : DMPage

@property (strong, nonatomic)   UIWebView *webView;

/*!
 *  如果通过loadView来定制页面，也就是直接通过代码创建页面
 *  需要在loadView实现里需要为此类的webView属性赋值,
 *  DMWebPage对象将负责和webView里的h5页面交互
 */
- (void)loadView;

/*!
 * 修改webview的frme
 */
- (void)updateWebViewFrame:(CGRect)frame;

@end
