//
//  DMPageLifeCircle.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/2.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DMPageLifeCircle <NSObject>
@optional
-(void) pageInit;
/*!
 *  当页面即将向前切换到当前页面时调用
 */
-(void) pageWillForwardToMe;
/*!
 *  当页面已经向前切换到当前页面时调用
 */
-(void) pageDidForwardToMe;
/*!
 *  当页面即将向前离开当前页面时调用
 */
-(void) pageWillForwardFromMe;
/*!
 *  当页面已经向前切换离开当前页面时调用
 */
-(void) pageDidForwardFromMe;

/*!
 *  当页面即将向后回退到当前页面时调用
 */
-(void) pageWillBackwardToMe;
/*!
 *  当页面已经向后回退到当前页面时调用
 */
-(void) pageDidBackwardToMe;

/*!
 *  当页面即将后退离开当前页面时调用
 */
-(void) pageWillBackwardFromMe;

/*!
 *  当页面已经后退离开当前页面时调用
 */
-(void) pageDidBackwardFromMe;

/*!
 *  当页面即将展示时调用(包含页面前进和回退)
 */
-(void) pageWillBeShown;
/*!
 *  当页面已经展示时调用(包含页面前进和后退)
 */
-(void) pageDidShown;

/*!
 *  当页面即将隐藏(包含页面前进和后退)
 */
-(void) pageWillBeHidden;

/*!
 *  当页面已经隐藏(包含前进和后退)
 */
-(void) pageDidHidden;

-(void) pageDestroy;

/*!
 *  页面重新加载刷新，可能是由于后一个页面返回前一个页面导致，也可能是当前页面一些需要导致
 */
-(void) pageReload;
/*!
 * 不能解析url时的回调
 */
-(void)canNotForwardUrl:(NSString *)urlStr;

@end
