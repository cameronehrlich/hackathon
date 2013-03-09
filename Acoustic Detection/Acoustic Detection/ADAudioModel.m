//
//  ADAudioModel.m
//  Acoustic Detection
//
//  Created by Cameron Ehrlich on 3/8/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import "ADAudioModel.h"
#import <AudioToolbox/AudioToolbox.h>


@implementation ADAudioModel{
    	// AudioQueue
	AudioQueueRef inputQueue;
//	AudioQueueRef outputQueue;
}


- (id)init
{
    self = [super init];
    if (self) {
        [self startInputAudioQueue];
    }
    return self;
}


#pragma mark Input

void InputBufferCallaback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription* inPacketDesc)
{
	[(__bridge ADAudioModel *)inUserData processInputBuffer:inBuffer queue:inAQ];
    
    NSLog(@"CALLABACK");
}

- (void)startInputAudioQueue {
	OSStatus err;
	int i;
    
    NSLog(@"Start input audio queue");
	
        // Set up stream format fields
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = kSampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat | kAudioFormatFlagsNativeEndian;
	streamFormat.mBitsPerChannel = 32;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBytesPerPacket = 4 * streamFormat.mChannelsPerFrame;
	streamFormat.mBytesPerFrame = 4 * streamFormat.mChannelsPerFrame;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mReserved = 0;
	
        // New input queue
	err = AudioQueueNewInput (&streamFormat, InputBufferCallaback, (__bridge void *)(self), nil, nil, 0, &inputQueue);
    
	if (err != noErr) NSLog(@"AudioQueueNewInput() error: %ld", err);
	
        // Enqueue buffers
	AudioQueueBufferRef buffer;
	for (i=0; i<3; i++) {
		err = AudioQueueAllocateBuffer (inputQueue, kBufferByteSize, &buffer);
		if (err == noErr) {
			err = AudioQueueEnqueueBuffer (inputQueue, buffer, 0, nil);
			if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %ld", err);
		} else {
			NSLog(@"AudioQueueAllocateBuffer() error: %ld", err);
			return;
		}
	}
	
        // Start queue
	err = AudioQueueStart(inputQueue, nil);
	if (err != noErr) NSLog(@"AudioQueueStart() error: %ld", err);
    
}

-(void) processInputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue {
        // FInd the peak amplitude.
    
    NSLog(@"Start input audio queue");
    
	int frame, count = buffer->mAudioDataByteSize / sizeof (Float32);
	Float32 *audioData = buffer->mAudioData;
	Float32 max = 0.0;
	Float32 sampleValue;
	for (frame = 0; frame < count; frame++) {
		sampleValue = audioData[frame];
		if (sampleValue < 0.0f)
			sampleValue = -sampleValue;
		if (max < sampleValue)
			max = sampleValue;
	}
	
        // Update level meter on main thread
	double db = 20 * log10 (max);
	NSNumber *peakAmplitudeNumber = [[NSNumber alloc] initWithDouble:db];
    NSLog(@"%d",[peakAmplitudeNumber intValue]);
    
    OSStatus err = AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
	if (err != noErr)
		NSLog(@"AudioQueueEnqueueBuffer() error %ld", err);
}


- (void)cleanUp {
	OSStatus err;
	
	err = AudioQueueDispose (inputQueue, YES); // Also disposes of its buffers
	if (err != noErr) NSLog(@"AudioQueueDispose() error: %ld", err);
	inputQueue = nil;
	
}


@end
