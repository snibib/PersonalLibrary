//
//  DMGifView.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/5.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMGifView.h"
#import <QuartzCore/QuartzCore.h>
#import "DMLog.h"
#import "DMPropertyAnimation.h"
#import "DMGifImage.h"
#import "DMWeakify.h"

@interface DMGifView()

@property (nonatomic, assign) NSInteger             loopCount;//循环次数
@property (strong,nonatomic) NSData                 *gifData;
@property (assign,nonatomic) CGSize innerImageSize;

@property (strong,nonatomic) DMPropertyAnimation* propertyAnimation;
@property (strong,nonatomic) DMGifImage* gifImage;
@end

@implementation DMGifView

DMLOG_DEFINE(DMGifView)

-(void) setImageFileName:(NSString *)imageFileName {
    _imageFileName = imageFileName;
    
    NSString *lastStr = nil;

    if (imageFileName.length > 4) {
        lastStr = [imageFileName substringFromIndex:imageFileName.length-4];
    }

    NSString* filePath = nil;
    if (lastStr.length == 4 && [lastStr isEqualToString:@".gif"]) {
        NSString *imgStr = [imageFileName substringToIndex:imageFileName.length-4];
        filePath = [[NSBundle mainBundle] pathForResource:imgStr ofType:@"gif"];
    }else{
        filePath = [[NSBundle mainBundle] pathForResource:imageFileName ofType:@"gif"];
    }
    [self loadFromData:[NSData dataWithContentsOfFile:filePath]];
}

-(CGSize) imageSize {
    return self.innerImageSize;
}


-(void) loadFromData:(NSData*)data {
    self.gifData = data;
    
    self.gifImage = [[DMGifImage alloc] initWithData:data];
    
    if (self.gifImage.imageCount <= 0) {
        return;
    }
    
    UIImage* firstFrameImage = [self.gifImage imageAtIndex:0];
    float dpWidth = firstFrameImage.size.width * firstFrameImage.scale / 3;
    float dpHeight = firstFrameImage.size.height * firstFrameImage.scale / 3;
    self.innerImageSize = CGSizeMake(dpWidth, dpHeight);
    self.propertyAnimation.duration = self.gifImage.delay * self.gifImage.imageCount;
    
    [self startAnimating];
}


- (void)setRate:(float)rate {
    if (rate<0 || rate>1) {
        return;
    }
    
    if (self->_gifImage == nil) {
        return;
    }
    
    int count = (int)self.gifImage.imageCount;
    int current = count * rate;
    self.image = [self.gifImage imageAtIndex:current];
}

-(DMPropertyAnimation*) propertyAnimation {
    if (self->_propertyAnimation == nil) {
        self->_propertyAnimation = [[DMPropertyAnimation alloc] init];
        self->_propertyAnimation.duration = 2;
        self->_propertyAnimation.loopCount = 0;
        
        @weakify_self
        self->_propertyAnimation.callback = ^(float rate){
            @strongify_self
            self.rate = rate;
        };
    }
    return self->_propertyAnimation;
}


-(void) playOnce {
    DMDebug(@"playOnce");
    self.propertyAnimation.loopCount = 1;
    [self startAnimating];
}

#pragma mark - 动画循环播放
-(void) playLoop {
    DMDebug(@"playLoop");
    self.propertyAnimation.loopCount = NSUIntegerMax;
    [self startAnimating];
}

#pragma mark - 动画停止播放
-(void) stop {
    [self stopAnimating];
}

-(void) setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    if (hidden) {
        [self stop];
    } else {
        self.rate = 0;
    }
}

#pragma mark - 动画播放
- (void)startAnimating {
    [self.propertyAnimation start];
}

#pragma mark - 动画停止
- (void)stopAnimating {
    if (self->_propertyAnimation == nil) {
        return;
    }
    [self->_propertyAnimation stop];
    if(self->_propertyAnimation.callback) {
        self->_propertyAnimation.callback(1);
    }
}

@end
