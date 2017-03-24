//
//  DMMutiProxy.m
//  DMTools
//
//  Created by chenxinxin on 15/10/23.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMMutiProxy.h"

@implementation DMMutiProxy

-(NSMutableArray*) proxies {
    if(self->_proxies == nil) {
        self->_proxies = [[NSMutableArray alloc] init];
    }
    return self->_proxies;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig;
    for (id proxy in self.proxies) {
        __weak id obj = nil;
        if ([proxy isKindOfClass:[NSValue class]]) {
            obj = [(NSValue*)proxy nonretainedObjectValue];
        } else {
            obj = proxy;
        }
        sig = [obj methodSignatureForSelector:aSelector];
        if (sig) return sig;
    }
    return nil;
}

// Invoke the invocation on whichever real object had a signature for it.
- (void)forwardInvocation:(NSInvocation *)invocation {
    for (id proxy in self.proxies) {
        __weak id obj = nil;
        if ([proxy isKindOfClass:[NSValue class]]) {
            obj = [(NSValue*)proxy nonretainedObjectValue];
        } else {
            obj = proxy;
        }
        if ([obj respondsToSelector:invocation.selector]) {
            [invocation invokeWithTarget:obj];
        }
    }
}

// Override some of NSProxy's implementations to forward them...
- (BOOL)respondsToSelector:(SEL)aSelector {
    for (id proxy in self.proxies) {
        __weak id obj = nil;
        if ([proxy isKindOfClass:[NSValue class]]) {
            obj = [(NSValue*)proxy nonretainedObjectValue];
        } else {
            obj = proxy;
        }
        if ([obj respondsToSelector:aSelector]) return YES;
    }
    return NO;
}

-(void) addProxy : (id) proxy {
    if (proxy) {
        [self.proxies addObject:proxy];
    }
}

-(void) addWeakProxy : (id) proxy {
    if (proxy == nil) {
        return;
    }
    [self.proxies addObject:[NSValue valueWithNonretainedObject:proxy]];
}
@end
