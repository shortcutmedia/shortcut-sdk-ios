//
//  SCMCameraToolbar.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/25/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "SCMCameraToolbar.h"
#import "SCMLocalization.h"


@interface SCMCameraToolbar (/* Private */)

@property (nonatomic, strong, readwrite) IBOutlet UIButton *doneButton;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *cameraButton;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *modeButton;

@end


@implementation SCMCameraToolbar

@synthesize doneButton;
@synthesize cameraButton;
@synthesize modeButton;

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self.doneButton setTitle:[SCMLocalization translationFor:@"DoneButtonTitle" withDefaultValue:@"Done"]
                     forState:UIControlStateNormal];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// The width of the button is 16 pixels wider than the text label. This is 4.0 for the edge insets + 12.0 for the rounded edges.
	CGFloat buttonEdgeInset = 16.0;
	CGFloat cancelButtonX = CGRectGetMinX(self.doneButton.frame);
	CGFloat maxCancelButtonX = CGRectGetMinX(self.cameraButton.frame) - 8.0;
	NSString *cancelButtonTitle = [self.doneButton titleForState:UIControlStateNormal];
	CGSize cancelTitleSize = [cancelButtonTitle sizeWithFont:self.doneButton.titleLabel.font
																									forWidth:maxCancelButtonX - cancelButtonX - buttonEdgeInset
																						 lineBreakMode:NSLineBreakByTruncatingTail];
	self.doneButton.frame = CGRectMake(cancelButtonX, CGRectGetMinY(self.doneButton.frame),
																			 cancelTitleSize.width + buttonEdgeInset, CGRectGetHeight(self.doneButton.frame));
}

@end
