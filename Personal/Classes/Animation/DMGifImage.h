//
//  DMGifImage.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/12/23.
//  Copyright © 2015年 dmall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DMGifImage : NSObject
-(instancetype) initWithData:(NSData*) data;

-(UIImage*) imageAtIndex:(NSUInteger) index;
-(NSUInteger) imageCount;
-(NSTimeInterval) delay;

@end
