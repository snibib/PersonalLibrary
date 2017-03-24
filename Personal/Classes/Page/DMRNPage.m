//
//  DMRNPage.m
//  DMAppNavigator
//
//  Created by chris on 16/7/11.
//  Copyright © 2016年 dmall. All rights reserved.
//

#import "DMRNPage.h"
#import "RCTRootView.h"
#import "DMBridgeRN.h"
#import "DMModuleGalleon.h"
#import "WTUpdateUtil.h"
#import "DMPage+DefaultNavigatorBar.h"

@interface DMRNPage ()

@property(nonatomic, strong)    RCTRootView         *rootView;

@property (nonatomic, strong)    DMBridgeRN          *rnBridge;
    
@end

@implementation DMRNPage

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadingComplete) name:RCTContentDidAppearNotification object:nil];
}

- (void)loadingComplete {
    self.rootView.hidden = NO;
}

- (RCTRootView*) rootView{
    
    if(!_rootView){
        _rootView = [[RCTRootView alloc] initWithBridge:self.rnBridge.innerBridge moduleName:[self moduleName] initialProperties:self.pageContext];
        _rootView.frame = self.view.bounds;
        _rootView.backgroundColor = [UIColor whiteColor];
//        _rootView.hidden = YES;
    }

    return _rootView;
}

- (void) pageWillForwardToMe{
    [super pageWillForwardToMe];
    
    [self.view addSubview:self.rootView];
}

- (DMBridgeRN *)rnBridge{
    
    if(!_rnBridge){
        _rnBridge = [DMBridgeRN rnBridge];
        
        NSString *path = [[WTUpdateUtil sharedInstance ] bundleCodePath:[self sourcePath]];
        if (path) {
            _rnBridge.sourceUrl =  [NSURL URLWithString:path];
        }
        else
        {
            _rnBridge.sourceUrl =  [self bundleUrl];
        }
    }
    return _rnBridge;
}

- (void)setShowDefaultNavigatorBar:(BOOL)showDefaultNavigatorBar {
    [super setShowDefaultNavigatorBar:showDefaultNavigatorBar];
    
    if (showDefaultNavigatorBar) {
        [self updateRootViewFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64)];
    }
}

- (void)updateRootViewFrame:(CGRect)frame{
    self.rootView.frame= frame;
}

- (NSString *)moduleName {
    NSArray *paths = [self.pageName componentsSeparatedByString:@"/"];
    return [paths lastObject];
}

- (NSString *)sourcePath {
    NSMutableArray *paths = [NSMutableArray arrayWithArray:[self.pageName componentsSeparatedByString:@"/"]];
    [paths removeLastObject];
    return [paths componentsJoinedByString:@"/"];
}

- (NSURL *)bundleUrl {
    NSString *sourceName = nil;
    NSString *bundleName = nil;
    NSString *subdirectory = nil;
    NSMutableArray *paths = [NSMutableArray arrayWithArray:[[self sourcePath] componentsSeparatedByString:@"/"]];
    if (paths.count == 1) {
        sourceName = [paths lastObject];
    }else if (paths.count >= 2) {
        bundleName = [paths firstObject];
        sourceName = [paths lastObject];
        [paths removeObjectAtIndex:0];
        [paths removeLastObject];
        subdirectory = [paths componentsJoinedByString:@"/"];
    }
    
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"index.ios" withExtension:@"jsbundle"];
    if (sourceName && sourceName.pathExtension && sourceName.pathExtension.length > 0) {
        NSString *name = [sourceName stringByReplacingOccurrencesOfString:[@"." stringByAppendingString:sourceName.pathExtension] withString:@""];
        NSBundle *bundle = [NSBundle mainBundle];
        
        if (bundleName) {
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
            bundle = [NSBundle bundleWithPath:bundlePath];
        }
        
        if (subdirectory) {
            bundleURL = [bundle URLForResource:name withExtension:sourceName.pathExtension subdirectory:subdirectory];
        }else {
            bundleURL = [bundle URLForResource:name withExtension:sourceName.pathExtension];
        }
        return bundleURL;
    }
#if TARGET_OS_SIMULATOR
    bundleURL = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios"];
#else
    
#ifdef DEBUG
        bundleURL = [NSURL URLWithString:@"http://192.168.8.61:8081/index.ios.bundle?platform=ios"];
#endif
    
#endif
    
    return bundleURL;
}

@end
