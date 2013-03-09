//
//  Conolver.m
//  Acoustic Detection
//
//  Created by Brian Freese on 3/9/13.
//  Copyright (c) 2013 Cameron Ehrlich. All rights reserved.
//

#import "Convolver.h"
#import "Math.h"

/*
#include <Accelerate/Accelerate.h>
#define NF  3
#define NC  (2*NF+1)
 */

@implementation Convolver{
    
}



- (id)init
{
    self = [super init];
    if (self) {
            //      Float32* testa = [self fuzzTestofSize:200];
//        //NSLog(@"fuzzVector[%d] == %f",1,testa[1]);
//Float32* testb = malloc(200*sizeof(Float32));
            //for (int i=0; i<200;i++) {
                //        testb[i]= testa[i]+(arc4random()%30);
                //}
        //[self sigmaOf:testa ofSize:10 withMean:[self averageVector:testa ofSize:10]];
        //[self convolveVector:testa ofSize:200 with:testb ofSize:200];
    }
    return self;
}

-(Float32) convolveVector: (Float32*)first ofSize:(int)firstSize with:(Float32*)second ofSize:(int)secondSize
{

    Float32 rating;
    Float32 firstAverage = [self averageVector:first ofSize:firstSize];
    Float32 secondAverage = [self averageVector:second ofSize:secondSize];
    Float32 firstSigma = [self sigmaOf:first ofSize:firstSize withMean:firstAverage];
    Float32 secondSigma = [self sigmaOf:second ofSize:secondSize withMean:secondAverage];
    Float32 rateSum = 0.0;
    
    int j;
    for (j =0; j<firstSize;j++) {
        if (j > 0 && ((first[j-1] == 0 && first[j] == 0) || (second[j-1] == 0 && second[j]== 0 ))) {
            break;
        }
        rateSum += (first[j]-firstAverage)*(second[j]-secondAverage);
    }
    rating = rateSum/(j*firstSigma*secondSigma);
    NSLog(@"rating for fuzzTest:%f",rating);
    return rating;
}

-(Float32) averageVector: (Float32*)tap ofSize:(int)size {
   
    Float32 sum=0.0;
    Float32 mean;
    Float32 lastValue = 10000;
    int i;
    for(i=0; i<size;i++) {
        if (lastValue == 0 && tap[i] == 0) {
            NSLog(@"completed avg after %d", i);
            break;
        }
        sum += tap[i];
        lastValue = tap[i];
    }
    
    mean = sum/i;
//     NSLog(@"average of array:%f", mean);
    return mean;
}

-(Float32) sigmaOf: (Float32*)vector ofSize:(int)size withMean:(Float32)mean {
    Float32 sigma;
    Float32 sum = 0.0;
    Float32 lastValue = 10000;
    int i;
    for(i=0; i < size; i++) {
        if (lastValue == 0 && vector[i] == 0) {
            NSLog(@"completed sigma after %d", i);
            break;
        }
        sum += powf((vector[i]-mean),2);
        lastValue = vector[i];
    }
    sigma = sqrtf(sum/i);
//    NSLog(@"sigma of array:%f", sigma);
    return sigma;
}

-(Float32*) fuzzTestofSize:(int)length {
    Float32* fuzzVector = malloc(length*sizeof(Float32));
    if (fuzzVector == NULL) {return 0;};
    for (int i = 0; i < length; i++) {
        fuzzVector[i] =  arc4random()%50;
        //NSLog(@"fuzzVector[%d] == %f",i,fuzzVector[i]);
    }
    return fuzzVector;
    
}


@end
