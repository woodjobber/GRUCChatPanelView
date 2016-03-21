//
//  GRUCChatPanelView+KeyboardAnimation.h
//  GRUC
//
//  Created by chengbin on 15/11/16.
//
//

/** 
 * 强弱引用转换，用于解决代码块（block）与强引用对象之间的循环引用问题
 * 调用方式: `@weakify(object)`实现弱引用转换，`@strongify(object)`实现强引用转换
 *
 * 示例：
 * @weakify(object)
 * [obj block:^{
 * @strongify(object)
 * strong_object = something;
 * }];
 */
#ifndef    weakify
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#endif
#ifndef    strongify
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) strong##_##object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) strong##_##object = block##_##object;
#endif
#endif



#import "GRUCChatPanelView.h"

typedef void(^GRUCAnimationsWithKeyboardBlock)(CGRect keyboardRect,CGFloat keyboardOffset,NSTimeInterval duration,BOOL isShowing);
typedef void(^GRUCBeforeAnimationsWithKeyboardBlock)(CGRect keyboardRect,CGFloat keyboardOffset,NSTimeInterval duration,BOOL isShowing);
typedef void(^GRUCCompletionKeyboardAnimationsBlock)(BOOL finished);
typedef void(^GRUCCompletionBeforeUnsubscribeKeyboardBlcok)(void);


@interface GRUCChatPanelView (KeyboardAnimation)
@property (nonatomic,assign) CGFloat yOffset; // keyboard offset if yOfset < 0, the keyboard is Showing,otherwise, it is Hiddening.


/**
 *  To the notification center, subscribe to a change in the keyboard position of the observer.
 *  The name of the object observered is 'UIKeyboardWillChangeFrameNotification'.
 *  @param animations perform the same as the keyboard animations.
 *  @param completion after the keyboard animations completion, Maybe you have other things to do.
 */

- (void)gruc_subscribeKeyboardWithAnimations:(GRUCAnimationsWithKeyboardBlock)animations completion:(GRUCCompletionKeyboardAnimationsBlock)completion;


/**
 *  To the notification center,subscribe to a change in the keyboard postion ofhte observer.
 *
 *  @param beforeAnimations before performing the keyboard animations,Maybe you have other things to do.
 *  @param animations       perform the keyboard animations.
 *  @param completion       the keyboard animaitons completion.
 */

- (void)gruc_subscribeKeyboardWithBeforeAnimations:(GRUCBeforeAnimationsWithKeyboardBlock)beforeAnimations
                                        animations:(GRUCAnimationsWithKeyboardBlock)animations
                                        completion:(GRUCCompletionKeyboardAnimationsBlock)completion;


/**
 *  Cancel subscriber for change the postion of the keyboard.
 */
- (void)gruc_unsubscribeKeyboard;


/**
 *  Cancel subcriber for change the postion of the keyboard. but before canceling subcriber,Maybe you have other things to do.
 *
 *  @param completion completion context.
 */

- (void)gruc_beforeUnsubscribeKeyboard:(GRUCCompletionBeforeUnsubscribeKeyboardBlcok)completion;


@end
