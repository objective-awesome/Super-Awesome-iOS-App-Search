//
//  UIColor+Utilities.m
//  App Search with Google
//
//  Created by Joel Fischer on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "UIColor+Utilities.h"

@implementation UIColor (Utilities)

+ (UIColor *)colorWithRGBRed:(Byte)red green:(Byte)green blue:(Byte)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((CGFloat)red / 255.0) green:((CGFloat)green / 255.0) blue:((CGFloat)blue / 255.0) alpha:alpha];
}

@end
