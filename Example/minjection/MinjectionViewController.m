//
//  MinjectionViewController.m
//  minjection
//
//  Created by undiwahn on 01/21/2018.
//  Copyright (c) 2018 undiwahn. All rights reserved.
//

#import "MinjectionViewController.h"

@interface MinjectionViewController ()
{
    
}

@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet UILabel* subtitleLabel;

@end

@implementation MinjectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _titleLabel.text = _titleString;
    _subtitleLabel.text = _subtitleString;
}

@end
