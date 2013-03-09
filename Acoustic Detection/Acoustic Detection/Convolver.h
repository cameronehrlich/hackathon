//
//  Conolver.h
//  Acoustic Detection
//
//  Created by Brian Freese on 3/9/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Convolver : NSObject
-(Float32) convolveVector: (Float32[])first ofSize:(int)firstSize with:(Float32[])second ofSize:(int)secondSize;
-(Float32) averageVector: (Float32[])tap ofSize:(int)size;
-(Float32) sigmaOf: (Float32[])vector ofSize:(int)size withMean:(Float32)mean;
@end
