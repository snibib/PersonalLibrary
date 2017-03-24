//
//  DMWebPage.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMWebPage.h"
#import "DKStorage.h"
#import "DMJSPageBridge.h"
#import "DMBridgeJavascript.h"
#import "DMBridgeHelper.h"
#import "DMEvaluateScript.h"
#import "DMPage+DefaultNavigatorBar.h"

@interface DMWebPage () <UIWebViewDelegate, DMEvaluateScript>

@property (nonatomic, strong)   DMJSPageBridge        *jsPageBridge;

@end

@implementation DMWebPage

- (void)pageReload {
    NSString *currentUrl = self.pageUrl; 
    NSInteger currentPos = self.pagePos;
    NSString *preUrl = self.prePageUrl;
    NSInteger prePos = self.prePos;
    
    NSString *jsCode = [NSString stringWithFormat:@"galleon.Navigator.currentUrl='%@';",currentUrl];
    jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.prevUrl='%@';",preUrl];
    jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.currentPos=%ld;",(long)currentPos];
    jsCode = [jsCode stringByAppendingFormat:@"galleon.Navigator.prevPos=%ld;",(long)prePos];
    
//    //测试阶段用，后期h5自动覆盖reload
//    jsCode = [jsCode stringByAppendingFormat:@"window.kayak?window.kayak.router.refresh():window.location.reload();"];
    
    jsCode = [NSString stringWithFormat:@"galleon.anchor.reload ? galleon.anchor.reload():window.location.reload();"];
    //避免在执行的时候线程卡顿
    dispatch_async(dispatch_get_main_queue(), ^{
        [self evaluateScript:jsCode];
    });
}

- (void)anchorBack {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }else {
        [self.navigator backward];
    }
}

- (NSString *)evaluateScript:(NSString *)script {
    return [self.webView stringByEvaluatingJavaScriptFromString:script];
}

- (void)setShowDefaultNavigatorBar:(BOOL)showDefaultNavigatorBar {
    [super setShowDefaultNavigatorBar:showDefaultNavigatorBar];
    
    if (showDefaultNavigatorBar) {
        [self updateWebViewFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64)];
    }
}

- (void)updateWebViewFrame:(CGRect)frame{
    self.webView.frame= frame;
}

-(void) loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    [[DMBridgeHelper getInstance] registBridge:self.jsPageBridge];
}

-(void) pageWillForwardToMe {
    [super pageWillForwardToMe];
    
    if (self.showDefaultNavigatorBar) {
        NSString *defaultTitle = self.title ? self.title : self.pageName;
        [self setDefaultTitle:defaultTitle];
        
        self.webView.frame = CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-64);
    }
    NSString* pageUrl = [self.pageUrl stringByRemovingPercentEncoding];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pageUrl] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    [self.webView loadRequest:request];
}

- (void)pageDidShown {
    [super pageDidShown];
    
    [[DMBridgeHelper getInstance] bindWebView:self.webView];
}

-(void) pageDestroy {
    [super pageDestroy];
    [self.webView stopLoading];
    self.webView = nil;
}

- (DMJSPageBridge *)jsPageBridge {
    if (_jsPageBridge == nil) {
        _jsPageBridge = [[DMJSPageBridge alloc] init];
        _jsPageBridge.jsPage = self.webView;
        _jsPageBridge.navigator = self.navigator;
    }
    return _jsPageBridge;
}

-(UIWebView*) webView {
    if (self->_webView == nil) {
        self->_webView = [[UIWebView alloc] init];
        self->_webView.frame = [UIScreen mainScreen].bounds;
        [self->_webView.scrollView setBounces:NO];
        self->_webView.backgroundColor = [UIColor whiteColor];
    }
    return self->_webView;
}

@end
