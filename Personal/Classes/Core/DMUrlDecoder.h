//
//  DMUrlDecoder.h
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMUrlInfo : NSObject
@property (strong,nonatomic) NSString* url;
@property (strong,nonatomic) NSString* urlOrigin;
@property (strong,nonatomic) NSString* urlPath;
@property (strong,nonatomic) NSString* protocol;
@property (strong,nonatomic) NSString* animation;
@property (strong,nonatomic) NSString* appPageName;
@property (strong,nonatomic) NSString* appH5PageName;
@property (strong,nonatomic) NSMutableDictionary* params;
@property (strong,nonatomic) NSMutableDictionary* pageContext;
@property (strong,nonatomic) NSMutableDictionary* frameworkParams;

//用于处理之前页面的信息
@property (strong,nonatomic) NSString* prePageUrl;
@property (assign,nonatomic) NSInteger prePos;
@property (assign,nonatomic) NSInteger pagePos;
@end


@interface DMUrlDecoder : NSObject

+(DMUrlInfo*) decodeUrl:(NSString*)url;

+(DMUrlInfo*) decodeParams:(NSString*)paramUrl;

@end
