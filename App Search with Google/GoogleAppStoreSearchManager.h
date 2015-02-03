//
//  GoogleAppStoreSearchManager.h
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

#import "Constants.h"


@protocol GoogleAppStoreSearchManagerDelegate;


@interface GoogleAppStoreSearchManager : NSObject <UIWebViewDelegate>

@property (strong, nonatomic) id<GoogleAppStoreSearchManagerDelegate> delegate;

- (instancetype)initWithDelegate:(id<GoogleAppStoreSearchManagerDelegate>)delegate;

/**
 *  Request that the manager start to search for results.
 *
 *  @note This will return results to the delegate
 *
 *  @param term  The string to be searched
 *  @param scope The scope of the search, iPhone or iPad
 */
- (void)getAppsForSearchTerm:(NSString *)term withScope:(DeviceScope)scope;

@end
