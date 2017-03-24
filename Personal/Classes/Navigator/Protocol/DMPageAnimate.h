//
//  DMPageAnimate.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 页面跳转动画协议
 * 框架已经提供几种常见的页面跳转动画
 * 如果项目中还需要实现更加高级的动画，
 * 可以通过此协议扩展
 * 动画将可以在页面跳转的url中指定
 */
@protocol DMPageAnimate <NSObject>
/*!
 *  动画实现函数
 *
 *  @param from     起点页面
 *  @param to       终点页面
 *  @param callback 动画结束时的回调
 */
-(void) animateFrom : (UIViewController*) from
                 to : (UIViewController*) to
           callback : (void (^)()) callback;
@end
