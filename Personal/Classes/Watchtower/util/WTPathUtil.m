//
//  WTPathUtil.m
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/13.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import "WTPathUtil.h"
#import "WTLog.h"
@implementation WTPathUtil
+ (BOOL)isExistsFileAtPath:(NSString*)path{
    BOOL isDirectory = NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
}
+ (BOOL)isExistsFolderAtPath:(NSString*)path{
    BOOL isDirectory = YES;
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
}
+ (NSString *)getDocumentPathStr:(NSString*)path{
    return [self getDocumentPathFromPaths:[self segmentationPath:path]];
}
+(BOOL)createFolder:(NSString*)path{
    if (![self isExistsFolderAtPath:path]) {
        NSError *error=nil;
        BOOL isCreate=[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            WTError(@"创建文件夹失败：",error);
        }
        return isCreate;
    }
    return YES;
}
+(NSString*)getDocumentPath{
    return   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}
+(NSArray*)segmentationPath:(NSString*)path{
    NSArray *paths= [path componentsSeparatedByString:@"/"];
    return   paths;
}
+ (NSString *)getCombinePathName:(NSArray*)paths indexPath:(NSInteger)indexPath{
    NSMutableString *combinePath=[NSMutableString new];
    if (paths.count+1<indexPath) {
        return nil;
    }
    for (int i=0; i<=indexPath; i++) {
        [combinePath appendString:@"/"];
        [combinePath appendString:paths[i]];
    }
    return combinePath;
}
+ (NSString *)getDocumentPathFromPaths:(NSArray*)paths {
    NSString *documentPath = [self getDocumentPath];
    for(int i=0;i<paths.count;i++){
       
       NSString *path=[documentPath stringByAppendingPathComponent:[self getCombinePathName:paths indexPath:i]] ;
        if(![self createFolder:path]){
            return nil;
        }
        
    }
    NSString *path= [documentPath stringByAppendingString:[self getCombinePathName:paths indexPath:paths.count-1]];
    return path;
}
+ (NSArray*) getFilesFromFolder:(NSString*)path{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray * tempFileList = [[NSArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:path error:nil]];
    return tempFileList;
}
@end
