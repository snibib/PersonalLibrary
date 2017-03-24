//
//  DMPageAware.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/2.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DMNavigator;

/*!
 *  如果页面需要自省，可实现此协议, 获取到需要的信息
 */
@protocol DMPageAware <NSObject>
/*!
 *  页面导航控制器
 */
@property (weak,nonatomic) DMNavigator* navigator;
/*!
 *  页面参数
 */
@property (strong,nonatomic) NSDictionary* pageParams;

/*!
 *  页面对象，也叫页面上下文
 */
@property (strong,nonatomic) NSDictionary* pageContext;

/*!
 *  框架参数
 */
@property (strong,nonatomic) NSDictionary* frameworkParams;

/*!
 *  跳转时传入的url(不包含传递给框架的参数,及@开头的参数)
 */
@property (strong,nonatomic) NSString* pageUrl;

@property (strong,nonatomic) NSString* pageName;

@property (strong,nonatomic) NSString* replaceStateUrl;

@property (strong,nonatomic) NSString* prePageUrl;
@property (assign,nonatomic) NSInteger prePos;
@property (assign,nonatomic) NSInteger pagePos;
/*!
 *  向上一个页面回传数据的接口
 */
@property (copy,nonatomic) void (^ pageCallback)(NSDictionary *dict);

@end
