//
//  DMBridgeHelper.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridgeHelper.h"
#import "DMUrlConcat.h"
#import "DKStorage.h"
#import "DMWeakify.h"
#import "DMBridgeJavascript.h"
#import "DMLog.h"
#import "DMStringUtils.h"
#import "DMUrlEncoder.h"
#import <objc/runtime.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "WTUpdateUtil.h"
#import "DMNavigator.h"
#import "DMPage.h"
#import "DMWebPage.h"

#define DECK_BRIDGE             @"galleon.dmall.com/bridge/bridge_load"
#define DECK_PATH               @"galleon.dmall.com/bridge/navigator"
#define DECK_STORAGE            @"galleon.dmall.com/bridge/storage"

static NSString * kRequestFlagProperty = @"com.deck.webbridgehelper";

@interface DMBridgeHolder : NSObject

@property (nonatomic, strong) id <DMBridgeProtocol>           bridgeObject;
@property (nonatomic, strong) NSMutableDictionary            *methodMap;

/*!
 * 执行和js方法对应的本地方法
 */
- (NSString *)invokeFromJavascript:(NSString *)jsMethodName withParam:(NSArray *)param;

- (NSString *)getBridgeScript;
/*!
 * 向webView中注入js
 */
- (void)registerBridgeScripts:(UIWebView *)webView;

/*!
 * 注入的js对象名
 */
- (NSString *)key;

@end

@interface DMBridgeHelper()

@property (nonatomic, strong) NSMutableDictionary *bridgeMap;
@property (nonatomic, strong) NSArray             *trustUrls;
@property (nonatomic, strong) NSDictionary        *nativeHostMap;

@end

typedef void (^ResponseCallback)(id responseData);

@implementation DMBridgeHelper

#pragma mark - Publick method
+ (DMBridgeHelper *)getInstance {
    static DMBridgeHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DMBridgeHelper alloc] init];
    });
    return instance;
}

- (void)registBridge:(id<DMBridgeProtocol>)bridgeObject {
    DMBridgeHolder *holder = [[DMBridgeHolder alloc] init];
    holder.bridgeObject = bridgeObject;
    
    //如果js对象名一样，会导致之前的对象被复写
    //同一个js对象最好还是同一个人负责编写，额外功能就继承
    [self.bridgeMap setObject:holder forKey:[holder key]];
}

- (void)bindWebView:(UIWebView *)webView {
    NSDictionary *bridgeMap = [self bridgeMap];
    for (id key in bridgeMap) {
        DMBridgeHolder *holder = [bridgeMap objectForKey:key];
        if (webView != nil) {
            [holder registerBridgeScripts:webView];
        }
    }
}

- (void)registBridge:(id<DMBridgeProtocol>)bridgeObject forWebView:(UIWebView *)webView {
    DMBridgeHolder *holder = [[DMBridgeHolder alloc] init];
    holder.bridgeObject = bridgeObject;
    
    //如果js对象名一样，会导致之前的对象被复写
    [self.bridgeMap setObject:holder forKey:[holder key]];
    [holder registerBridgeScripts:webView];
}

#pragma mark - Private method
+ (void)initialize {
    [NSURLProtocol registerClass:self];
}

- (void)setNativeSourceHosts:(NSDictionary *)hostMap {
    self->_nativeHostMap = hostMap;
}

- (void)setAccessControlOrigin:(NSArray *)urls {
    self->_trustUrls = urls;
}

- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        
    }
    return self;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSURL *url;
    BOOL shouldAccept = (request != nil);
    
    if (shouldAccept) {
        url = [request URL];
        shouldAccept = (url != nil);
    }
    
    if (shouldAccept) {
        shouldAccept = ([NSURLProtocol propertyForKey:kRequestFlagProperty inRequest:request] == nil);
    }

    if (shouldAccept) {
        shouldAccept = [self isDeckBridgeLoad:url] ||
        [self isDeckQueueMessage:url] ||
        [self isDeckStorageMessage:url] ||
        ([self isNativeSource:url] && [self isNativeSourceExist:url]) ||
        [self isDMAppFrameworkMessage:url];
    }
    
    return shouldAccept;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSURL *url = self.request.URL;
    NSData *data = nil;//[@"[[nil]]" dataUsingEncoding:NSUTF8StringEncoding];
    
    if (url == nil) {
        return;
    }
    
    [NSURLProtocol setProperty:@YES forKey:kRequestFlagProperty inRequest:[[self request] mutableCopy]];
    if ([DMBridgeHelper isDMAppFrameworkMessage:url]) {
        NSError* error;
        NSString *jsonStr = [[NSString alloc] initWithData:self.request.HTTPBody encoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[[DMUrlEncoder unescape:jsonStr] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
        if (dic != nil) {
            NSString *obj              = [dic objectForKey:@"obj"];
            NSString *jsMethodName     = [dic objectForKey:@"method"];
            NSArray  *param            = [dic objectForKey:@"param"];
            
            DMBridgeHolder* bridgeHolder = [[[DMBridgeHelper getInstance] bridgeMap] objectForKey:obj];
            if (bridgeHolder) {
                NSString *responseStr = [bridgeHolder invokeFromJavascript:jsMethodName withParam:param];
                if (responseStr != nil) {
                    data = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
                }
            }
        }
    }
    
    else if ([DMBridgeHelper isDeckQueueMessage:url]) {
        NSData *requestData = self.request.HTTPBody;
        NSDictionary *message = nil;
        if (requestData) {
            message = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingAllowFragments error:nil];
        }
        
        if ([NSThread isMainThread]) {
            [[DMBridgeHelper getInstance] _dispatchFromMessage:message];
        }else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[DMBridgeHelper getInstance] _dispatchFromMessage:message];
            });
        }
    }
    
    else if ([DMBridgeHelper isDeckBridgeLoad:url]) {
        NSString *jsCode = DMBridgeJavascript();
        DMPage *currentPage = [DMNavigator getInstance].topPage;
        NSString *currentUrl = currentPage.pageUrl;
        NSInteger currentPos = currentPage.pagePos;
        NSString *preUrl = currentPage.prePageUrl;
        NSInteger prePos = currentPage.prePos;
        
        jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.currentUrl='%@';",currentUrl];
        jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.prevUrl='%@';",preUrl];
        jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.currentPos=%ld;",(long)currentPos];
        jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.prevPos=%ld;",(long)prePos];
        
        //        NSDictionary *bridgeMap = [[DMBridgeHelper sharedInstance] bridgeMap];
        //        NSMutableString *jsString = [NSMutableString new];
        //        for (id key in bridgeMap) {
        //            DMBridgeHolder *holder = [bridgeMap objectForKey:key];
        //            [jsString appendString:[holder getBridgeScript]];
        //        }
        //        jsCode = jsString;
        
        data = [jsCode dataUsingEncoding:NSUTF8StringEncoding];
    }
    //STORAGE METHOD
    else if ([DMBridgeHelper isDeckStorageMessage:url]) {
        NSData *requestData = self.request.HTTPBody;
        NSDictionary *message = nil;
        if (requestData) {
            message = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingAllowFragments error:nil];
            
            NSString *method = message[@"handlerName"];
            NSDictionary *messageData = message[@"data"];
            NSString *keyName = messageData[@"keyName"];
            
            if ([method isEqualToString:@"galleon.storage.set"]) {
                if (messageData[@"valueData"] && keyName) {
                    NSData *valueData = [NSJSONSerialization dataWithJSONObject:messageData[@"valueData"] options:NSJSONReadingAllowFragments error:nil];
                    [[DKStorage getInstance] set:valueData forKey:keyName];
                }
            }else if ([method isEqualToString:@"galleon.storage.get"] && keyName) {
                data = [[DKStorage getInstance] get:keyName];
            }else if ([method isEqualToString:@"galleon.storage.remove"] && keyName) {
                [[DKStorage getInstance] remove:keyName];
            }else if ([method isEqualToString:@"galleon.storage.setContext"]) {
                DMPage *currentPage = [DMNavigator getInstance].topPage;
                currentPage.pageContext = messageData[@"valueData"];
            }else if ([method isEqualToString:@"galleon.storage.getContext"]) {
                DMPage *currentPage = [[DMNavigator getInstance] topPage];
                if (currentPage.pageContext) {
                    NSData *valueData = [NSJSONSerialization dataWithJSONObject:currentPage.pageContext options:NSJSONReadingAllowFragments error:nil];
                    data = valueData;
                }
            }

        }
    }
    
    //NATIVE SOURCE
    else if ([DMBridgeHelper isNativeSource:url]) {
        //对访问本地资源的域名进行处理，返回本地数据
        
        NSArray *files = [DMUrlConcat concatUrl:url];
        NSMutableData *fileData = [[NSMutableData alloc] init];
        
        for (NSString *filePath in files) {
            NSString *fileFullPath  =  [[WTUpdateUtil sharedInstance ]h5ResponsePath:filePath];
            
            //            NSString *jsstr = [[NSString alloc] initWithContentsOfFile:fileFullPath encoding:NSUTF8StringEncoding error:nil];
            
            NSData *detailData = [NSData dataWithContentsOfFile:fileFullPath];
            
            if (detailData == nil) {
                continue;
            }
            
            [fileData appendData:detailData];
        }
        data = fileData;
    }
    
    NSMutableDictionary *headerFields = [self.request.allHTTPHeaderFields mutableCopy];
    [headerFields setValue:@"POST,GET" forKey:@"Access-Control-Allow-Methods"];
    
    if ([DMBridgeHelper getInstance].trustUrls && [DMBridgeHelper getInstance].trustUrls.count > 0) {
        NSString *host = [url.host lowercaseString];
        for (NSString *string in [DMBridgeHelper getInstance].trustUrls) {
            if ([[string lowercaseString] containsString:host]) {
                NSString *trustUrl = [url.scheme stringByAppendingFormat:@"://%@",url.host];
                [headerFields setValue:trustUrl forKey:@"Access-Control-Allow-Origin"];
            }else {
                [headerFields setValue:@"*" forKey:@"Access-Control-Allow-Origin"];
            }
        }
    }else {
        [headerFields setValue:@"*" forKey:@"Access-Control-Allow-Origin"];
    }

    [headerFields setValue:@"true" forKey:@"Access-Control-Allow-Credentials"];
    
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"http/1.1" headerFields:headerFields];
    
    //    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url MIMEType:@"text/plain" expectedContentLength:data.length textEncodingName:@"UTF-8"];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)_dispatchFromMessage:(NSDictionary *)message {
    if (message == nil) {
        return;
    }

    NSString *methodName = message[@"handlerName"];
    NSDictionary *data = message[@"data"];
    if ([methodName isEqualToString:@"galleon.navigator.forward"]) {
        NSDictionary *context = data[@"context"] == [NSNull null] ? nil:data[@"context"];
        [[DMNavigator getInstance] forward:data[@"url"] context:context];
    }
    else if ([methodName isEqualToString:@"galleon.navigator.backward"]) {
        NSString *param = data[@"param"] == [NSNull null] ? nil : data[@"param"];
        NSDictionary *context = data[@"context"] == [NSNull null] ? nil:data[@"context"];
        [[DMNavigator getInstance] backward:param pageCount:[data[@"backCount"] integerValue] context:context];
    }
    else if ([methodName isEqualToString:@"galleon.navigator.replace"]) {
        NSDictionary *context = data[@"context"] == [NSNull null] ? nil:data[@"context"];
        [[DMNavigator getInstance] replace:data[@"url"] context:context];
    }
    else if ([methodName isEqualToString:@"galleon.navigator.pushFlow"]) {
        [[DMNavigator getInstance] pushFlow];
    }
    else if ([methodName isEqualToString:@"galleon.navigator.popFlow"]) {
        NSString *param = data[@"param"] == [NSNull null] ? nil : data[@"param"];
        NSDictionary *context = data[@"context"] == [NSNull null] ? nil:data[@"context"];
        [[DMNavigator getInstance] popFlow:param context:context];
    }
    else if ([methodName isEqualToString:@"galleon.navigator.replaceState"]) {
        DMPage *currentPage = [[DMNavigator getInstance] topPage];
        currentPage.replaceStateUrl = data[@"url"];
    }
    else if ([methodName isEqualToString:@"galleon.anchor.back"]) {
        DMPage *currentPage = [[DMNavigator getInstance] topPage];
        if (currentPage && [currentPage respondsToSelector:@selector(anchorBack)]) {
            [currentPage anchorBack];
        }
    }
}

- (void)stopLoading {
    [NSURLProtocol removePropertyForKey:kRequestFlagProperty inRequest:[[self request] mutableCopy]];
}

+ (BOOL)isDeckBridgeLoad:(NSURL *)url {
    return [[url.absoluteString lowercaseString] containsString:DECK_BRIDGE];
}

+ (BOOL)isDeckQueueMessage:(NSURL *)url {
    return [[url.absoluteString lowercaseString] containsString:DECK_PATH];
}

+ (BOOL)isDeckStorageMessage:(NSURL *)url {
    return [[url.absoluteString lowercaseString] containsString:DECK_STORAGE];
}

+ (BOOL)isDMAppFrameworkMessage:(NSURL *)url {
    if (url == nil) {
        return NO;
    }
    return ([url.absoluteString rangeOfString:@"/!lightapp/"].location != NSNotFound);
}

+ (BOOL)isNativeSource:(NSURL *)url {
    NSDictionary *hostMap = [self getInstance].nativeHostMap;
    if (hostMap) {
        return [[hostMap allKeys] containsObject:[url.host lowercaseString]] || [[hostMap allKeys] containsObject:url.host];
    }else {
        return false;
    }
}

+ (BOOL)isNativeSourceExist:(NSURL *)url {
    NSArray *files = [DMUrlConcat concatUrl:url];
    
    for (NSString *filePath in files) {
        NSString *folder = [[self getInstance].nativeHostMap objectForKey:url.host];
        if (folder == nil) {
            folder = [[self getInstance].nativeHostMap objectForKey:[url.host lowercaseString]];
        }
        NSString *fileFullPath  =  [[WTUpdateUtil sharedInstance ]  h5ResponsePath:filePath folder:folder];
        
        BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:fileFullPath];
        
        if (fileExist == false) {
            return false;
        }
    }
    return YES;
}

- (NSMutableDictionary *)bridgeMap {
    if (_bridgeMap == nil) {
        _bridgeMap = [NSMutableDictionary new];
    }
    return  _bridgeMap;
}

@end

union ArgDef {
    char charValue;
    unsigned char unsignedChar;
    short shortValue;
    unsigned short unsignedShortValue;
    long longValue;
    unsigned long unsignedLongValue;
    int intValue;
    unsigned int unsignedIntValue;
    float floatValue;
    double doubleValue;
    BOOL boolValue;
    long long longLongValue;
    unsigned long long unsignedLongLongValue;
};

@implementation DMBridgeHolder

- (NSString *)getBridgeScript {
    NSMutableString *jsCode = [NSMutableString new];
    [jsCode appendString:@"(function(){"];
    
    [jsCode appendString:@"\n\
     function EncodeUtf8(s1)\n\
     {\n\
     if(s1==null){return "";}\n\
     var s = escape(s1);\n\
     var sa = s.split(\"%\");\n\
     var retV =\"\";\n\
     if(sa[0] != \"\")\n\
     {\n\
     retV = sa[0];\n\
     }\n\
     for(var i = 1; i < sa.length; i ++)\n\
     {\n\
     if(sa[i].substring(0,1) == \"u\")\n\
     {\n\
     retV += Hex2Utf8(Str2Hex(sa[i].substring(1,5)));\n\
     if(sa[i].length>=6)\n\
     {\n\
     retV += sa[i].substring(5);\n\
     }\n\
     }\n\
     else retV += \"%\" + sa[i];\n\
     }\n\
     return retV;\n\
     }\n\
     function Str2Hex(s)\n\
     {\n\
     var c = \"\";\n\
     var n;\n\
     var ss = \"0123456789ABCDEF\";\n\
     var digS = \"\";\n\
     for(var i = 0; i < s.length; i ++)\n\
     {\n\
     c = s.charAt(i);\n\
     n = ss.indexOf(c);\n\
     digS += Dec2Dig(eval(n));\n\
     }\n\
     return digS;\n\
     }\n\
     function Dec2Dig(n1)\n\
     {\n\
     var s = \"\";\n\
     var n2 = 0;\n\
     for(var i = 0; i < 4; i++)\n\
     {\n\
     n2 = Math.pow(2,3 - i);\n\
     if(n1 >= n2)\n\
     {\n\
     s += '1';\n\
     n1 = n1 - n2;\n\
     }\n\
     else\n\
     s += '0';\n\
     }\n\
     return s;\n\
     }\n\
     function Dig2Dec(s)\n\
     {\n\
     var retV = 0;\n\
     if(s.length == 4)\n\
     {\n\
     for(var i = 0; i < 4; i ++)\n\
     {\n\
     retV += eval(s.charAt(i)) * Math.pow(2, 3 - i);\n\
     }\n\
     return retV;\n\
     }\n\
     return -1;\n\
     }\n\
     function Hex2Utf8(s)\n\
     {\n\
     var retS = \"\";\n\
     var tempS = \"\";\n\
     var ss = \"\";\n\
     if(s.length == 16)\n\
     {\n\
     tempS = \"1110\" + s.substring(0, 4);\n\
     tempS += \"10\" +  s.substring(4, 10);\n\
     tempS += \"10\" + s.substring(10,16);\n\
     var sss = \"0123456789ABCDEF\";\n\
     for(var i = 0; i < 3; i ++)\n\
     {\n\
     retS += \"%\";\n\
     ss = tempS.substring(i * 8, (eval(i)+1)*8);\n\
     retS += sss.charAt(Dig2Dec(ss.substring(0,4)));\n\
     retS += sss.charAt(Dig2Dec(ss.substring(4,8)));\n\
     }\n\
     return retS;\n\
     }\n\
     return \"\";\n\
     }\n\
     function EncodeParam(p){\n\
     if(p==null){\n\
     return "";\n\
     }\n\
     return escape(EncodeUtf8(p));\n\
     }\n\
     "];
    
    for (NSUInteger i=0; i<[self key].length; ) {
        NSRange range = [self.key rangeOfString:@"." options:NSLiteralSearch range:NSMakeRange(i, self.key.length-i)];
        if(range.location == NSNotFound) {
            break;
        }
        NSString* path = [self.key substringToIndex:range.location];
        [jsCode appendFormat:@"if(typeof(%@)=='undefined'){\n%@={};\n};",path,path];
        i = range.location + 1;
        if(i>self.key.length-1){
            break;
        }
    }
    [jsCode appendString:@"\n"];
    [jsCode appendString:[self key]];
    [jsCode appendString:@"={\n"];
    __block BOOL first = YES;
    @weakify_self
    @weakify(jsCode)
    [self walkBridgeSelector:self.bridgeObject callback:^(SEL selector) {
        @strongify_self
        @strongify(jsCode)
        int argCount = [self argsCountForSelector:selector];
        
        if (first) {
            first = NO;
        } else {
            [strong_jsCode appendString:@",\n"];
        }
        NSMethodSignature* methodSign = [[self.bridgeObject class] instanceMethodSignatureForSelector:selector];
        const char* methodRetType = [methodSign methodReturnType];
        NSString* methodName = [self javascriptMethodNameForSelector:selector];
        [strong_jsCode appendFormat:@"%@:function(",methodName];
        for(int j = 0 ; j < argCount ; j++) {
            [strong_jsCode appendFormat:@"arg%d",j];
            if(j < argCount-1) {
                [strong_jsCode appendString:@","];
            }
        }
        [strong_jsCode appendString:@"){\n"];
        [strong_jsCode appendString:@"var request = new XMLHttpRequest();\n"];
        [strong_jsCode appendFormat:@"var arg = \"{\\\"obj\\\":\\\"%@\\\",\\\"method\\\": \\\"%@\\\",\\\"param\\\":[",self.key,methodName];
        for(int j = 0 ; j < argCount ; j++) {
            
            [strong_jsCode appendFormat:@"\\\"\"+EncodeParam(arg%d)+\"\\\"",j];
            if(j < argCount-1) {
                [strong_jsCode appendString:@","];
            }
        }
        [strong_jsCode appendFormat:@"]}\";\n"];
        [strong_jsCode appendString:@"request.open('POST', 'http://galleon.dmall.com/bridge/!lightapp/', false);\n"];
        [strong_jsCode appendString:@"request.setRequestHeader('content-type\','application/x-www-form-urlencoded');\n"];
        [strong_jsCode appendFormat:@"request.send(arg);\n"];
        if (strcmp(methodRetType, "@") == 0) {
            [strong_jsCode appendString:@"return \"[[nil]]\"==request.responseText?null:request.responseText;\n"];
        }
        else if(strcmp(methodRetType,"v") != 0){
            [strong_jsCode appendString:@"return Number(request.responseText);\n"];
        }
        [strong_jsCode appendString:@"}\n"];
    }];
    
    [jsCode appendString:@"};\n"];
    [jsCode appendString:@"})();\n"];
    return jsCode;
}

- (void)registerBridgeScripts:(UIWebView *)webView {
    NSString *jsCode = [self getBridgeScript];
    [webView stringByEvaluatingJavaScriptFromString:jsCode];
}

- (void)walkBridgeSelector:(id <DMBridgeProtocol>)bridgeObject callback:(void (^)(SEL selector))walker {
    for (Class superClass = [bridgeObject class]; superClass && superClass != [NSObject class]; superClass = [superClass superclass]) {
        unsigned int protocolCount = 0;
        Protocol *__unsafe_unretained * protocols = class_copyProtocolList(superClass, &protocolCount);
        for (int i=0; i<protocolCount; i++) {
            Protocol *protocol = protocols[i];
            
            if (!protocol_conformsToProtocol(protocol, @protocol(JSExport))) {
                continue;
            }
            unsigned int methodCount = 0;
            struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, YES, YES, &methodCount);
            for (int j=0; j<methodCount; j++) {
                SEL sel = methods[j].name;
                walker(sel);
            }
            free(methods);
        }
        free(protocols);
    }
}

- (NSString *)invokeFromJavascript:(NSString *)jsMethodName withParam:(NSArray *)param {
    SEL selector = [self methodFromName:jsMethodName];
    NSMethodSignature *methodSignature = [[self.bridgeObject class] instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    
    NSMutableArray *buffer = [NSMutableArray new];
    unsigned long argCount = methodSignature.numberOfArguments - 2;
    for (int i=0; i<argCount; i++) {
        unsigned int index = i + 2;
        const char *argType = [methodSignature getArgumentTypeAtIndex:index];
        NSString *argValue = [param[i] stringByRemovingPercentEncoding];
        if (!argValue) {
            continue;
        }
        if (strcmp(argType, "@") == 0) {
            NSString *arg = argValue;
            [invocation setArgument:&arg atIndex:index];
            [buffer addObject:arg];
        }else {
            [buffer addObject:argValue];
            union ArgDef arg = [self convertBasicArg:argValue with:argType];
            [invocation setArgument:&arg atIndex:index];
        }
    }
    
    [invocation invokeWithTarget:self.bridgeObject];
    const char *methodReturnType = [methodSignature methodReturnType];
    if (strcmp(methodReturnType, "@") == 0) {
        void *retObject;
        [invocation getReturnValue:&retObject];
        NSString *ret = (__bridge NSString *)retObject;
        return ret;
    }else if(strcmp(methodReturnType, "v") != 0) {
        union ArgDef value;
        [invocation getReturnValue:&value];
        return [self argDefToString:value with:methodReturnType];
    }
    return @"";
}

- (SEL)methodFromName:(NSString *)jsMethodName {
    NSString *selectorName = [self.methodMap objectForKey:jsMethodName];
    return NSSelectorFromString(selectorName);
}

- (int)argsCountForSelector:(SEL)selector {
    NSMethodSignature *methodSign = [[self.bridgeObject class] instanceMethodSignatureForSelector:selector];
    return (int)(methodSign.numberOfArguments - 2);
}

- (NSString *)javascriptMethodNameForSelector:(SEL)selector {
    NSString *selectorName = NSStringFromSelector(selector);
    NSMutableString *buffer = [[NSMutableString alloc] init];
    NSArray *elements = [selectorName componentsSeparatedByString:@":"];
    
    for (int i=0; i<elements.count; i++) {
        NSString *element = elements[i];
        if (i==0) {
            [buffer appendString:element];
        }else {
            [buffer appendString:[DMStringUtils firstToUpper:element]];
        }
    }
    
    [self.methodMap setObject:selectorName forKey:buffer];
    
    return buffer;
}

- (union ArgDef)convertBasicArg:(NSString*)value with:(const char*) type {
    union ArgDef ret;
    if (strcmp(type, "c") == 0) {
        ret.charValue = [value characterAtIndex:0];
        if ([@"true" isEqualToString:value] || [@"false" isEqualToString:value]) {
            ret.boolValue = [value boolValue];
        }
        return ret;
    }
    if (strcmp(type, "i") == 0) {
        ret.intValue = [value intValue];
        return ret;
    }
    if (strcmp(type, "I") == 0) {
        ret.unsignedIntValue = (unsigned int)[value intValue];
        return ret;
    }
    if (strcmp(type, "s") == 0) {
        ret.shortValue = [value intValue];
        return ret;
    }
    if (strcmp(type, "S") == 0) {
        ret.unsignedShortValue = [value intValue];
        return ret;
    }
    if (strcmp(type, "l") == 0) {
        ret.longValue = [value longLongValue];
        return ret;
    }
    if (strcmp(type, "L") == 0) {
        ret.unsignedLongLongValue = [value longLongValue];
        return ret;
    }
    if (strcmp(type, "f") == 0) {
        ret.floatValue = [value floatValue];
        return ret;
    }
    if (strcmp(type, "d") == 0) {
        ret.doubleValue = [value doubleValue];
        return ret;
    }
    if (strcmp(type, "B") == 0) {
        ret.boolValue = [value boolValue];
        return ret;
    }
    if (strcmp(type, "q") == 0) {
        ret.longLongValue = [value longLongValue];
        return ret;
    }
    return ret;
}

- (NSString *)argDefToString:(union ArgDef)arg with:(const char*)type {
    if (strcmp(type, "c") == 0) {
        return [NSString stringWithFormat:@"%c",arg.charValue];
    }
    if (strcmp(type, "i") == 0) {
        return [NSString stringWithFormat:@"%d",arg.intValue];
    }
    if (strcmp(type, "I") == 0) {
        return [NSString stringWithFormat:@"%u",arg.unsignedIntValue];
    }
    if (strcmp(type, "s") == 0) {
        return [NSString stringWithFormat:@"%d",arg.shortValue];
    }
    if (strcmp(type, "S") == 0) {
        return [NSString stringWithFormat:@"%u",arg.unsignedShortValue];
    }
    if (strcmp(type, "l") == 0) {
        return [NSString stringWithFormat:@"%ld",arg.longValue];
    }
    if (strcmp(type, "L") == 0) {
        return [NSString stringWithFormat:@"%lu",arg.unsignedLongValue];
    }
    if (strcmp(type, "f") == 0) {
        return [NSString stringWithFormat:@"%f",arg.floatValue];
    }
    if (strcmp(type, "d") == 0) {
        return [NSString stringWithFormat:@"%f",arg.doubleValue];
    }
    if (strcmp(type, "B") == 0) {
        return [NSString stringWithFormat:@"%d",arg.boolValue];
    }
    if (strcmp(type, "q") == 0) {
        return [NSString stringWithFormat:@"%lld",arg.longLongValue];
    }
    if (strcmp(type, "Q") == 0) {
        return [NSString stringWithFormat:@"%llu",arg.unsignedLongLongValue];
    }
    return @"";
}

- (NSMutableDictionary *)methodMap {
    if (_methodMap == nil) {
        _methodMap = [NSMutableDictionary new];
    }
    return _methodMap;
}

- (NSString *)key {
    return [self.bridgeObject javascriptObjectName];
}

@end
