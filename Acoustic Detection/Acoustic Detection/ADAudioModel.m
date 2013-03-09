    //
    //  ADAudioModel.m
    //  Acoustic Detection
    //
    //  Created by Cameron Ehrlich on 3/8/13.
    //  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
    //

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#include <stdio.h>
#import <dispatch/dispatch.h>
#import "ADAudioModel.h"
#import "Convolver.h"

const Float64 kSampleRate = 44100.0;
const NSUInteger kBufferByteSize = 2048 * 4;
const float threshHold = -10.0f;

@implementation ADAudioModel{
    
    AudioQueueRef inputQueue;
        
    Convolver *convolver;
    
    int countDown;
    
    Float32* calibration; 
}

@synthesize isCalibrating;

- (id)init
{
    self = [super init];
    if (self) {
        
        bool suc = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [self log:[NSString stringWithFormat:@"AV Session created? : %d", suc]];

        convolver = [[Convolver alloc] init];
        isCalibrating = NO;
        countDown = 0;
        
        [self startInputAudioQueue];
    }
    return self;
}

-(void)beginCalibrating{
    [self log:@"Ready to Calibrate..."];
    isCalibrating = YES;
}

- (void)startInputAudioQueue {
    OSStatus err;
    
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = kSampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat | kAudioFormatFlagsNativeEndian;
	streamFormat.mBitsPerChannel = 32;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBytesPerPacket = 4;
	streamFormat.mBytesPerFrame = 4;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mReserved = 0;
    
    err = AudioQueueNewInput (&streamFormat, InputBufferCallback, (__bridge void *)(self), nil, nil, 0, &inputQueue);
    if (err != noErr) NSLog(@"AudioQueueNewInput() error: %ld", err);
    
    AudioQueueBufferRef buffer;
    
	for (int i=0; i<3; i++) {
		err = AudioQueueAllocateBuffer (inputQueue, kBufferByteSize, &buffer);
		if (err == noErr) {
			err = AudioQueueEnqueueBuffer (inputQueue, buffer, 0, nil);
			if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %ld", err);
		} else {
			NSLog(@"AudioQueueAllocateBuffer() error: %ld", err);
			return;
		}
	}
    err = AudioQueueStart(inputQueue, nil);
	if (err != noErr) NSLog(@"AudioQueueStart() error: %ld", err);
    
}


void InputBufferCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription* inPacketDesc) {
	[(__bridge ADAudioModel *)inUserData processInputBuffer:inBuffer queue:inAQ];
}

-(void) processInputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue {    
	int count = buffer->mAudioDataByteSize / sizeof (Float32) ;
    
	Float32 *audioData = buffer->mAudioData;
    
    
        //determine buffers elegibility
    Float32 max, sampleValue = 0.0;
	for (int frame = 0; frame < count; frame++) {
		sampleValue = audioData[frame];
		if (sampleValue < 0.0f){sampleValue = -sampleValue;}
        if (max < sampleValue){max = sampleValue;}
	}
	double db = 20 * log10 (max);
    
        //begin checking
    if (countDown < 0) {
        if (db > threshHold) {
            countDown = 10;
            
            Float32 *buffData = calloc(count, sizeof(Float32));

            int startingIndex = 0;
            float currentHighest = -100.00;
            
            for(int i = 0; i < count; i++){
                if (fabsf(audioData[i]) > currentHighest ) {
                    currentHighest = fabsf(audioData[i]);
                    startingIndex = i;
                }
            }
            

            [self log:[NSString stringWithFormat:@"count: %d, starting: %d",count, startingIndex]];
            
            
            int index = 0;
            for (int i = startingIndex; i < count; i++) {
                buffData[index] = audioData[i] ;
                index++;
            }
            
            if (isCalibrating) {
                [self calibrate:buffData WithCount:count];
            }else{
               [self test:buffData WithCount:count];
            }
        }
    }else{
        countDown--;
    }

    
    OSStatus err = AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
	if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error %ld", err);
}

-(void)test:(Float32*)buff WithCount:(int)count{
    
    float avgC = 0.0f;
    float avgB = 0.0f;
    
    int avgLimit = 10; //for testing
    
    if (calibration != nil) {
        for (int i = 0; i< count; i++) {
            if (i <= avgLimit) {
                avgC += calibration[i];
                avgB += buff[i];
            }
        }

        [self log:[NSString stringWithFormat:@"Cal : %f, Buff : %f", avgC/10,avgB/10]];
        
        Float32 rating = [convolver convolveVector:buff ofSize:count with:calibration ofSize:count];

        [self log:[NSString stringWithFormat:@"Rating : %f",rating]];
    }

    
    
}

-(void)calibrate:(Float32*)buff WithCount:(int)count{

    calibration = malloc(count*sizeof(Float32));

    memcpy(calibration, buff, count);
    
    [self log:@"Calibrated"];
    
    isCalibrating = NO;
}

-(void)log:(NSString*)str{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"log" object:str];
    });
}


- (void)cleanUp {
	OSStatus err;
	err = AudioQueueDispose (inputQueue, YES);
	if (err != noErr) NSLog(@"AudioQueueDispose() error: %ld", err);
	inputQueue = nil;
	
}


@end
