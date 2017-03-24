//
//  DMPage+DefaultNavigatorBar.h
//  Galleon
//
//  Created by 杨涵 on 2017/3/10.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "DMPage.h"

@interface DMPage (DefaultNavigatorBar)

/*!
 * true为显示，false为隐藏,默认值为false
 */
@property (nonatomic, assign)   BOOL        showDefaultNavigatorBar;

- (void)setDefaultTitle:(NSString *)title;
- (void)setLeftView:(UIView *)leftView;
- (void)setRightView:(UIView *)rightView;

@end
