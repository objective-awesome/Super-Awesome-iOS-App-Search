//
//  GoogleAppResult.m
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "GoogleAppResult.h"

@interface GoogleAppResult ()
@property (nonatomic, strong, readwrite) NSString *url;
@property (nonatomic, strong, readwrite) NSString *name;
@end

@implementation GoogleAppResult
- (instancetype) initWithUrl:(NSString *)url name:(NSString *)name
{
    self = [super init];
    if (self) {
        _url = url;
        _name = name;
    }
    return self;
}
@end
