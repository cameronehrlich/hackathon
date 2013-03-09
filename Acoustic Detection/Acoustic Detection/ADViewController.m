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

@synthesize console;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    model = [[ADAudioModel alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:@"log" object:nil];
    
}

-(void)log:(NSNotification*)notification{
    NSString *str = [notification.object description];
    NSLog(@"%@", str );
    [console setText:[NSString stringWithFormat:@"%@\n\n%@", str, console.text ]];
}

- (IBAction)calibrateButton:(id)sender {
    [model beginCalibrating:[sender tag]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
