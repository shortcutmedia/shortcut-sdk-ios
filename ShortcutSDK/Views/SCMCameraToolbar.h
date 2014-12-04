//
//  SCMCameraToolbar.h
//  Shortcut
//
//  Created by David Wisti on 3/25/12.
//  Copyright (c) 2012 kooaba AG. All rights reserved.
//

#import "SCMCustomToolbar.h"


@interface SCMCameraToolbar : SCMCustomToolbar

@property (nonatomic, strong, readonly) IBOutlet UIButton* doneButton;
@property (nonatomic, strong, readonly) IBOutlet UIButton* cameraButton;
@property (nonatomic, strong, readonly) IBOutlet UIButton* modeButton;

@end
