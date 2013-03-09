//
//  ADAudioModel.h
//  Acoustic Detection
//
//  Created by Cameron Ehrlich on 3/8/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface ADAudioModel : NSObject

@property (assign) BOOL isCalibrating;
@property (nonatomic, strong) UIViewController *parent;
- (void) processInputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue;
- (void) processOutputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue;

-(void)beginCalibrating;

@end
