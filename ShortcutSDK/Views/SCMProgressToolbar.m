//
//  SCMProgressToolbar.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/25/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMProgressToolbar.h"
#import "SCMLocalization.h"


@interface SCMProgressToolbar ()

@property (nonatomic, strong, readwrite) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


@implementation SCMProgressToolbar

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.cancelButton setTitle:[SCMLocalization translationFor:@"SkipButtonTitle" withDefaultValue:@"Skip"] forState:UIControlStateNormal];
    self.statusLabel.text = [SCMLocalization translationFor:@"ProcessingTitle" withDefaultValue:@"Processing…"];
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)setAnimating:(BOOL)value {
    _animating = value;

    if (_animating) {
        self.statusLabel.hidden = NO;
        [self.activityIndicator startAnimating];
    } else {
        self.statusLabel.hidden = YES;
        [self.activityIndicator stopAnimating];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // The width of the button is 16 pixels wider than the text label. This is 4.0 for the edge insets + 12.0 for the rounded edges.
    CGFloat buttonEdgeInset = 16.0;
    CGFloat cancelButtonX = CGRectGetMinX(self.cancelButton.frame);
    CGFloat maxCancelButtonX = CGRectGetMinX(self.activityIndicator.frame) - 8.0;
    NSString *cancelButtonTitle = [self.cancelButton titleForState:UIControlStateNormal];

    CGSize constraintSize = CGSizeMake(maxCancelButtonX - cancelButtonX - buttonEdgeInset, CGFLOAT_MAX);
    CGSize cancelTitleSize = [cancelButtonTitle boundingRectWithSize:constraintSize
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName: self.cancelButton.titleLabel.font}
                                                             context:nil].size;

    self.cancelButton.frame = CGRectMake(cancelButtonX, CGRectGetMinY(self.cancelButton.frame),
            cancelTitleSize.width + buttonEdgeInset, CGRectGetHeight(self.cancelButton.frame));

    CGFloat statusLabelX = CGRectGetMaxX(self.cancelButton.frame) + 8.0;
    CGFloat statusLabelWidth = CGRectGetMinX(self.activityIndicator.frame) - 8.0 - statusLabelX;
    self.statusLabel.frame = CGRectMake(statusLabelX, CGRectGetMinY(self.statusLabel.frame), statusLabelWidth, CGRectGetHeight(self.statusLabel.frame));
}


@end
