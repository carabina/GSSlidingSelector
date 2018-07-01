/*!
 * \file GSSlideSelectorViewController.m
 * \author Galarius
 * \date 30.06.2018
 * \copyright (c) 2018 galarius. All rights reserved.
 */

#import "GSSlideSelectorViewController.h"
#import "GSSlideSelectorStyle.h"

@interface GSSlideSelectorViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

/*!
 *  \brief ScrollView to slide items horizontally
 */
@property(strong, nonatomic) UIScrollView   *scrollView;
/*!
 *  \brief Array of text fields in scroll view
 */
@property(strong, nonatomic) NSMutableArray *textFields;
/*!
 *  \brief Selected & displayed item
 */
@property(strong, nonatomic) NSString *selectedItem;

@property(nonatomic) BOOL decelerating;

@end

@implementation GSSlideSelectorViewController
{
    struct {
        unsigned int numberOfItems:1;
        unsigned int titleForItem:1;
        unsigned int didSelectItem:1;
    } delegateRespondsTo;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupView];
    [self reloadData];
}

- (void)setDelegate:(id<GSSlideSelectorDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        if(_delegate) {
            delegateRespondsTo.numberOfItems = [self.delegate respondsToSelector:@selector(numberOfItemsInSlideSelector:)];
            delegateRespondsTo.titleForItem = [self.delegate respondsToSelector:@selector(slideSelector:titleForItemAtIndex:)];
            delegateRespondsTo.didSelectItem = [self.delegate respondsToSelector:@selector(slideSelector:didSelectItemAtIndex:)];
        } else {
            delegateRespondsTo.numberOfItems = NO;
            delegateRespondsTo.titleForItem = NO;
            delegateRespondsTo.didSelectItem = NO;
        }
    }
}

- (void)setupView
{
    self.view.backgroundColor = [GSSlideSelectorStyleKit mainColor];
    
    _scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    
    // Configure the press and hold gesture recognizer
    UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc]
                                        initWithTarget:self
                                        action:@selector(holdGesture:)];
    gr.minimumPressDuration = 0.0;
    gr.delegate = self;
    [self.scrollView addGestureRecognizer:gr];
}

- (void)reloadData
{
    if(delegateRespondsTo.numberOfItems && delegateRespondsTo.titleForItem) {
        if(self.textFields.count) {
            // Remove all previously added text fields
            [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self.textFields removeAllObjects];
        }
        // Recreate scroll view content
        NSUInteger count = [self.delegate numberOfItemsInSlideSelector:self];
        self.textFields = [NSMutableArray arrayWithCapacity:count];
        for(int i = 0; i < count; ++i) {
            NSString *title = [self.delegate slideSelector:self titleForItemAtIndex:i];
            UITextField *textField = [GSSlideSelectorStyleKit createTextFieldWithText:title];
            [self.textFields addObject:textField];
            [self.scrollView addSubview:textField];
        }
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = CGRectGetHeight(self.view.frame);
    self.scrollView.frame = CGRectMake(0, 0, w, h);
    
    CGFloat x = 0;
    for(int i = 0; i < self.textFields.count; ++i, x += w) {
        UITextField *tField = [self.textFields objectAtIndex:i];
        tField.frame = CGRectMake(x, 0, w, h);
    }

    self.scrollView.contentSize = CGSizeMake(x, h);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    self.decelerating = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Update selected item
    CGFloat w = CGRectGetWidth(self.scrollView.frame);
    NSUInteger idx = self.scrollView.contentOffset.x / w;
    UITextField* tf = [self.textFields objectAtIndex:idx];
    CGFloat x = CGRectGetMinX(tf.frame);
    CGPoint center = CGPointMake(x, 0.0f);
    // Scroll to selected item
    [self.scrollView setContentOffset:center animated:YES];
    // Notify observer
    if(delegateRespondsTo.didSelectItem) {
        [self.delegate slideSelector:self didSelectItemAtIndex:idx];
    }
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.decelerating = NO;
}

#pragma mark - GestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - GestureRecognizer Action

- (void)holdGesture:(UIGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.scrollView.backgroundColor = [GSSlideSelectorStyleKit holdTouchColor];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            if(!self.decelerating) {
                self.scrollView.backgroundColor = [UIColor clearColor];
            }
            break;
            
        default:
            break;
    }
}

@end