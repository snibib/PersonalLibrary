//
//  DMDropBoxAnimation.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/10.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface DMDropBoxAnimation : NSObject


-(void) animateDropView:(UIView*)view toBox:(UIView*)box;

+(void) animate:(UIView*)view toBox:(UIView*)box;

@end
