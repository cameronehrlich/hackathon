//
//  ADViewController.h
//  Acoustic Detection
//
//  Created by Cameron Ehrlich on 3/8/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>


@interface ADViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *console;

-(IBAction)calibrateButton:(id)sender;
-(void)log:(NSString*)str;

@end
