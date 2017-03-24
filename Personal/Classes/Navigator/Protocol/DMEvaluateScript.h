//
//  DMEvaluateScript.h
//  Deck
//
//  Created by 杨涵 on 2016/12/14.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DMEvaluateScript <NSObject>

- (NSString *)evaluateScript:(NSString *)script;

@end
