//
//  DMMutiProxy.h
//  DMTools
//
//  Created by chenxinxin on 15/10/23.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 *  DMMutiProxy是动态代理类型，它可以截获对自己的函数调用，同时将调用转发给proxies多个代理来处理.
 *  这个类的功能可以弥补很多iOS View的delegate只能一对一回调的缺陷。这样就可以在事件源的回调转发给
 *  多个proxy对象包括原有事件监听者来处理，允许框架设计者和框架使用者同时关注一对一的事件. 
 */
@interface DMMutiProxy : NSObject

@property (strong,nonatomic) NSMutableArray* proxies;

- (void)addProxy:(id)proxy;

- (void)addWeakProxy:(id)proxy;

@end
