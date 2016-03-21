//
//  GRUCChatPanelView+KeyboardAnimation.m
//  GRUC
//
//  Created by chengbin on 15/11/16.
//
//

#import "GRUCChatPanelView+KeyboardAnimation.h"
#import <objc/runtime.h>

static const void *GRUCAnimationsBlockAssociationKey = &GRUCAnimationsBlockAssociationKey;
static const void *GRUCBeforeAnimationsBlockAssociationKey = &GRUCBeforeAnimationsBlockAssociationKey;
static const void *GRUCAnimationsCompletionBlockAssociationKey = &GRUCAnimationsCompletionBlockAssociationKey;
static const void *externVarableKey = &externVarableKey;



@implementation GRUCChatPanelView (KeyboardAnimation)



#pragma mark -- puplic methods
- (void)gruc_subscribeKeyboardWithAnimations:(GRUCAnimationsWithKeyboardBlock)animations completion:(GRUCCompletionKeyboardAnimationsBlock)completion{
    [self gruc_subscribeKeyboardWithBeforeAnimations:nil animations:animations completion:completion];
}

-(void)gruc_subscribeKeyboardWithBeforeAnimations:(GRUCBeforeAnimationsWithKeyboardBlock)beforeAnimations animations:(GRUCAnimationsWithKeyboardBlock)animations completion:(GRUCCompletionKeyboardAnimationsBlock)completion{
    objc_setAssociatedObject(self, GRUCBeforeAnimationsBlockAssociationKey, beforeAnimations, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, GRUCAnimationsBlockAssociationKey, animations, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, GRUCAnimationsCompletionBlockAssociationKey, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(gruc_keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

-(void)gruc_unsubscribeKeyboard{
    [self gruc_beforeUnsubscribeKeyboard:nil];
    
}

-(void)gruc_beforeUnsubscribeKeyboard:(GRUCCompletionBeforeUnsubscribeKeyboardBlcok)completion{
    if (completion) {
        completion();
    }
    
    objc_setAssociatedObject(self, GRUCBeforeAnimationsBlockAssociationKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, GRUCAnimationsBlockAssociationKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, GRUCAnimationsCompletionBlockAssociationKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];

}



#pragma mark -- private methods

- (void)gruc_keyboardWillChangeFrame:(NSNotification *)notification{
    
    BOOL isShowing;
    NSDictionary *info = [notification userInfo];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect beginKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat offset = endKeyboardRect.origin.y - beginKeyboardRect.origin.y;
    self.yOffset += offset;
    isShowing = offset>0?NO:YES;
    GRUCAnimationsWithKeyboardBlock animationsBlock = objc_getAssociatedObject(self, GRUCAnimationsBlockAssociationKey);
    GRUCBeforeAnimationsWithKeyboardBlock beforeAnimationsBlock = objc_getAssociatedObject(self, GRUCBeforeAnimationsBlockAssociationKey);
    GRUCCompletionKeyboardAnimationsBlock completionBlock = objc_getAssociatedObject(self, GRUCAnimationsCompletionBlockAssociationKey);
    
    
    if (beforeAnimationsBlock) {
        beforeAnimationsBlock(endKeyboardRect,offset,duration,isShowing);
    }
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [UIView setAnimationCurve:curve];
        
        if (animationsBlock) {
            animationsBlock(endKeyboardRect,offset,duration,isShowing);
        }
    } completion:^(BOOL finished) {
        completionBlock(finished);
    }];
    
}


- (CGFloat)yOffset{
    return [objc_getAssociatedObject(self, externVarableKey) doubleValue];
}

-(void)setYOffset:(CGFloat)yOffset{
    objc_setAssociatedObject(self, externVarableKey, @(yOffset), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
