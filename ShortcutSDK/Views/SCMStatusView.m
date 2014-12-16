//
//  SCMCameraStatusView.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/27/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMStatusView.h"


static const CGFloat kVerticalTextMargin = 6.0;
static const CGFloat kHorizontalTextMargin = 12.0;
static const CGFloat kActivityIndicatorMargin = 6.0;

@interface SCMStatusView (/* Private */)

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign, readwrite) BOOL showActivityIndicator;

- (void)setupView;

@end

@implementation SCMStatusView

@synthesize titleLabel;
@synthesize subtitleLabel;
@synthesize activityIndicator;
@synthesize showActivityIndicator;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupView];
}

- (void)setupView
{
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    self.layer.cornerRadius = 8.0;
    self.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.8] CGColor];
    self.layer.borderWidth = 1.0;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    self.titleLabel.shadowColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    self.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    self.titleLabel.numberOfLines = 0;
    [self addSubview:self.titleLabel];
    
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.subtitleLabel.font = [UIFont systemFontOfSize:15.0];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.backgroundColor = [UIColor clearColor];
    self.subtitleLabel.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    self.subtitleLabel.shadowColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    self.subtitleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    self.subtitleLabel.numberOfLines = 0;
    [self addSubview:self.subtitleLabel];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    [self addSubview:self.activityIndicator];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // These two are invariants
    CGFloat bottomY = CGRectGetMaxY(self.frame);
    CGFloat centerX = CGRectGetMidX(self.frame);
    
    [self.activityIndicator sizeToFit];
    
    CGFloat activityIndicatorWidth = 0.0;
    if (self.showActivityIndicator) {
        activityIndicatorWidth = CGRectGetWidth(self.activityIndicator.frame) + kActivityIndicatorMargin;
    }
    
    CGFloat maxTextWidth = CGRectGetWidth(self.superview.bounds) - (2 * kHorizontalTextMargin) - activityIndicatorWidth;
    
    CGSize titleSize = CGSizeMake(0.0, self.titleLabel.font.lineHeight);
    CGSize subtitleSize = CGSizeZero;
    
    if (self.titleLabel.text.length > 0) {
        titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
                                     constrainedToSize:CGSizeMake(maxTextWidth, CGFLOAT_MAX)
                                         lineBreakMode:NSLineBreakByWordWrapping];
    }
    
    if (self.subtitleLabel.text.length > 0) {
        subtitleSize = [self.subtitleLabel.text sizeWithFont:self.subtitleLabel.font
                                           constrainedToSize:CGSizeMake(maxTextWidth, CGFLOAT_MAX)
                                               lineBreakMode:NSLineBreakByWordWrapping];
    }
    
    CGFloat activityHeight = CGRectGetHeight(self.activityIndicator.frame);
    CGFloat textHeight = titleSize.height + subtitleSize.height;
    CGFloat totalHeight = MAX(activityHeight, textHeight) + (2 * kVerticalTextMargin);
    CGFloat textWidth = MAX(titleSize.width, subtitleSize.width);
    CGFloat totalWidth = activityIndicatorWidth + textWidth + (2 * kHorizontalTextMargin);
    CGFloat frameX = floorf(centerX - (totalWidth / 2.0));
    CGFloat frameY = bottomY - totalHeight;
    self.frame = CGRectMake(frameX, frameY, totalWidth, totalHeight);
    
    CGFloat titleX = kHorizontalTextMargin + activityIndicatorWidth;
    CGFloat titleY = kVerticalTextMargin;
    self.titleLabel.frame = CGRectMake(titleX, titleY, textWidth, titleSize.height);
    
    CGFloat subtitleX = kHorizontalTextMargin + activityIndicatorWidth;
    CGFloat subtitleY = CGRectGetMaxY(self.titleLabel.frame);
    self.subtitleLabel.frame = CGRectMake(subtitleX, subtitleY, textWidth, subtitleSize.height);
    
    CGFloat activityY = CGRectGetMidY(self.bounds) - (activityHeight / 2.0);
    self.activityIndicator.frame = CGRectMake(kHorizontalTextMargin, activityY, CGRectGetWidth(self.activityIndicator.frame), activityHeight);
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)setStatusTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    [self setStatusTitle:title subtitle:subtitle showActivityIndicator:NO];
}

- (void)setStatusTitle:(NSString *)title subtitle:(NSString *)subtitle showActivityIndicator:(BOOL)showActivity
{
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    self.showActivityIndicator = showActivity;
    if (self.showActivityIndicator) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self setNeedsLayout];
}

@end
