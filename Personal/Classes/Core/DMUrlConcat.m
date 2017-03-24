//
//  DMUrlConcat.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMUrlConcat.h"

@implementation DMUrlConcat

+ (NSArray *)concatUrl:(NSURL *)url {
    NSMutableArray *results = [NSMutableArray array];
    
    NSRange baseSeparator = [url.absoluteString rangeOfString:@"/??"];
    NSString *basePath = url.path;
    if (baseSeparator.location != NSNotFound) {
        NSString *urlHost = url.host;
        NSString *urlFullPath  =[url.absoluteString stringByReplacingOccurrencesOfString:@"??" withString:@"@@"];
        
        NSRange parameReparator = [urlFullPath rangeOfString:@"?"];
        if (parameReparator.location != NSNotFound) {
            urlFullPath = [urlFullPath substringToIndex:parameReparator.location];
        }
        
        NSRange hostRange = [urlFullPath rangeOfString:urlHost];
        if (hostRange.location != NSNotFound) {
            urlFullPath = [urlFullPath substringFromIndex:hostRange.location+hostRange.length];
        }
        
        urlFullPath = [urlFullPath stringByReplacingOccurrencesOfString:@"@@" withString:@"??"];
        
        baseSeparator = [urlFullPath rangeOfString:@"/??"];
        basePath = [urlFullPath substringToIndex:baseSeparator.location];
        
        NSString *filePath = [urlFullPath substringFromIndex:baseSeparator.location+baseSeparator.length];
        NSArray *files = [filePath componentsSeparatedByString:@","];
        for (NSString *filePath in files) {
            NSString *fileFullPath = [basePath stringByAppendingPathComponent:filePath];
            [results addObject:fileFullPath];
        }
    }else {
        [results addObject:basePath];
    }
    
    return results;
}

@end
