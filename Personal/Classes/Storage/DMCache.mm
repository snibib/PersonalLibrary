//
//  DMCache.m
//  dmall
//
//  Created by chenxinxin on 2015-11-16.
//  Copyright (c) 2015 dmall. All rights reserved.
//

#import "DMCache.h"
#import "DMLog.h"
#import "leveldb/db.h"

@interface  DMCache()
@end

@implementation DMCache {
    leveldb::DB* _db;
}

DMLOG_DEFINE(DMCache)

- (instancetype)initWithPath:(NSString*) path;
{
    self = [super init];
    if (self) {
        
        DMDebug(@"open cache in %@",path);
        
        self->_db = NULL;
        leveldb::Options options;
        options.create_if_missing = true;
        leveldb::DB::Open(options, [path cStringUsingEncoding:NSUTF8StringEncoding], &self->_db);
    }
    return self;
}

- (void)dealloc
{
    if(_db != NULL) {
        delete _db;
        _db = NULL;
    }
}

-(void) setData:(NSData*) data forKey:(NSString*) key {
    if(data != nil) {
        DMDebug(@"save to cache => byteLength:%d key:%@",(int)data.length,key);
        self->_db->Put(leveldb::WriteOptions(), [key cStringUsingEncoding:NSUTF8StringEncoding], leveldb::Slice((const char*)[data bytes],[data length]));
    } else {
        DMDebug(@"remove data due to nil data => key:%@",key);
        [self removeDataForKey:key];
    }
}

-(NSData*) dataForKey:(NSString*) key {
    std::string value;
    leveldb::Status status = self->_db->Get(leveldb::ReadOptions(), [key cStringUsingEncoding:NSUTF8StringEncoding], &value);
    if(status.IsNotFound()) {
        DMDebug(@"read data failed due to not exists => key : %@",key);
        return nil;
    } else {
       NSData* data = [NSData dataWithBytes:value.c_str() length:value.length()];
        DMDebug(@"read data sucess => byteLength:%d key:%@",(int)data.length,key);
        return data;
    }
}

-(void) removeDataForKey:(NSString*) key {
    DMDebug(@"removeDataForKey:%@",key);
    leveldb::Status s = self->_db->Delete(leveldb::WriteOptions(), [key cStringUsingEncoding:NSUTF8StringEncoding]);
}

DMCache* DMCache_instance = nil;

+(DMCache*) getInstance {
    if(DMCache_instance == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString* path = [NSString stringWithFormat:@"%@/DMCache",documentsDirectory];
        
        DMCache_instance = [[DMCache alloc] initWithPath:path];
    }
    return DMCache_instance;
}

@end
