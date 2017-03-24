//
//  DMUrlEncoder.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/28.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DMUrlEncoder : NSObject

+(NSString*) encodeParams:(NSDictionary*)param;

+(NSString*) escape : (NSString*)param;

+(NSString*) unescape : (NSString*)param;
@end