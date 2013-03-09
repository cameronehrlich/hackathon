    //
    //  ADAudioModel.m
    //  Acoustic Detection
    //
    //  Created by Cameron Ehrlich on 3/8/13.
    //  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
    //

#import "ADAudioModel.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "Convolver.h"
#include <stdio.h>

const Float64 kSampleRate = 44100.0;
const NSUInteger kBufferByteSize = 2048 * 4;

@implementation ADAudioModel{
    
    AudioQueueRef inputQueue;
    AudioQueueRef outputQueue;
    
    AudioQueueBufferRef constBuffer;
    
    	// Note player
	double noteFrequency;
	double noteAmplitude;
	double noteDecay;
	int noteFrame;
	NSLock *noteLock;
    
    Convolver *convolver;
    
    int countDown;
    Float32* calibration; 

}

@synthesize isCalibrating;
@synthesize parent;


- (id)init
{
    self = [super init];
    if (self) {
        
        bool suc = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        NSLog(@"AV Session created? : %d", suc);

        convolver = [[Convolver alloc] init];
        
        isCalibrating = NO;
        
        countDown = 0;        
        [self startInputAudioQueue];
//        [self startOutputAudioQueue];
        
    }
    return self;
}



-(void)log:(NSString*)str{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"log" object:str];
    });
}


-(void)beginCalibrating{
    [self log:@"Ready to Calibrate..."];
    isCalibrating = YES;
}

- (void)startInputAudioQueue {
    OSStatus err;
    
        //Input
    
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
    
    err = AudioQueueNewInput (&streamFormat, InputBufferCallaback, (__bridge void *)(self), nil, nil, 0, &inputQueue);
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


void InputBufferCallaback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription* inPacketDesc)
{
	[(__bridge ADAudioModel *)inUserData processInputBuffer:inBuffer queue:inAQ];
}

-(void) processInputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue {
        // FInd the peak amplitude.
    
	int count = buffer->mAudioDataByteSize / sizeof (Float32) ;
    
	Float32 *audioData = buffer->mAudioData;
    
    constBuffer = buffer;
	
    Float32 max = 0.0;
	Float32 sampleValue;
	for (int frame = 0; frame < count; frame++) {
		sampleValue = audioData[frame];
        
        
		if (sampleValue < 0.0f){
			sampleValue = -sampleValue;
        }
		
        if (max < sampleValue){
			max = sampleValue;
        }
	}
	
    
        // begin testing
    
    float threshHold = -10.0f;
    
    double db = 20 * log10 (max);
    if (countDown < 0) {
        if (db > threshHold) {
            countDown = 10;
            
            Float32 *blah = calloc(count, sizeof(Float32));
//            Float32 *blah = malloc(count * sizeof(Float32));

            int startingIndex = 0;
            float currentHighest = -100.00;
            
            for(int i = 0; i < count; i++){
                if (fabsf(audioData[i]) > currentHighest ) {
                    currentHighest = fabsf(audioData[i]);
                    startingIndex = i;
                }
            }
            

            [self log:[NSString stringWithFormat:@"count: %d, starting: %d",count, startingIndex]];
//
//            if (startingIndex > 2* (count/3) ) {
//                NSLog(@"Cancelled.  Insufficient buffer length");
//                countDown = 0;
//                return;
//            }
            
            
            int index = 0;
            for (int i = startingIndex; i < count; i++) {
                blah[index] = audioData[i] ;
                index++;
            }
            
            
            if (isCalibrating) {
//                [self log:@"calibrating"];
                
                [self calibrate:blah WithCount:count];
            }else{
//                [self log:@"testing"];
               [self test:blah WithCount:count];
            }
        }
    }else{
        countDown--;
    }

    
    OSStatus err = AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
	if (err != noErr)
		NSLog(@"AudioQueueEnqueueBuffer() error %ld", err);
}

-(void)test:(Float32*)buff WithCount:(int)count{
    
    float avgC = 0;
    float avgB = 0;
    if (calibration != nil) {
        for (int i = 0; i< count; i++) {
            if (i < 11) {
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


#pragma mark Output

void OutputBufferCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	[(__bridge ADAudioModel *)inUserData processOutputBuffer:inBuffer queue:inAQ];
}

- (void)startOutputAudioQueue {
	OSStatus err;
	int i;
	
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
    
        // New output queue ---- PLAYBACK ----
	err = AudioQueueNewOutput (&streamFormat, OutputBufferCallback, (__bridge void *)(self), nil, nil, 0, &outputQueue);
	if (err != noErr) NSLog(@"AudioQueueNewOutput() error: %ld", err);
	
        // Enqueue buffers
	AudioQueueBufferRef buffer;
	for (i=0; i<3; i++) {
		err = AudioQueueAllocateBuffer (outputQueue, kBufferByteSize, &buffer);
		if (err == noErr) {
//            [self generateTone: buffer];
            
			err = AudioQueueEnqueueBuffer (outputQueue, buffer, 0, nil);
			if (err != noErr) NSLog(@"AudioQueueEnqueueBuffer() error: %ld", err);
		} else {
			NSLog(@"AudioQueueAllocateBuffer() error: %ld", err);
			return;
		}
	}
    
        // Start queue
	err = AudioQueueStart(outputQueue, nil);
	if (err != noErr) NSLog(@"AudioQueueStart() error: %ld", err);
}

- (void) processOutputBuffer: (AudioQueueBufferRef) buffer queue:(AudioQueueRef) queue {
        // Fill buffer.
	[self generateTone: buffer];
	
        //    buffer = constBuffer;
    
        // Re-enqueue buffer.
	OSStatus err = AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
	if (err != noErr)
		NSLog(@"AudioQueueEnqueueBuffer() error %ld", err);
}

- (void) generateTone: (AudioQueueBufferRef) buffer {
	
	if (constBuffer == nil) {
            // Skip rendering audio if the amplitude is zero.
		memset(buffer->mAudioData, 0, buffer->mAudioDataBytesCapacity);
        buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
	} else {
        
        int frame, count = buffer->mAudioDataBytesCapacity / sizeof (Float32);
        
        Float32 *audioData = buffer->mAudioData;
        Float32 *constBufferRef = constBuffer->mAudioData;
        
        for (frame = 0; frame < count; frame++) {
            
            audioData[frame] = constBufferRef[frame];
        }
        
	}
	
        // Don't forget to set the actual size of the data in the buffer.
	buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
}


- (void)cleanUp {
	OSStatus err;
	
	err = AudioQueueDispose (inputQueue, YES); // Also disposes of its buffers
	if (err != noErr) NSLog(@"AudioQueueDispose() error: %ld", err);
	inputQueue = nil;
	
    err = AudioQueueDispose (outputQueue, NO); // Also disposes of its buffers
	if (err != noErr) NSLog(@"AudioQueueDispose() error: %ld", err);
	outputQueue = nil;
}


@end
