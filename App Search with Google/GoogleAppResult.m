//
//  GoogleAppResult.m
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "GoogleAppResult.h"



@interface GoogleAppResult ()

@property (nonatomic, strong, readwrite) NSString *iTunesId;
@property (nonatomic, strong, readwrite) NSString *url;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSNumber *ratingCount;
@property (nonatomic, strong, readwrite) NSNumber *rating;
@property (nonatomic, strong, readwrite) NSNumber *price;
@property (nonatomic, strong, readwrite) NSNumber *rank;

@end



@implementation GoogleAppResult

- (instancetype)initWithId:(NSString *)iTunesId url:(NSString *)url name:(NSString *)name ratingCount:(NSNumber *)count rating:(NSNumber *)rating price:(NSNumber *)price rank:(NSNumber *)rank
{
    self = [super init];
    if (self) {
        _iTunesId = iTunesId;
        _url = url;
        _name = name;
        _ratingCount = count;
        _price = price;
        _rating = rating;
        _rank = rank;
    }
    return self;
}

@end
