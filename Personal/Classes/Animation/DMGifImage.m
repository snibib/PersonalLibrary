//
//  DMGifImage.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/12/23.
//  Copyright © 2015年 dmall. All rights reserved.
//

#import "DMGifImage.h"
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

@interface DMGifImage()
@property (assign,nonatomic) CGImageSourceRef imageSource;
@property (assign,nonatomic) NSUInteger imageCount;
@property (assign,nonatomic) NSTimeInterval delay;
@end

@implementation DMGifImage

-(instancetype) initWithData:(NSData *)data {
    if (self = [super init]) {
        self->_imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        self->_imageCount = CGImageSourceGetCount(_imageSource);
        NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        NSDictionary *framePropertiesGIF = [frameProperties objectForKey:(id)kCGImagePropertyGIFDictionary];
        
        // Try to use the unclamped delay time; fall back to the normal delay time.
        NSNumber *delayTime = [framePropertiesGIF objectForKey:(id)kCGImagePropertyGIFUnclampedDelayTime];
        self.delay = delayTime.floatValue;
    }
    return self;
}


-(UIImage*) imageAtIndex:(NSUInteger) index {
    if (index >= self.imageCount) {
        index = self.imageCount - 1;
    }
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, index, NULL);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CFRelease(imageRef);
    return image;
}

- (void)dealloc
{
    if (self->_imageSource) {
        CFRelease(self->_imageSource);
    }
}

@end
