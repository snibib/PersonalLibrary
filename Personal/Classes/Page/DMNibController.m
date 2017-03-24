//
//  DMNibController.m
//  Deck
//
//  Created by 杨涵 on 2016/12/22.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMNibController.h"
#import "DMLog.h"

@implementation DMNibController

DMLOG_DEFINE(DMNibController)

-(NSBundle*) nibFileBundle {
    return [NSBundle mainBundle];
}

-(NSString*) nibFileName {
    return NSStringFromClass(self.class);
}

-(NSArray*) loadNibs:(NSString*)fileName bundle:(NSBundle*)bundle {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[bundle pathForResource:fileName ofType:@"nib"]]
        ) {
        return [bundle loadNibNamed:fileName owner:self options:nil];
    } else {
        DMWarn(@"[Warn] can't load nib file %@ in main bundle",fileName);
    }
    return nil;
}

- (void) loadView {
    [super loadView];
    
    NSString* fileName  = [self nibFileName];
    NSArray* nib        = [self loadNibs:fileName bundle:[self nibFileBundle]];
    if (nib == nil || nib.count == 0) {
        return;
    }
    UIView* view  = [nib objectAtIndex:0];
    view.frame    = [UIScreen mainScreen].bounds;
    [view setNeedsLayout];
    self.view     = view;
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.view.frame = [UIScreen mainScreen].bounds;
}
@end
