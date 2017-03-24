//
//  DKUpdateSource.m
//  Deck
//
//  Created by 兵兵 刘 on 16/9/21.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "WTUpdateSource.h"
#import "WTLog.h"
#import "WTPathUtil.h"
@implementation WTUpdateSource
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    
    return YES;
}
+ (JSONKeyMapper*) keyMapper{
    
    JSONKeyMapper *mapper = [[JSONKeyMapper alloc] initWithDictionary:@{@"id":@"idstr"}];
    return mapper;
}
+ (BOOL) propertyIsIgnored:(NSString *)propertyName{
    
    if([propertyName isEqualToString:@"wt_url"]||
       [propertyName isEqualToString:@"wt_size"]||
       [propertyName isEqualToString:@"wt_name"]||
       [propertyName isEqualToString:@"wt_localPath"]||
       [propertyName isEqualToString:@"isUnZip"]||
       [propertyName isEqualToString:@"typeStr"]
       )
        
        return YES;
    
    return NO;
    
}

-(NSString *)dir{
    if (_dir.length>0) {
        return _dir;
    }else{
        return @"";
    }
}
-(NSString *)name{
    if (_name.length==0) {
        return @"";
    }else{
        return _name;
    }
}
-(NSString*)version{
    if (_version.length==0) {
        return @"";
    }else{
        return _version;
    }
}
-(NSString *)pageName{
    return [NSString stringWithFormat:@"%@%@%@.zip",self.name,self.idstr,self.version];
}

-(NSString *)wt_url{
    return self.link;
}
-(NSString *)wt_name{
    return [self pageName];
}
-(NSString *)wt_size{
    return @"123";
}

-(NSString*)getUnzipToPath{
    NSString *toPath   =  nil;
    if (self.type==WTUpdateSourceTypeH5) {
        toPath   =  [WTPathUtil getDocumentPathStr:[NSString stringWithFormat:@"/%@/%@/%@",SourceDic,H5LocalPath,self.dir]];
    }else if(self.type==WTUpdateSourceTypeRN)
    {
        toPath   =  [WTPathUtil getDocumentPathStr:[NSString stringWithFormat:@"/%@/%@/%@",SourceDic,RNLocalPath,self.dir]];
    }else if (self.type==WTUpdateSourceTypeJson){
        toPath   =  [WTPathUtil getDocumentPathStr:[NSString stringWithFormat:@"/%@/%@/%@",SourceDic,JonsLocalPath,self.dir]];
    }else if (self.type==WTUpdateSourceTypeCustom){
        toPath   =  [WTPathUtil getDocumentPathStr:[NSString stringWithFormat:@"/%@/%@/%@",SourceDic,CustomLocalPath,self.dir]];
    }
    return toPath;
}
-(NSString *)typeStr{
    NSString *typeStr=nil;
    if (self.type==WTUpdateSourceTypeH5) {
        typeStr = H5LocalPath;
    }else if(self.type==WTUpdateSourceTypeRN)
    {
        typeStr = RNLocalPath;
    }else if (self.type==WTUpdateSourceTypeJson){
        typeStr = JonsLocalPath;
    }else if (self.type==WTUpdateSourceTypeCustom){
        typeStr = CustomLocalPath;
    }

    return typeStr;
}
-(NSString *)idstr{
    if (_idstr.length==0) {
        return @"";
    }else{
       return  _idstr;
    }
}
-(NSString *)getUnzipFromFile{
    return [[WTPathUtil getDocumentPathFromPaths:@[SourceDic,LocalTmpPath,self.typeStr]]  stringByAppendingPathComponent:self.pageName];
}
-(NSString*)getLoadLocalPath{
    return [NSString stringWithFormat:@"/%@/%@/%@/",SourceDic,LocalTmpPath,self.typeStr];
}
-(BOOL) isSameSouece:(WTUpdateSource*)source{
    if ([self.name isEqualToString:source.name]&&self.type ==source.type&&[self.idstr isEqualToString:source.idstr]) {
        return YES;
    }else{
        return NO;
    }
}
@end
