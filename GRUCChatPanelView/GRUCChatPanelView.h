//
//  GRUCChatPanelView.h
//
//
//  Created by chengbin on 15-11-11.
//  Copyright (c) 2015年 chengbin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^GRUCChatPanelViewWithKeyboardAnimationsChangeFrameBlock)(CGRect keyboardRect,CGFloat keyboardOffset,NSTimeInterval duration,BOOL isShowing);
typedef void(^GRUCChatPanelViewCompletionAnimationsBlock)(BOOL finished);
static const CGFloat INPUT_HEIGHT = 45.0f;
static const CGFloat NAV_HEIGHT = 64.0f;

@class GRUCChatPanelView;

@protocol GRUCChatPanelViewDelegate <NSObject>

@required

//tell you that you should begin recording
- (void)chatPanelViewShouldBeginRecord:(GRUCChatPanelView *)view;
//tell you that you view should cancel recording
- (void)chatPanelViewShouldCancelRecord:(GRUCChatPanelView *)view;
//tell you that you view should finish recording
- (void)chatPanelViewShouldFinishedRecord:(GRUCChatPanelView *)view;
//send text after clicking the button 'send' or 'return'
@optional
- (void)chatPanelViewSendText:(GRUCChatPanelView *)view andText:(NSString *)aText;
- (void)chatPanelViewUpdateFrame:(GRUCChatPanelView *)view andFrame:(CGRect)rc;//视图随着文本的变化而变化
@end

@interface GRUCChatPanelView : UIView
{

    NSString *_text;
    UIColor  *_textColor;
    UIFont   *_textFont;
    UIColor  *_textViewBackgroundColor;
}

@property (nonatomic, weak) id<GRUCChatPanelViewDelegate> delegate;

@property (nonatomic, strong, readwrite) NSString    *text;

@property (nonatomic, strong, readwrite) UIColor     *textColor;

@property (nonatomic, strong, readwrite) UIFont      *textFont;

@property (nonatomic, strong, readwrite) UIColor     *textViewBackgroundColor;

@property (nonatomic, strong, readonly)  UITextView   *textView;


//update view
- (void)grucHandleUpdateChatPanelViewWithKeyboardAnimationsAndFrame:(GRUCChatPanelViewWithKeyboardAnimationsChangeFrameBlock)animations completion:(GRUCChatPanelViewCompletionAnimationsBlock)completion;//视图随着键盘的变化而变化

//show view
- (void)showInView:(UIView *)view;

//you should call this method when you have prepared for record
- (void)didBeginRecord;

@end
