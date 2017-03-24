//
//  DMStringUtils.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMStringUtils : NSObject
/*!
 *  去除字符串首尾的空字符
 *
 *  @param str 待处理的字符串
 *
 *  @return 处理后的字符串
 */
+(NSString*) trim : (NSString*) str;

+(BOOL) isEmpty : (NSString*) str;

+(NSString*) firstToUpper : (NSString*) str;
@end
