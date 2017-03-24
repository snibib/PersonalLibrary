//
//  DMPullToRefreshView.h
//  DMTools
//
//  Created by chenxinxin on 15/10/23.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DMPullToRefreshView;

/*!
 *  下拉刷新的回调接口
 */
@protocol DMPullToRefreshViewDelegate <NSObject>
@optional
/*!
 *  当触发下拉刷新时调用
 *
 *  @param pullToRefreshView 触发刷新的下拉控件
 *  @param refresh           是否刷新
 */
-(void)pullToRefreshViewDidRefresh:(DMPullToRefreshView*)pullToRefreshView;
-(void)pullToRefreshViewPullBegin:(DMPullToRefreshView*)pullToRefreshView;
-(void)pullToRefreshViewPullEnd:(DMPullToRefreshView*)pullToRefreshView;
@end

/*!
 *  下拉刷新控件。此控件可以组合任何继承自scrollView的滚动控件。
 *  例如UITableView, UIScrollView, UIWebView等等。
 *  需要注意一个细节. 如果这些滚动控件的delegate被占用,
 */
@interface DMPullToRefreshView : UIView

@property (assign,nonatomic) BOOL pullEnable;


@property (weak,nonatomic) id<DMPullToRefreshViewDelegate> delegate;

/*!
 *  请确保在设置了scrollView之后其delegate不会被修改，如果开发者自己也需要关注scrollView的delegate回调，
 *  请在设置scrollView之前先设置好delegate, 再将scrollView设置到PullToRefreshView中
 */
@property (weak,nonatomic) UIScrollView* scrollView;

/*!
 *  下拉出现的头部箭头图片，下拉过程中箭头可能发生旋转，如果旋转之后再松手将触发刷新
 */
@property (strong,nonatomic) UIImage* headerArrowImage;
/*!
 *  下拉出现的头部背景图片. 控件会自动缩放图片填满整个Header, 并同事根据
 *  图片的长宽比例来决定Header的总体高度。
 */
@property (strong,nonatomic) UIImage* headerBackgroundImage;

@property (strong,nonatomic) NSData* headerBackgroundGif;

@property (assign,nonatomic) CGRect headerBackgroundFrame;

/*!
 *  头部箭头的高度，此字段有默认值。(单位为像素)
 */
@property (assign,nonatomic) CGFloat headerArrowHeight;
/*!
 *  头部箭头距离Header底部的间隔(单位为像素)
 */
@property (assign,nonatomic) CGFloat headerArrowMarginBottom;
/*!
 *  在下拉时箭头旋转的时间长度(单位为秒)
 */
@property (assign,nonatomic) CGFloat headerArrowRotateDuration;


///headview的高宽比例，传进来
@property (assign, nonatomic) CGFloat   headScaleRatio;


-(void) notifyDataLoaded;

-(void) notifyDataLoaded:(void(^)()) callback;

@end
