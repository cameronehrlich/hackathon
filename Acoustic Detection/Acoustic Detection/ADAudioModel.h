//
//  ADAudioModel.h
//  Acoustic Detection
//
//  Created by Cameron Ehrlich on 3/8/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


    // Constants
const Float64 kSampleRate = 44100.0;
const NSUInteger kBufferByteSize = 2048;

@interface ADAudioModel : NSObject

- (void) processInputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue;

@end
