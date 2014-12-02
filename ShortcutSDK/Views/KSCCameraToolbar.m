//
//  KSCCameraToolbar.m
//  Shortcut
//
//  Created by David Wisti on 3/25/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "KSCCameraToolbar.h"
#import "KSCLocalization.h"


@interface KSCCameraToolbar (/* Private */)

@property (nonatomic, strong, readwrite) IBOutlet UIButton* doneButton;
@property (nonatomic, strong, readwrite) IBOutlet UIButton* cameraButton;
@property (nonatomic, strong, readwrite) IBOutlet UIButton* modeButton;

@end


@implementation KSCCameraToolbar

@synthesize doneButton;
@synthesize cameraButton;
@synthesize modeButton;

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.doneButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, 4.0);
	[self.doneButton setTitle:[KSCLocalization translationFor:@"DoneButtonTitle" withDefaultValue:@"Done"]
                     forState:UIControlStateNormal];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// The width of the button is 16 pixels wider than the text label. This is 4.0 for the edge insets + 12.0 for the rounded edges.
	CGFloat buttonEdgeInset = 16.0;
	CGFloat cancelButtonX = CGRectGetMinX(self.doneButton.frame);
	CGFloat maxCancelButtonX = CGRectGetMinX(self.cameraButton.frame) - 8.0;
	NSString* cancelButtonTitle = [self.doneButton titleForState:UIControlStateNormal];
	CGSize cancelTitleSize = [cancelButtonTitle sizeWithFont:self.doneButton.titleLabel.font
																									forWidth:maxCancelButtonX - cancelButtonX - buttonEdgeInset
																						 lineBreakMode:NSLineBreakByTruncatingTail];
	self.doneButton.frame = CGRectMake(cancelButtonX, CGRectGetMinY(self.doneButton.frame),
																			 cancelTitleSize.width + buttonEdgeInset, CGRectGetHeight(self.doneButton.frame));
}

@end
