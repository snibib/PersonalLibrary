//
//  DMMagicScrollView.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/30.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DMMagicScrollView;
@protocol DMMagicScrollViewDelegate <NSObject>
@required
/*!
 *  定制初始状态
 *
 *  @param source 需要定制的DMMagicScrollView
 */
-(void) magicScrollViewSetupLeftState:(DMMagicScrollView*)source;

/*!
 *  定制最终状态
 *
 *  @param source 需要定制的DMMagicScrollView
 */
-(void) magicScrollViewSetupRightState:(DMMagicScrollView*)source;

@optional
-(void) magicScrollView:(DMMagicScrollView*)src didUpdateScroll:(float) rate;
@end

@interface DMMagicScrollView : UIView

@property (weak,nonatomic) id<DMMagicScrollViewDelegate> delegate;
@property (assign,nonatomic) CGFloat scrollLength;
@property (assign,nonatomic) CGFloat offsetX;
@property (assign,nonatomic) CGFloat scrollRate;

-(void) scrollToInitState;
-(void) scrollToFinalState;
@end
