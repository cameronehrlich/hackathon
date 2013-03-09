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

- (void) processInputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue;
- (void) beginCalibrating;

@end
