//
//  DMPageAnimateMagic.m
//  DMAppFramework
//
//  Created by chenxinxin on 15/11/6.
//  Copyright (c) 2015年 dmall. All rights reserved.
//

#import "DMPageAnimateMagicMove.h"
#import "DMPageAnimate.h"
#import "DMWeakify.h"
#import "DMMagicMoveSet.h"
#import "DMMagicMoveCell.h"

@interface DMMagicCell : NSObject
@property (strong,nonatomic) NSString* key;
@property (strong,nonatomic) id fromView;
@property (strong,nonatomic) id toView;
@property (assign,nonatomic) CGRect fromViewBegin;
@property (assign,nonatomic) CGRect fromViewEnd;
@property (assign,nonatomic) CGRect toViewBegin;
@property (assign,nonatomic) CGRect toViewEnd;

-(UIView*) getFromView;
-(UIView*) getToView;

-(BOOL) needRotateByX;
-(BOOL) needRotateByY;

@end

@implementation DMMagicCell
-(BOOL) needRotateByX {
    if ([self.fromView isKindOfClass:[DMMagicMoveCell class]]) {
        return [((DMMagicMoveCell*)self.fromView) rotate3DByX];
    }
    if ([self.toView isKindOfClass:[DMMagicMoveCell class]]) {
        return [((DMMagicMoveCell*)self.toView) rotate3DByX];
    }
    return NO;
}
-(BOOL) needRotateByY {
    if ([self.fromView isKindOfClass:[DMMagicMoveCell class]]) {
        return [((DMMagicMoveCell*)self.fromView) rotate3DByY];
    }
    if ([self.toView isKindOfClass:[DMMagicMoveCell class]]) {
        return [((DMMagicMoveCell*)self.toView) rotate3DByY];
    }
    return NO;
}
-(UIView*) getFromView {
    if ([self.fromView isKindOfClass:[UIView class]]) {
        return self.fromView;
    }
    if ([self.fromView isKindOfClass:[DMMagicMoveCell class]]) {
        return [((DMMagicMoveCell*)self.fromView) view];
    }
    return nil;
}
-(UIView*) getToView {
    if ([self.toView isKindOfClass:[UIView class]]) {
        return self.toView;
    }
    if ([self.toView isKindOfClass:[DMMagicMoveCell class]]) {
        return [((DMMagicMoveCell*)self.toView) view];
    }
    return nil;
}
@end


@implementation DMPageAnimateMagicMove

-(void) animateFrom : (UIViewController*) from
                 to : (UIViewController*) to
           callback : (void (^)()) callback {
    from.view.layer.opacity = 1;
    to.view.layer.opacity = 0;
    
    NSMutableDictionary* magicCells = [[NSMutableDictionary alloc] init];

    NSDictionary* fromMagicSet = nil;
    NSDictionary* toMagicSet = nil;
    if ([from respondsToSelector:@selector(magicMoveSet)]) {
        fromMagicSet = [((id<DMMagicMoveSet>)from) magicMoveSet];
    }
    if ([to respondsToSelector:@selector(magicMoveSet)]) {
        toMagicSet = [((id<DMMagicMoveSet>)to) magicMoveSet];
    }
    for (NSString* key in fromMagicSet) {
        id fromView = [fromMagicSet objectForKey:key];
        id toView = [toMagicSet objectForKey:key];
        if (fromView != nil && toView != nil) {
            DMMagicCell* cell = [[DMMagicCell alloc] init];
            cell.fromView = fromView;
            cell.toView = toView;
            cell.fromViewBegin = [cell getFromView].frame;
            cell.fromViewEnd = [[cell getFromView].superview convertRect:[cell getToView].frame fromView:[cell getToView].superview];
            cell.toViewBegin = [[cell getToView].superview convertRect:[cell getFromView].frame fromView:[cell getFromView].superview];
            cell.toViewEnd = [cell getToView].frame;
            [magicCells setObject:cell forKey:key];
        }
    }
    
    // 设置开始
    for(NSString* key in magicCells) {
        DMMagicCell* cell = [magicCells objectForKey:key];
        if (cell != nil) {
            [cell getToView].frame = cell.toViewBegin;
            if ([cell needRotateByX]) {
                [cell getToView].layer.transform = CATransform3DRotate(CATransform3DIdentity, -1*M_PI, 1, 0, 0) ;
                [cell getFromView].layer.transform = CATransform3DRotate(CATransform3DIdentity, 0, 1, 0, 0) ;
            }
            if ([cell needRotateByY]) {
                [cell getToView].layer.transform = CATransform3DRotate(CATransform3DIdentity, -1*M_PI, 0, 1, 0) ;
                [cell getFromView].layer.transform = CATransform3DRotate(CATransform3DIdentity, 0, 0, 1, 0) ;
            }
        }
    }
        
    @weakify(from)
    @weakify(to)
    //@weakify(magicCells)
    
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        @strongify(from)
        @strongify(to)
        //  @strongify(magicCells)
        strong_from.view.layer.opacity = 0;
        strong_to.view.layer.opacity = 1;
        
        // 设置结束
        for(NSString* key in magicCells) {
            DMMagicCell* cell = [magicCells objectForKey:key];
            if (cell != nil) {
                [cell getFromView].frame = cell.fromViewEnd;
                [cell getToView].frame = cell.toViewEnd;
                
                if ([cell needRotateByX]) {
                    [cell getToView].layer.transform = CATransform3DRotate(CATransform3DIdentity, 0, 1, 0, 0) ;
                    [cell getFromView].layer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI, 1, 0, 0) ;
                }
                if ([cell needRotateByY]) {
                    [cell getToView].layer.transform = CATransform3DRotate(CATransform3DIdentity, 0, 0, 1, 0) ;
                    [cell getFromView].layer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 1, 0) ;
                }
            }
        }

    } completion:^(BOOL finished) {
        @strongify(from)
        @strongify(to)
        //@strongify(magicCells)
        strong_from.view.layer.opacity = 1;
        strong_to.view.layer.opacity = 1;
        
        // 设置from
        for(NSString* key in magicCells) {
            DMMagicCell* cell = [magicCells objectForKey:key];
            if (cell != nil) {
                [cell getFromView].frame = cell.fromViewBegin;
                [cell getToView].frame = cell.toViewEnd;
                
                [cell getFromView].layer.transform = CATransform3DIdentity;
                [cell getToView].layer.transform = CATransform3DIdentity;
            }
        }
        
        if (callback) {
            callback();
        }
    }];
}

@end
