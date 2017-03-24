//
//  DMBubbleAnimation.h
//  DMAnimation
//
//  Created by chenxinxin on 15/10/21.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DMBubbleAnimation : NSObject

@property (assign,nonatomic) NSTimeInterval beginTime;
@property (assign,nonatomic) NSTimeInterval duration;

/*!
 *  对指定的UIView应用动画
 *
 *  @param view 需要应用动画的View
 */
-(void) animateView:(UIView*) view;

/*!
 *  对一个UIView的集合引用动画
 *  每个View的启动时间将被应用一个随机的偏移
 *  以便看上去动画步调比较自然
 *
 *  @param views 需要应用动画的一个UIView的集合
 */
+(void) animateViews:(NSArray*)views;
@end
