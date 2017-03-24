//
//  DMBridgeRN.m
//  DMAppNavigator
//
//  Created by 杨涵 on 16/8/9.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridgeRN.h"
#import "RCTBridgeDelegate.h"
#import "RCTBridge+Private.h"


@interface DMBridgeRN() <RCTBridgeDelegate>
{
    BOOL hasListenners;
}

@end

@implementation DMBridgeRN

+ (instancetype) rnBridge{
    
    DMBridgeRN   * s_bridge = [[DMBridgeRN alloc] init];
    
    return s_bridge;
}

- (void)setSourceUrl:(NSURL *)sourceUrl {
    _sourceUrl = sourceUrl;
}

- (RCTBridge*) innerBridge{
    
    if(!_innerBridge){
        _innerBridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:nil];
    }
    return _innerBridge;
}

#pragma mark - RCTBridgeDelegate
- (NSURL*) sourceURLForBridge:(RCTBridge *)bridge{
    
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"index.ios" withExtension:@"jsbundle"];
    if (self.sourceUrl) {
        return self.sourceUrl;
    }
    return bundleURL;
}

@end
