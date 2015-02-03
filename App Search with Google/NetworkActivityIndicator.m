//
//  NetworkActivityIndicator.m
//  App Search with Google
//
//  Created by Joel Fischer on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "NetworkActivityIndicator.h"

static int count = 0;

@implementation NetworkActivityIndicator

+ (void)incrementActivityCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        count++;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
}

+ (void)decrementActivityCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        count--;
        
        if (count <= 0) {
            count = 0;
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    });
}

@end
