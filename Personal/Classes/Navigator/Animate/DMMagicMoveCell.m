//
//  DMMagicMoveCell.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/9.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMMagicMoveCell.h"

@implementation DMMagicMoveCell

-(instancetype) init {
    if(self = [super init]) {
        self.rotate3DByX = NO;
        self.rotate3DByY = NO;
    }
    return self;
}

-(instancetype) initWithView:(UIView*)view rotate3DByX:(BOOL)enableX rotate3DByY:(BOOL)enableY {
    if(self = [super init]) {
        self.view = view;
        self.rotate3DByX = enableX;
        self.rotate3DByY = enableY;
    }
    return self;
}

@end
