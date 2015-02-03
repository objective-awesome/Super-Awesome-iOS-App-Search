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
    NSArray *terms = [term componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *urlString = [GoogleAppStoreSearchManager getUrlWithSearchTerms:terms scope:scope];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    [NetworkActivityIndicator incrementActivityCount];

    [self.webView loadRequest:requestObj];
}

#pragma mark - Private Helpers

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
    NSString *idComponent = pathComponents.lastObject;
    NSString *appId = [idComponent substringFromIndex:2];
    
    return appId;
}


#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.results = [[NSMutableArray alloc] init];
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:
                      @"document.body.innerHTML"];
    NSError *err = nil;
    ONOXMLDocument *doc = [ONOXMLDocument HTMLDocumentWithString:html encoding:NSUTF8StringEncoding error:&err];
    NSInteger rank = 0;
    
    for (ONOXMLElement *element in [doc CSS:@"h3.r a"]) {
        NSString *url = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@", [GoogleAppStoreSearchManager getAppIdFromiTunesUrl:element.attributes[@"href"]]];
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
                               "Price: %@\n", title, ratingCount, rating, itunesUrl, price);
                    
                    GoogleAppResult *appResult = [[GoogleAppResult alloc] initWithUrl:itunesUrl name:title ratingCount:ratingCount rating:rating price:price rank:self.tasks[task]];
                    [self.results addObject:appResult];
                }
            }

            [self.tasks removeObjectForKey:task];
            
            if (self.tasks.count == 0) {
                [NetworkActivityIndicator decrementActivityCount];
                [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:self.results]];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [self.tasks removeObjectForKey:task];
            
            if (self.tasks.count == 0) {
                [NetworkActivityIndicator decrementActivityCount];
                [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:self.results]];
            }
        }];
        
        [self.tasks setObject:@(rank++) forKey:task];
        [task resume];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [self.delegate appSearchDidFailWithError:error];
}
@end
