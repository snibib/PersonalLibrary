//
//  DMModuleGalleon.m
//  Galleon
//
//  Created by 杨涵 on 2017/3/14.
//  Copyright © 2017年 yanghan. All rights reserved.
//

#import "DMModuleGalleon.h"
#import "DMPage.h"
#import "DMRNPage.h"

#import "DMNavigator.h"
#import "DKStorage.h"
#import "DMBridgeRN.h"
#import "DMUrlEncoder.h"
#import "RCTBridgeModule.h"

@implementation DMModuleGalleon

RCT_EXPORT_MODULE(galleon);

- (NSArray<NSString *> *)supportedEvents {
    return @[@"galleon"];
}

- (void)sendEventMessage:(NSDictionary *)message {
    if (self.hasListener) {
        [self sendEventWithName:@"galleon" body:message];
    }
}

- (NSDictionary<NSString *,id> *)constantsToExport {
    return nil;
}

RCT_EXPORT_METHOD(reloadPage){
    DMRNPage *page1 = (DMRNPage *)[self.navigator topPage];
//    [page1.rnBridge.innerBridge reload];
}

RCT_EXPORT_METHOD(forward:(NSString*)url context:(NSDictionary *)context callback:(RCTResponseSenderBlock) callback){
    
    if (callback) {
        void (^nativeCallback)(NSDictionary*) = ^(NSDictionary *param){
            NSString* str = [DMUrlEncoder encodeParams:param];
            callback(@[[NSNull null],str]);
            
        };
        [self.navigator forward:url context:context callback:nativeCallback];
    }
    else {
        [self.navigator forward:url context:context callback:nil];
    }
    
}

RCT_EXPORT_METHOD(backward:(NSString *)param pageCount:(NSInteger)count context:(NSDictionary *)context){
    
    [self.navigator backward:param pageCount:count context:context];
}

RCT_EXPORT_METHOD(replace:(NSString*)url context:(NSDictionary*)context callback:(RCTResponseSenderBlock)callback) {
    if (callback) {
        void (^nativeCallback)(NSDictionary*) = ^(NSDictionary *param){
            NSString* str = [DMUrlEncoder encodeParams:param];
            callback(@[[NSNull null],str]);
            
        };
        [self.navigator replace:url context:context callback:nativeCallback];
    }
    else {
        [self.navigator replace:url context:context callback:nil];
    }
}

RCT_EXPORT_METHOD(replaceState:(NSString*)path) {
    DMPage *currentPage = [[DMNavigator getInstance] topPage];
    currentPage.replaceStateUrl = path;
}

RCT_EXPORT_METHOD(callback:(NSString*)param){
    
    [self.navigator callback:param];
}

RCT_EXPORT_METHOD(pushFlow){
    
    [self.navigator pushFlow];
}

RCT_EXPORT_METHOD(popFlow:(NSString*)param context:(NSDictionary *)context){
    
    [self.navigator popFlow:param context:context];
}

RCT_EXPORT_METHOD(set:(id)json forKey:(NSString *)key) {
    NSData *data = nil;
    
    if ([json isKindOfClass:[NSData class]]) {
        data = json;
    }else {
        data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONReadingAllowFragments error:nil];
    }
    [self.storage set:data forKey:key];
}

RCT_EXPORT_METHOD(get:(NSString *)key callback:(RCTResponseSenderBlock)callback) {
    if (callback) {
        NSData *data = [self.storage get:key];
        if (data) {
            id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            callback(@[[NSNull null],object]);
        }
        else {
            callback(@[[NSNull null],[NSNull null]]);
        }
    }
}

RCT_EXPORT_METHOD(remove:(NSString *)key) {
    [self.storage remove:key];
}

RCT_EXPORT_METHOD(setContext:(NSDictionary *)context) {
    DMPage *currentPage = [[DMNavigator getInstance] topPage];
    currentPage.pageContext = context;
}

RCT_EXPORT_METHOD(getContext:(RCTResponseSenderBlock)callback) {
    DMPage *currentPage = [[DMNavigator getInstance] topPage];
    if (callback) {
        if (currentPage.pageContext) {
            callback(@[[NSNull null],currentPage.pageContext]);
        }else {
            callback(@[[NSNull null],[NSNull null]]);
        }
    }
}

@end
