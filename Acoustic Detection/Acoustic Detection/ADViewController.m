//
//  ADViewController.m
//  Acoustic Detection
//
//  Created by Cameron Ehrlich on 3/8/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import "ADViewController.h"
#import "ADAudioModel.h"

@implementation ADViewController{
    ADAudioModel *model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    model = [[ADAudioModel alloc] init];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
