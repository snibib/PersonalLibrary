//
//  DMDisplayLinkAnimation.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/30.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMPropertyAnimation : NSObject

@property (assign,nonatomic) NSUInteger loopCount;
@property (assign,nonatomic) NSTimeInterval duration;
@property (assign,nonatomic) NSInteger frameInterval;
@property (copy,nonatomic) void(^ callback)(float) ;

-(void) start;
-(void) stop;

@end
