//
//  GoogleAppStoreSearchManager.m
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "GoogleAppStoreSearchManager.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>

#import "GoogleAppResult.h"
#import "GoogleAppStoreSearchManagerDelegate.h"
#import "NetworkActivityIndicator.h"


#ifdef DEBUG
static const int ddLogLevel = DDLogLevelDebug;
#else
static const int ddLogLevel = DDLogLevelError;
#endif


@interface GoogleAppStoreSearchManager ()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSMutableDictionary *tasks;
@property (strong, nonatomic) NSMutableArray *results;

@end



@implementation GoogleAppStoreSearchManager

#pragma mark - Public Methods

- (instancetype)initWithDelegate:(id<GoogleAppStoreSearchManagerDelegate>)delegate {
    self = [super init];
    
    if (self) {
        _tasks = [[NSMutableDictionary alloc] init];
        _results = [[NSMutableArray alloc] init];
        _delegate = delegate;
        
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
    }
    
    return self;
}

- (void)getAppsForSearchTerm:(NSString *)term withScope:(DeviceScope)scope {
    [self invalidateTasks];
    
    NSArray *terms = [term componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *urlString = [GoogleAppStoreSearchManager getUrlWithSearchTerms:terms scope:scope];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    [NetworkActivityIndicator incrementActivityCount];

    [self.webView loadRequest:requestObj];
}


#pragma mark - Private Helpers

- (void)invalidateTasks {
    DDLogInfo(@"Invalidate all google app search tasks");
    [NetworkActivityIndicator decrementActivityCount];
//    [self.webView stopLoading];
    
    if (self.tasks.allKeys.count > 0) {
        DDLogDebug(@"Invalidating %@ tasks", @(self.tasks.allKeys.count));
        
        for (NSURLSessionDataTask *task in self.tasks.allKeys) {
            [NetworkActivityIndicator decrementActivityCount];
            [task cancel];
        }
    }
    
    self.results = [NSMutableArray array];
}

+ (NSString *)getUrlWithSearchTerms:(NSArray *)terms scope:(DeviceScope)scope {
    
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:@"https://www.google.com/webhp?ion=1&espv=2&ie=UTF-8#safe=active&q=site:itunes.apple.com"];

    for (NSString *term in terms) {
        [urlString appendString:@"+"];
        [urlString appendString:term];
    }
    
    NSString *scopeString = nil;
    switch (scope) {
        case DeviceScopeiPad: {
            scopeString = @"ipad";
        } break;
        case DeviceScopeiPhone: {
            scopeString = @"iphone";
        } break;
    }

    [urlString appendString:[NSString stringWithFormat:@"+%@+app", scopeString]];
    
    return urlString;
}

+ (NSString *)getAppIdFromiTunesUrl:(NSString *)urlString {
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSArray *pathComponents = [components.path componentsSeparatedByString:@"/"];
    NSLog(@"%@", pathComponents);
    
    if (![(NSString *)pathComponents[2] isEqualToString:@"app"]) {
        return nil;
    }
    
    NSString *idComponent = pathComponents.lastObject;
    NSString *appId = [idComponent substringFromIndex:2];
    
    return appId;
}

- (NSURLSessionDataTask *)taskForAppDetailsFromItunesForAppId:(NSString *)appId {
    NSParameterAssert(appId != nil);
    
    NSString *url = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@", appId];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSURLSessionDataTask *task = [manager GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *errorMessage = (NSString *)responseObject[@"errorMessage"];
        NSArray *results = (NSArray *)responseObject[@"results"];
        DDLogVerbose(@"App Search Result: %@", results);
        
        if (errorMessage == nil) {
            for (NSDictionary *result in results) {
                NSString *title = (NSString *)result[@"trackName"];
                NSNumber *ratingCount = (NSNumber *)result[@"userRatingCount"];
                NSNumber *rating = (NSNumber *)result[@"averageUserRating"];
                NSString *itunesUrl = (NSString *)result[@"trackViewUrl"];
                NSNumber *price = (NSNumber *)result[@"price"];
                DDLogDebug(@"App Search Result:\n"
                           "Title: %@\n"
                           "Rating: %@\n"
                           "Rating Count: %@\n"
                           "iTunes URL: %@\n"
                           "Price: %@\n"
                           "Rank: %@\n", title, ratingCount, rating, itunesUrl, price, self.tasks[task]);
                
                GoogleAppResult *appResult = [[GoogleAppResult alloc] initWithId:appId url:itunesUrl name:title ratingCount:ratingCount rating:rating price:price rank:self.tasks[task]];
                [self.results addObject:appResult];
            }
        }
        
        [self.tasks removeObjectForKey:task];
        [NetworkActivityIndicator decrementActivityCount];
        
        if (self.tasks.count == 0) {
            [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:self.results]];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DDLogWarn(@"ITunes request failed with error: %@", error);
        [self.tasks removeObjectForKey:task];
        [NetworkActivityIndicator decrementActivityCount];
        
        // TODO: This is wrong
        if (self.tasks.count == 0) {
            [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:self.results]];
        }
    }];
    
    return task;
}


#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // The request finished, so decrement
    [NetworkActivityIndicator decrementActivityCount];
    
    NSInteger rank = 0;
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:
                      @"document.body.innerHTML"];
    NSError *err = nil;
    ONOXMLDocument *doc = [ONOXMLDocument HTMLDocumentWithString:html encoding:NSUTF8StringEncoding error:&err];
    
    for (ONOXMLElement *element in [doc CSS:@"h3.r a"]) {
        NSString *appId = [GoogleAppStoreSearchManager getAppIdFromiTunesUrl:element.attributes[@"href"]];
        if (appId != nil) {
            NSURLSessionDataTask *task = [self taskForAppDetailsFromItunesForAppId:appId];
            
            [NetworkActivityIndicator incrementActivityCount];
            [self.tasks setObject:@(rank++) forKey:task];
            [task resume];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogWarn(@"WebView request did fail load");
    [self.delegate appSearchDidFailWithError:error];
}

@end
