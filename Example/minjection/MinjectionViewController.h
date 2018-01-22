//
//  MinjectionViewController.h
//  minjection
//
//  Created by undiwahn on 01/21/2018.
//  Copyright (c) 2018 undiwahn. All rights reserved.
//

@import UIKit;
#import "ConfigurationTags.h"

@interface MinjectionViewController : UIViewController

#pragma mark Injected properties

@property (nonatomic, copy) NSString<Title>* titleString;
@property (nonatomic, copy) NSString<Subtitle>* subtitleString;

#pragma mark -

@end
