//
//  DMNavigator.h
//  DMAppFramework
//
//  Created by chenxinxin on 15/10/27.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DMPage;
@class DMNavigator;

@protocol DMNavigatorDelegate <NSObject>

@optional
-(void) navigator:(DMNavigator*)navigator willChangePageTo:(NSString*) url;
-(void) navigator:(DMNavigator *)navigator didChangedPageTo:(NSString *) url;
-(BOOL) navigator:(DMNavigator *)navigator shouldCachePage:(NSString *) url;
-(BOOL) navigator:(DMNavigator *)navigator shouldForwardTo:(NSString*) url;
-(Class) navigator:(DMNavigator *)navigator shouldOverridePageClass:(NSString*) url;
-(void) initPageArguments:(DMPage *)from toPage:(DMPage *)to;

@end


/*!
 *  DMNavigator负责管理页面及其导航跳转
 *  这些页面包括h5页面，本地开发的页面等等
 *  页面地址及参数通过统一资源定位符设置。
 *  例如:
 *  (1) 本地页面链接举例:
 *      "app://ProductDetail?id=1212"
 *      带有动画参数的url:
 *      "app://ProductDetail?id=1222&@animate=pushLeft"
 */
@interface DMNavigator : UIViewController

@property (weak,nonatomic) id<DMNavigatorDelegate> delegate;

/*!
 * 是否支持右滑返回，默认支持
 */
@property (assign,nonatomic) BOOL  isSlideBack;
/*!
 * 是否支持右滑返回，添加阴影效果，默认添加
 */
@property (assign,nonatomic) BOOL  isSlideAddShadow;
-(instancetype) init;
-(instancetype) initWithUrl:(NSString*)url;

+(DMNavigator*) getInstance;

/*!
 * 返回页面栈信息，内包含DMPageHolder对象
 */
-(NSMutableArray*) pageStack;

/*!
 *  返回栈顶页面对象
 *
 *  @return 栈顶页面对象
 */
-(DMPage*) topPage;

/*!
 *  返回栈顶页面对象
 *
 *  @return 栈顶页面对象
 */
-(DMPage*) topPage:(int)deep;

/*!
 * 将当期页面滚动到顶部
 */
-(void) rollup;


@end


/*!
 *  Navigator是框架页面导航的核心类型，该类型提供三个平台的版本(android,iOS,javascript)，只是语言上的差异，功能完全一致。Navigator实现了基于url控制页面跳转及页面参数传递的功能，跳转可以在Native页面和H5页面任意跳转，并维护统一的页面堆栈。
 */
@interface DMNavigator(Navigate)
/*!
 *  跳转到指定的页面
 *
 *  @param url 页面资源路径
 *     可能为app，h5或者RN页面
 */
-(void) forward:(NSString*)url;

/*!
 *  @param context 页面上下文，允许进行页面间对象传递
 */
-(void) forward:(NSString*)url  context:(NSDictionary *)context;
/*!
 *  跳转到指定的页面
 *
 *  @param url      页面资源路径
 *  @param callback 页面回调接口
 */
-(void) forward:(NSString* )url
       callback:(void(^)(NSDictionary* ))callback;

-(void) forward:(NSString *)url
        context:(NSDictionary *)context
       callback:(void(^)(NSDictionary* ))callback;
/**
 * 触发页面回退
 * @param param 可选返回参数，允许携带框架参数(参数名以@开头)。（例如"param=value&param2=value2&@animate=popright"）
 *     如果不传此参数，框架将在页面回退的同时不向上一个页面的回传数据。
 *     这样做的目的，是允许开发者在当前页面其他时机去主动调用callback回传数据，
 *     避免页面传参和页面回退动作绑死。
 * @param count 回退页面个数，以当前页面为准向之前页面回退count个页面，count<＝0不发生回退操作
 */
-(void) backward;

-(void) backward:(NSString*)param;

-(void) backward:(NSString*)param context:(NSDictionary *)context;

-(void) backward:(NSString *)param pageCount:(NSInteger)count;

-(void) backward:(NSString *)param pageCount:(NSInteger)count context:(NSDictionary *)context;

/*!
 * 替换当前页面，将当前页面从页面栈里推出，目标页面压入栈
 * @param url 目标替换页面url
 * @param callback 页面回调
 */
-(void) replace:(NSString *)url;

-(void) replace:(NSString *)url context:(NSDictionary *)context;

-(void) replace:(NSString *)url callback:(void(^)(NSDictionary* ))callback;

-(void) replace:(NSString *)url context:(NSDictionary *)context callback:(void (^)(NSDictionary *))callback;

/**
 * 单独向上一个页面回传参数的接口
 * @param param 参数 （例如"param=value&param2=value2"）
 */
-(void) callback:(NSString*)param;

/*!
 *  开启一个子业务流程
 */
-(void) pushFlow;
/*!
 *  结束当前子业务流程，同时页面跳转回之前pushFlow的地方
 */
-(void) popFlow:(NSString*)param;

-(void) popFlow:(NSString *)param context:(NSDictionary *)context;
@end



@interface DMNavigator(Registry)
/*!
 *  注册本地页面(不推荐使用此函数注册页面)
 *  默认情况下按照约定页面类型的名字可以作为跳转url中的页面名称，无需特别的注册。
 *  除非在极其特殊的情况下需要覆盖这个约定，才使用此函数注册页面, 赋予页面不同于类型名字的标志。
 *  因为在实际App中页面数量会越来越大，如果一定要在一个统一的地方注册的话，这个注册会变得很难维护。
 *  所以推荐使用约定来确定页面名称。不要过分的依赖这种页面注册功能。
 *
 *  @param name      本地页面的标识符,页面名称不区分大小写(例如标识符:Payment, 其他页面通过app://Payment来访问)
 *  @param pageClass
 *             页面实现类的class属性(例如Payment如果实现类为DMPayment的话，通过[DMPayment class]来指定)
 *             页面类型需要是UIViewController或者其子类
 */
+(void) registAppPage:(NSString*)name
            pageClass:(Class)pageClass;

/*!
 *  注册重定向url
 *  注意：url不包含参数部分
 *
 *  @param toUrl 目标url
 *  @param fromUrl 源url
 */
+(void) registRedirectFromUrl:(NSString*)fromUrl toUrl:(NSString*)toUrl;

@end
