//
//  NetworkActivityIndicator.h
//  App Search with Google
//
//  Created by Joel Fischer on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface NetworkActivityIndicator : NSObject

+ (void)incrementActivityCount;
+ (void)decrementActivityCount;

@end
