//
//  GoogleAppStoreSearchManager.h
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
#import "GoogleAppResult.h"
#import "GoogleAppStoreSearchManagerDelegate.h"

typedef NS_ENUM(NSUInteger, DeviceScope) {
    DeviceScopeiPad,
    DeviceScopeiPhone
};

@interface GoogleAppStoreSearchManager : NSObject <UIWebViewDelegate>
@property (strong, nonatomic) id<GoogleAppStoreSearchManagerDelegate> delegate;

- (void)getAppsForSearchTerms:(NSArray *)terms withScope:(DeviceScope)scope;

- (instancetype)initWithDelegate:(id<GoogleAppStoreSearchManagerDelegate>)delegate;

@end
