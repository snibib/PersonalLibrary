//
//  DMMagicMoveCell.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/9.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DMMagicMoveCell : NSObject

@property (strong,nonatomic) UIView* view;
@property (assign,nonatomic) BOOL rotate3DByX;
@property (assign,nonatomic) BOOL rotate3DByY;

-(instancetype) init;
-(instancetype) initWithView:(UIView*)view rotate3DByX:(BOOL)enableX rotate3DByY:(BOOL)enableY;

@end
