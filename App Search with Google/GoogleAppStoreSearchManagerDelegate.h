//
//  GoogleAppStoreSearchManagerDelegate.h
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GoogleAppStoreSearchManagerDelegate <NSObject>

- (void)didReceiveAppStoreSearchResults:(NSArray *)apps;
- (void)searchFailedWithError:(NSError *)error;

@end
