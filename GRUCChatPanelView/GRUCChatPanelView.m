

#import "GRUCChatPanelView.h"
#import <CoreText/CoreText.h>
#import "FBShimmeringView.h"
#import "GRUCChatPanelView+KeyboardAnimation.h"
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusbarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define kFloatRecordImageUpTime (0.5f)
#define kFloatRecordImageRotateTime (0.17f)
#define kFloatRecordImageDownTime (0.5f)
#define kFloatGarbageAnimationTime (.3f)
#define kFloatGarbageBeginY (45.0f)
#define kFloatCancelRecordingOffsetX  (100.0f)
CGFloat kHeight_TextView = 0.0f;
CGFloat const topMagin = 8.5f;
static void setViewFixedAnchorPoint(CGPoint anchorPoint, UIView *view)
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

@interface GRUCSlideView : UIView

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

- (void)updateLocation:(CGFloat)offsetX;

@end

@implementation GRUCSlideView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self createSubViews];
    }
    
    return self;
}

- (void)createSubViews
{
    self.clipsToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.text = @"滑动删除";
    label.font = [UIFont systemFontOfSize:16.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    [self addSubview:label];
    self.textLabel = label;
    
    UIImageView *bkimageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SlideArrow"]];
    CGRect frame = bkimageView.frame;
    frame.origin.x = self.frame.size.width / 2.0 + 33;
    frame.origin.y += 5;
    [bkimageView setFrame:frame];
    [self addSubview:bkimageView];
    self.arrowImageView = bkimageView;
}

- (void)updateLocation:(CGFloat)offsetX
{
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.x += offsetX;
    self.textLabel.frame = labelFrame;
    
    CGRect imageFrame = self.arrowImageView.frame;
    imageFrame.origin.x += offsetX;
    self.arrowImageView.frame = imageFrame;
}

@end

@interface WARVGarbageView : UIView

@property (nonatomic, strong) UIImageView *bodyView;
@property (nonatomic, strong) UIImageView *headerView;

@end

@implementation WARVGarbageView


- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 18, 26)];
    if (self) {
        self.bodyView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BucketBodyTemplate"]];
        self.headerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BucketLidTemplate"]];
        CGRect frame = self.bodyView.frame;
        frame.origin.y = 1;
        [self.bodyView setFrame:frame];
        [self addSubview:self.headerView];
        setViewFixedAnchorPoint(CGPointMake(0, 1), self.headerView);
        [self addSubview:self.bodyView];
    }
    return self;
}

@end

@interface GRUCChatPanelView ()<UITextViewDelegate>

@property (nonatomic, strong,readwrite) UITextField      *textField;
@property (nonatomic, strong,readwrite) FBShimmeringView *slideView;
@property (nonatomic, strong,readwrite) UIButton         *recordBtn;
@property (nonatomic, strong,readwrite) UIButton         *voiceBtn;
@property (nonatomic, strong,readwrite) UIButton         *shareBtn;
@property (nonatomic, strong,readwrite) UILabel          *timeLabel;
@property (nonatomic, assign,readwrite) CGPoint          trackTouchPoint;
@property (nonatomic, assign,readwrite) CGPoint          firstTouchPoint;
@property (nonatomic, strong,readwrite) WARVGarbageView  *garbageImageView;
@property (nonatomic, assign,readwrite) BOOL             canCancelAnimation;
@property (nonatomic, assign,readwrite) BOOL             isCanceling;
@property (nonatomic, strong,readwrite) NSTimer          *countTimer;
@property (nonatomic, assign,readwrite) NSUInteger       currentSeconds;
@property (nonatomic, strong,readwrite) UIButton         *emotionBtn;
@property (nonatomic, assign,readwrite) CGFloat           keyboardOriginY;
@property (nonatomic, assign,readwrite) CGRect            lrect;
@property (nonatomic, assign,readwrite) CGFloat           yOffset;

@property (nonatomic, strong,readwrite) GRUCChatPanelViewWithKeyboardAnimationsChangeFrameBlock keyboardAnimations;

@property (nonatomic, strong,readwrite) GRUCChatPanelViewCompletionAnimationsBlock completionAnimations;
@end

@implementation GRUCChatPanelView

@synthesize textColor = _textColor;
@synthesize textFont =_textFont;
@synthesize text = _text;
@synthesize textViewBackgroundColor= _textViewBackgroundColor;


- (instancetype)init
{
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    self = [super initWithFrame:CGRectMake(0, 0, size.width, INPUT_HEIGHT)];

    if (self) {
        [self creatSubviews];
         self.canCancelAnimation = NO;
    }
    return self;
}

- (void)creatSubviews
{
    
    self.keyboardOriginY = kScreenHeight;
    self.backgroundColor =[UIColor grayColor];
    CGFloat l_height = self.frame.size.height;
    CGFloat l_width = self.frame.size.width;
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [shareButton setImage:[UIImage imageNamed:@"ButtonAttachMedia7"] forState:UIControlStateNormal];
    [shareButton setImage:[UIImage imageNamed:@"ButtonAttachMedia7"] forState:UIControlStateSelected];
    [shareButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [shareButton setFrame:CGRectMake(10, l_height/2 - 45.0f/2, 26, 45.0f)];
    [shareButton addTarget:self action:@selector(sendShareMsg:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:shareButton];
     self.shareBtn = shareButton;
    
    UIButton *emotBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [emotBtn setImage:[UIImage imageNamed:@"MicRecBtn"] forState:UIControlStateNormal];
    [emotBtn setImage:[UIImage imageNamed:@"MicRecRed"] forState:UIControlStateSelected];
    [emotBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [emotBtn setFrame:CGRectMake(46, l_height/2 - 45.0f/2, 26, 45.0f)];
    [emotBtn addTarget:self action:@selector(sendEmotionBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:emotBtn];
     self.emotionBtn = emotBtn;
    CGFloat x = emotBtn.frame.origin.x + emotBtn.frame.size.width + 10;
    CGFloat width = l_width - x - 26;
    kHeight_TextView = l_height - 2*topMagin;
    _textView = ({
        UITextView *txtView =  [[UITextView alloc]initWithFrame:CGRectMake(x, topMagin, width - 10, kHeight_TextView)];
        txtView.backgroundColor = [UIColor whiteColor];
        txtView.scrollEnabled = YES;
        txtView.editable = YES;
        txtView.delegate = self;
        txtView.returnKeyType = UIReturnKeySend;
        txtView.textAlignment = NSTextAlignmentLeft;
        txtView.keyboardType = UIKeyboardTypeDefault;
        txtView.dataDetectorTypes = UIDataDetectorTypeAll;
        txtView.textColor = [UIColor blackColor];
        txtView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        txtView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        txtView.autocorrectionType =UITextAutocorrectionTypeNo;
        txtView.spellCheckingType = UITextSpellCheckingTypeYes;
        txtView.font = [UIFont systemFontOfSize:16.0f];
        txtView.layer.cornerRadius = 6;
        txtView.layer.masksToBounds = YES;
        txtView.layer.backgroundColor = [[UIColor clearColor] CGColor];
        txtView.layer.borderColor = [[UIColor colorWithRed:215.0 / 255.0 green:215.0 / 255.0 blue:215.0 / 255.0 alpha:1] CGColor];
        txtView.layer.borderWidth = 1.2f;
        [txtView.layer setMasksToBounds:YES];
         UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 2.0, 2.0, 0.0);
        [txtView setContentInset:insets];
        [self addSubview:txtView];
        txtView;
    });
    
    UIButton *voice = [UIButton buttonWithType:UIButtonTypeSystem];
    [voice setImage:[UIImage imageNamed:@"chat_micphone_up1"] forState:UIControlStateNormal];
    [voice setImage:[UIImage imageNamed:@"MicRecRed"] forState:UIControlStateSelected];
    [voice setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    CGFloat width1 = l_width - (_textView.frame.size.width+ _textView.frame.origin.x) - 5;
    
    [voice setFrame:CGRectMake(width + x - 5 , l_height/2 - 45.0f/2, width1, 45)];
    [voice addTarget:self action:@selector(beginRecord:forEvent:) forControlEvents:UIControlEventTouchDown];
    [voice addTarget:self action:@selector(mayCancelRecord:forEvent:) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
    [voice addTarget:self action:@selector(finishedRecord:forEvent:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    [self addSubview:voice];
    self.voiceBtn = voice;
}

-(void)setTextColor:(UIColor *)textColor{
    if (textColor != _textColor) {
        self.textView.textColor = textColor;
        _textColor = textColor;
        [self.textView setNeedsDisplay];
    }
}
-(void)setTextFont:(UIFont *)textFont{
    if (_textFont != textFont) {
        [self.textView setFont:textFont];
        _textFont = textFont;
        [self.textView setNeedsDisplay];
    }
}

-(void)setTextViewBackgroundColor:(UIColor *)textViewBackgroundColor{
    if (_textViewBackgroundColor != textViewBackgroundColor) {
        [self.textView setBackgroundColor:textViewBackgroundColor];
        _textViewBackgroundColor= textViewBackgroundColor;
        [self.textView setNeedsDisplay];
    }
}




- (void)sendEmotionBtn:(id)sender{

}
- (void)beginRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    self.textView.hidden = YES;
    self.shareBtn.hidden = YES;
    self.emotionBtn.hidden = YES;
    UITouch *touch = [[event touchesForView:btn] anyObject];
    self.trackTouchPoint = [touch locationInView:self];
    self.firstTouchPoint = self.trackTouchPoint;
    self.isCanceling = NO;
    
    [self showSlideView];
    [self showRecordImageView];
    
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldBeginRecord:)]) {
        [self.delegate chatPanelViewShouldBeginRecord:self];
    }
}


- (void)mayCancelRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    UITouch *touch = [[event touchesForView:btn] anyObject];
    CGPoint curPoint = [touch locationInView:self];
    if (curPoint.x < self.voiceBtn.frame.origin.x) {
        [(GRUCSlideView *)self.slideView.contentView updateLocation:(curPoint.x - self.trackTouchPoint.x)];
    }
    self.trackTouchPoint = curPoint;
    if ((self.firstTouchPoint.x - self.trackTouchPoint.x ) > kFloatCancelRecordingOffsetX) {
        self.isCanceling = YES;
        [btn cancelTrackingWithEvent:event];
        [self cancelRecord];
    }
}

- (void)finishedRecord:(UIButton *)btn forEvent:(UIEvent *)event
{
    if (self.isCanceling) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldFinishedRecord:)]) {
        [self.delegate chatPanelViewShouldFinishedRecord:self];
    }

    [self endRecord];
    
    self.recordBtn.hidden = YES;
}

- (void)cancelRecord
{
    if ([self.delegate respondsToSelector:@selector(chatPanelViewShouldCancelRecord:)]) {
        [self.delegate chatPanelViewShouldCancelRecord:self];
    }
    
    [self.recordBtn.layer removeAllAnimations];
    self.slideView.hidden = YES;
    [self.voiceBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    CGRect orgFrame = self.recordBtn.frame;
    
    if (!self.canCancelAnimation) {
        [self endRecord];
        return;
    }
    
    [UIView animateWithDuration:kFloatRecordImageUpTime delay:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.recordBtn.frame;
        
        frame.origin.y -= (1.5 * self.recordBtn.frame.size.height);

        self.recordBtn.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            
            [self showGarbage];
            
            [UIView animateWithDuration:kFloatRecordImageRotateTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGAffineTransform transForm = CGAffineTransformMakeRotation(-1 * M_PI);
                self.recordBtn.transform = transForm;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:kFloatRecordImageDownTime delay:.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.recordBtn.frame = orgFrame;
                    self.recordBtn.alpha = 0.1f;
                }completion:^(BOOL finished) {
                    self.recordBtn.hidden = YES;
                    [self dismissGarbage];
                }];
            }];
        }
        }];
}

- (void)dismissGarbage
{
    [UIView animateWithDuration:kFloatGarbageAnimationTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.garbageImageView.headerView.transform = CGAffineTransformIdentity;
        CGRect frame = self.garbageImageView.frame;
        frame.origin.y = kFloatGarbageBeginY;
        self.garbageImageView.frame = frame;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self endRecord];
        });
    }];
}

- (void)showGarbage
{
    [self garbageImageView];
    [UIView animateWithDuration:kFloatGarbageAnimationTime delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform transForm = CGAffineTransformMakeRotation(-1 * M_PI_2);
        self.garbageImageView.headerView.transform = transForm;
        CGRect frame = self.garbageImageView.frame;
        frame.origin.y = (self.bounds.size.height - frame.size.height) / 2.0;
        self.garbageImageView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

- (WARVGarbageView *)garbageImageView
{
    if (!_garbageImageView) {
        WARVGarbageView *imageView = [[WARVGarbageView alloc] init];
        CGRect frame = imageView.frame;
        frame.origin = CGPointMake(_recordBtn.center.x - frame.size.width / 2.0f, kFloatGarbageBeginY);
        [imageView setFrame:frame];
        [self addSubview:imageView];
        _garbageImageView = imageView;
    }
    return _garbageImageView;
}


- (void)showSlideView
{
    self.slideView.hidden = NO;
    CGRect frame = self.slideView.frame;
    CGRect orgFrame = {CGPointMake(CGRectGetMaxX(self.voiceBtn.frame),CGRectGetMinY(frame)),frame.size};
    self.slideView.frame = orgFrame;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.slideView.frame = frame;
    } completion:NULL];
}

- (void)showRecordImageViewGradient
{
    CABasicAnimation *basicAnimtion = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [basicAnimtion setRepeatCount:1000000];
    [basicAnimtion setDuration:1.0];
    basicAnimtion.autoreverses = YES;
    basicAnimtion.fromValue = [NSNumber numberWithFloat:1.0f];
    basicAnimtion.toValue = [NSNumber numberWithFloat:0.1f];
    [self.recordBtn.layer addAnimation:basicAnimtion forKey:nil];
}

- (void)showRecordImageView
{
    self.recordBtn.alpha = 1.0;
    self.recordBtn.hidden = NO;
    CGRect frame = self.recordBtn.frame;
    CGRect orgFrame = CGRectMake(CGRectGetMinX(self.voiceBtn.frame), frame.origin.y, frame.size.width, frame.size.height);
    self.recordBtn.frame = orgFrame;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.recordBtn.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            
        }
    }];
}

- (void)endRecord
{
    self.textView.hidden = NO;
    self.isCanceling = NO;
    self.canCancelAnimation = NO;
    [self invalidateCountTimer];
    
    if (_recordBtn) {
        [self.recordBtn.layer removeAllAnimations];
        [self.recordBtn removeFromSuperview];
         self.recordBtn = nil;
    }
    
    if (_slideView) {
        [self.slideView removeFromSuperview];
        self.slideView = nil;
    }
    
    if (_timeLabel) {
        [self.timeLabel removeFromSuperview];
        self.timeLabel = nil;
    }
    
    if (_garbageImageView) {
        [self.garbageImageView removeFromSuperview];
        self.garbageImageView = nil;
    }
    
    [self.voiceBtn addTarget:self action:@selector(beginRecord:forEvent:) forControlEvents:UIControlEventTouchDown];
    [self.voiceBtn addTarget:self action:@selector(mayCancelRecord:forEvent:) forControlEvents:UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
    [self.voiceBtn addTarget:self action:@selector(finishedRecord:forEvent:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    CGRect frame = self.shareBtn.frame;
    CGFloat offset = self.textView.frame.origin.x - frame.origin.x;
    frame.origin.x -= 100;
    [self.shareBtn setFrame:frame];
    self.shareBtn.hidden = NO;
    
    CGRect frame2 = self.emotionBtn.frame;
    frame2.origin.x -= 100;
    [self.emotionBtn setFrame:frame2];
    self.emotionBtn.hidden = NO;
    
    CGFloat textFieldMaxX = CGRectGetMaxX(self.textView.frame);
    self.textView.hidden = NO;
    frame = self.textView.frame;
    frame.origin.x = self.shareBtn.frame.origin.x + offset;
    frame.size.width = textFieldMaxX - frame.origin.x;
    [self.textView setFrame:frame];
    
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect nframe = self.shareBtn.frame;
        nframe.origin.x += 100;
        [self.shareBtn setFrame:nframe];
        CGRect lframe = self.emotionBtn.frame;
        lframe.origin.x += 100;
        [self.emotionBtn setFrame:lframe];
        nframe = self.textView.frame;
        nframe.origin.x = self.shareBtn.frame.origin.x + offset;
        nframe.size.width = textFieldMaxX - nframe.origin.x;
        [self.textView setFrame:nframe];
    }];
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(43, 0, 81, 45)];
        _timeLabel.textColor = [UIColor blackColor];
        _timeLabel.font = [UIFont systemFontOfSize:17.0f];
        [self addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (FBShimmeringView *)slideView
{
    if (!_slideView) {
        _slideView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(90, self.textView.frame.origin.y, 120, self.textView.frame.size.height)];
        GRUCSlideView *contentView = [[GRUCSlideView alloc] initWithFrame:_slideView.bounds];
        _slideView.contentView = contentView;
        [self addSubview:_slideView];
        
        _slideView.shimmeringDirection = FBShimmerDirectionLeft;
        _slideView.shimmeringSpeed = 60.0f;
        _slideView.shimmeringHighlightWidth = 0.29f;
        _slideView.shimmering = YES;
    }
    
    return _slideView;
}

- (UIButton *)recordBtn
{
    if (!_recordBtn) {
        _recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_recordBtn setImage:[UIImage imageNamed:@"MicRecBtn"] forState:UIControlStateNormal];
        CGRect frame = self.shareBtn.frame;
        [_recordBtn setFrame:frame];
        [_recordBtn setTintColor:[UIColor redColor]];
        [self addSubview:_recordBtn];
    }
    
    return _recordBtn;
}


-(void)sendShareMsg:(id)sender
{
    UIActionSheet *alertView = [[UIActionSheet alloc] initWithTitle:Nil delegate:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"摄影",@"选择图片",@"选择视频",@"共享位置",@"共享联系人", nil];
    [alertView showInView:self];
}

- (void)showInView:(UIView *)view
{
    if (view) {
        CGRect frame = self.frame;
        frame.origin.x = 0;
        frame.origin.y = view.frame.size.height - INPUT_HEIGHT;
        @weakify(self);
        [self gruc_subscribeKeyboardWithAnimations:^(CGRect keyboardRect, CGFloat keyboardOffset, NSTimeInterval duration, BOOL isShowing) {
            @strongify(self);
            _yOffset += keyboardOffset;
             CGRect rect = self.frame;
             rect.origin.y += keyboardOffset;
             strong_self.frame = rect;
            if (strong_self.keyboardAnimations) {
                strong_self.keyboardAnimations(keyboardRect,keyboardOffset,duration,isShowing);
            }
            if (!isShowing && self.text.length == 0) {
                self.frame = CGRectMake(0, _keyboardOriginY - INPUT_HEIGHT + _yOffset, kScreenWidth, INPUT_HEIGHT);
                CGFloat hight = self.frame.size.height - 2*topMagin;
                self.textView.frame = CGRectMake(_textView.frame.origin.x, topMagin, _textView.frame.size.width,  hight);
                [self setNeedsLayout];
                [self layoutIfNeeded];
            }
        } completion:^(BOOL finished) {
            @strongify(self);
            if (strong_self.completionAnimations) {
                strong_self.completionAnimations(finished);
            }
        }];
        [self setFrame:frame];
        self.backgroundColor = [UIColor grayColor];
        self.lrect = self.frame;
        [view addSubview:self];
    }
}
-(void)grucHandleUpdateChatPanelViewWithKeyboardAnimationsAndFrame:(GRUCChatPanelViewWithKeyboardAnimationsChangeFrameBlock)animations completion:(GRUCChatPanelViewCompletionAnimationsBlock)completion{
    self.keyboardAnimations = animations;
    self.completionAnimations = completion;
    
}

- (void)didBeginRecord
{
    self.canCancelAnimation = YES;
    [self startCountTimer];
    [self showRecordImageViewGradient];
}

- (NSTimer *)countTimer
{
    if (!_countTimer) {
        _countTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateRecordTime:) userInfo:nil repeats:YES];
    }
    return _countTimer;
}

- (void)invalidateCountTimer
{
    self.currentSeconds = 0;
    [_countTimer invalidate];
    self.countTimer = nil;
}

- (void)startCountTimer
{
    self.currentSeconds = 0;
    [[NSRunLoop currentRunLoop] addTimer:self.countTimer forMode:NSRunLoopCommonModes];
    [self.countTimer fire];
}

- (void)updateRecordTime:(NSTimer *)timer
{
    self.currentSeconds++;
    NSUInteger sec = self.currentSeconds % 60;
    NSString *secondStr = nil;
    if (sec < 10) {
        secondStr = [NSString stringWithFormat:@"0%lu",(unsigned long)sec];
    }
    else{
        secondStr = [NSString stringWithFormat:@"%lu",(unsigned long)sec];
    }
    NSString *mims = [NSString stringWithFormat:@"%lu",self.currentSeconds / (unsigned long)60];
    self.timeLabel.text = [NSString stringWithFormat:@"%@:%@",mims,secondStr];
}

#pragma mark-- UITextViewDelegate
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if (textView.text.length >0) {
        self.voiceBtn.enabled = NO;
    }else if(textView.text.length ==0 || textView.text.hash == @"".hash){
        self.voiceBtn.enabled = YES;
    }
    return YES;
 }
-(BOOL)textViewShouldEndEditing:(UITextView *)textView{
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView{

    
}

-(void)textViewDidEndEditing:(UITextView *)textView{
    
     self.text = textView.text;
     self.voiceBtn.enabled = YES;
    [textView resignFirstResponder];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatPanelViewSendText:andText:)]) {
            
            [self.delegate chatPanelViewSendText:self andText:textView.text];
        }
        textView.text = nil;
        self.text = nil;
        self.frame = CGRectMake(0, _keyboardOriginY - INPUT_HEIGHT + _yOffset, kScreenWidth, INPUT_HEIGHT);
        CGFloat hight = self.frame.size.height - 2*topMagin;
        textView.frame = CGRectMake(textView.frame.origin.x, topMagin, textView.frame.size.width,  hight);
        [self setNeedsLayout];
        [self layoutIfNeeded];
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatPanelViewUpdateFrame:andFrame:)]) {
            [self.delegate chatPanelViewUpdateFrame:self andFrame:self.frame];
        }
        self.voiceBtn.enabled = YES;
        return NO;
    }
    return YES;
}
-(void)textViewDidChange:(UITextView *)textView{

    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (textView.text.length>0) {
            self.voiceBtn.enabled =NO;
        }else if (textView.text.length == 0 ||textView.text.hash == @"".hash){
            self.voiceBtn.enabled =YES;
        }
        
        CGFloat height = [self textHeightForText:textView.text InTextView:textView];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.15];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        if ( height <= kHeight_TextView) {
        
            self.frame = CGRectMake(0, _keyboardOriginY - INPUT_HEIGHT + _yOffset, kScreenWidth, INPUT_HEIGHT);
            CGFloat hight = self.frame.size.height - 2*topMagin;
            textView.frame = CGRectMake(textView.frame.origin.x, topMagin, textView.frame.size.width,  hight);
            if (!CGRectEqualToRect(self.lrect, self.frame)) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatPanelViewUpdateFrame:andFrame:)]) {
                    [self.delegate chatPanelViewUpdateFrame:self andFrame:self.frame];
                }
            }
            
            _textView.frame = textView.frame;
        }else if (height >= 88.0f && self.frame.size.height <=100.0f){
            CGRect txtViewRect = textView.frame;
            
            self.frame = CGRectMake(self.frame.origin.x, _keyboardOriginY - 100.0f + _yOffset , kScreenWidth, 100.0f);
            
            _textView.frame = CGRectMake(txtViewRect.origin.x, topMagin, txtViewRect.size.width, 83.5f);
            if (!CGRectEqualToRect(self.lrect, self.frame)) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatPanelViewUpdateFrame:andFrame:)]) {
                    [self.delegate chatPanelViewUpdateFrame:self andFrame:self.frame ];
                }
            }
        }else if (height>kHeight_TextView && height < 88.0f){
            CGRect txtViewRect = textView.frame;
            CGFloat l_hoffset = height - INPUT_HEIGHT ;
        
            self.frame = CGRectMake(0, _keyboardOriginY - INPUT_HEIGHT - fabs(l_hoffset)+ _yOffset - 10.5f, kScreenWidth,  INPUT_HEIGHT+fabs(l_hoffset)+10.5f);
          
   
            CGFloat hight = self.frame.size.height - 2*topMagin;
            txtViewRect = CGRectMake(txtViewRect.origin.x,topMagin, txtViewRect.size.width, hight);
            _textView.frame = txtViewRect;
           
            if (!CGRectEqualToRect(self.lrect, self.frame)) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatPanelViewUpdateFrame:andFrame:)]) {
                    [self.delegate chatPanelViewUpdateFrame:self andFrame:self.frame];
                }
            }
        }
        
        [self.textView setNeedsDisplay];
         self.lrect = self.frame;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        [UIView commitAnimations];
        
    });
   
}
-(void)textViewDidChangeSelection:(UITextView *)textView{
    
}


- (CGSize)textSizeForText:(NSString *)txt
{
    CGFloat fbase = 8.0;
    CGSize constraint = CGSizeMake(_textView.contentSize.width - fbase, MAXFLOAT);
    NSDictionary *attribute = @{NSFontAttributeName: self.textView.font};
    
    return [txt boundingRectWithSize:constraint options:NSLineBreakByWordWrapping attributes:attribute context:nil].size;
}
- (CGFloat)textHeightForText:(NSString *)txt InTextView:(UITextView *)txtView{
    CGFloat fbase = 8.0f;
    CGSize constraint = CGSizeMake(txtView.contentSize.width - fbase, MAXFLOAT);
    NSDictionary *attribute = @{NSFontAttributeName: txtView.font};

    CGSize size = [txt boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil].size;

    NSString *str = [NSString stringWithFormat:@"%@",txtView.font];
    CGFloat fHeight = size.height + [str integerValue] * 0.95f ;
  
    if (fHeight < kHeight_TextView) {
        return kHeight_TextView;
    }
    return fHeight;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    self.shareBtn.frame = CGRectMake(self.shareBtn.frame.origin.x, (self.frame.size.height - self.shareBtn.frame.size.height)/2, CGRectGetWidth(self.shareBtn.frame), CGRectGetHeight(self.shareBtn.frame));
    self.emotionBtn.frame= CGRectMake(self.emotionBtn.frame.origin.x, (self.frame.size.height - self.emotionBtn.frame.size.height)/2, CGRectGetWidth(self.emotionBtn.frame), CGRectGetHeight(self.emotionBtn.frame));
    self.voiceBtn.frame= CGRectMake(self.voiceBtn.frame.origin.x, (self.frame.size.height - self.voiceBtn.frame.size.height)/2, CGRectGetWidth(self.voiceBtn.frame), CGRectGetHeight(self.voiceBtn.frame));
   
}

@end
