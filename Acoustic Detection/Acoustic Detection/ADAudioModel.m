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

const Float64 kSampleRate = 44100.0;
const NSUInteger kBufferByteSize = 2048;

@implementation ADAudioModel{
    
@private
	AudioQueueRef inputQueue;
    AudioQueueRef outputQueue;
    
    AudioQueueBufferRef constBuffer;
    
    	// Note player
	double noteFrequency;
	double noteAmplitude;
	double noteDecay;
	int noteFrame;
	NSLock *noteLock;
}


- (id)init
{
    self = [super init];
    if (self) {
        
        bool suc = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        NSLog(@"AV Session created? : %d", suc);
        
        
        OSStatus rc = AudioSessionSetActive(true);
        NSLog(@"Sesssion set active: %ld", rc);

        [self startInputAudioQueue];
        [self startOutputAudioQueue];
        
//        [NSTimer scheduledTimerWithTimeInterval:2.00 target:self selector:@selector(playNote) userInfo:nil repeats:YES];
    }
    return self;
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
	streamFormat.mBytesPerPacket = 4 * streamFormat.mChannelsPerFrame;
	streamFormat.mBytesPerFrame = 4 * streamFormat.mChannelsPerFrame;
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
    
	int count = buffer->mAudioDataByteSize / sizeof (Float32);
    
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
	
   
        // Update level meter on main thread
    double db = 20 * log10 (max);
    if (db > -27.0f) {
        [self playNote];
       NSLog(@"%f", db);
    }
    
    OSStatus err = AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
	if (err != noErr)
		NSLog(@"AudioQueueEnqueueBuffer() error %ld", err);
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
//			buffer = constBuffer;
            [self generateTone: buffer];

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
	[noteLock lock];
	
	if (noteAmplitude == 0.0) {
            // Skip rendering audio if the amplitude is zero.
		memset(buffer->mAudioData, 0, buffer->mAudioDataBytesCapacity);
	} else {
            // Generate a sine wave.
		int frame, count = buffer->mAudioDataBytesCapacity / sizeof (Float32);
		Float32 *audioData = buffer->mAudioData;
		double x, y;
		
		for (frame = 0; frame < count; frame++) {
			x = noteFrame * noteFrequency / kSampleRate;
			y = sin (x * 2.0 * M_PI) * noteAmplitude;
			audioData[frame] = y;
			
                // Advance counters
			noteAmplitude -= noteDecay;
			if (noteAmplitude < 0.0)
				noteAmplitude = 0.0;
			noteFrame++;
		}
	}
	
        // Don't forget to set the actual size of the data in the buffer.
	buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
	
	[noteLock unlock];
}

- (void)playNote {
//	double tag = [sender tag];
	[noteLock lock];
	noteFrame = 0;
	noteFrequency = 4000 / 10.0;
	noteAmplitude = 4.0;
	noteDecay = 2.0 / 44100.0;
	[noteLock unlock];
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
