//
//  DMUrlConcat.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMUrlConcat : NSObject

/*
 * 对多路径的url实现concat, 返回所有路径
 */
+ (NSArray *)concatUrl:(NSURL *)url;

@end
