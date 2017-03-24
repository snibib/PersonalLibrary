//
//  WTFileManager.m
//  Watchtower
//
//  Created by 兵兵 刘 on 2017/2/20.
//  Copyright © 2017年 兵兵 刘. All rights reserved.
//

#import "WTFileManager.h"
#import "WTPathUtil.h"
#import "WTLog.h"
#import "ZipArchive/ZipArchive.h"
@implementation WTFileManager

+ (BOOL)isZip:(NSData*)data{
    if (data.length<5) {
        return NO;
    }
    char _header[4];
    for (int i = 0; i < 4; i++) {
        int headerOffset = (int)i;
        const char *bytes = [data bytes];
        _header[headerOffset] = bytes[i];
    }
    BOOL isZip = _header[0] == 'P' && _header[1] == 'K' && _header[2] == 3 && _header[3] == 4;
    return isZip;
}
/**
 *  解压
 *  @param fromPath 解压文件目录
 *  @param toPath   解压到目录
 */
+ (BOOL)unzipfile:(NSString*)fromPath toPath:(NSString*)toPath {
    ZipArchive *za = [[ZipArchive alloc] init];
    if ([za UnzipOpenFile:fromPath]) {
        WTDebug(@"解压资源目录:%@",[za getZipFileContents]);
        WTDebug(@"解压到的地址:%@",toPath);
        BOOL zip=[za UnzipFileTo:toPath overWrite:YES];
        [za UnzipCloseFile];
        
        if(!zip){
            WTError(@"解压失败：from:%@-->to:%@",fromPath,toPath);
            [WTFileManager removeFile:fromPath];
        }else{
            WTDebug(@"解压成功：%@",fromPath);
        }
        return zip;
    }
    [WTFileManager removeFile:fromPath];
    WTError(@"解压文件不是zip文件：%@",fromPath);
    return false;
}

+(BOOL)removeFile:(NSString*)path{
    NSError *err;
    BOOL isRemove=[[NSFileManager defaultManager] removeItemAtPath:path error:&err];
    if (err) {
        WTError(@"移除下载文件出错（%@）：%@",path,err);
    }
    return isRemove;
}


/**
 *  文件拷贝
 *  @param fromPath 拷贝文件目录
 *  @param toPath   拷贝到目录
 */
+ (BOOL)copyFile:(NSString*)fromPath toPath:(NSString*)toPath{
    
    if ([WTPathUtil isExistsFileAtPath:toPath]) {
        NSError *err;
        [[NSFileManager defaultManager] removeItemAtPath:toPath error:&err];
    }
    
    NSError *err;
    [[NSFileManager defaultManager] copyItemAtPath:fromPath toPath:toPath error:&err];
    if (err) {
        WTError(@"copyFile：%@",err);
        return false;
    }else{
        [[NSFileManager defaultManager] removeItemAtPath:fromPath error:&err];
        if (err) {
            WTError(@"copyFile：%@",err);
            return false;
        }else{
            return true;
        }
    }
    
}
@end
