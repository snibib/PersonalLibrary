//
//  ViewController.m
//  PersonalLibraryDemo
//
//  Created by 杨涵 on 16/8/11.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "ViewController.h"
#import "DMBridge.h"

@interface ViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) DMBridge   *bridge;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:webView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TestWebPage" ofType:@"html"];
    NSURL *url = [NSURL URLWithString:path];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    self.bridge = [DMBridge bridgeForWebView:webView];
    [self.bridge setWebViewDelegate:self];
    [self.bridge registerHandler:@"testApp" handler:^(id data, ResponseCallback responseCallback) {
        if (responseCallback) {
            responseCallback(@"response from oc");
        }
    }];
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
