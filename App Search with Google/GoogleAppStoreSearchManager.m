//
//  GoogleAppStoreSearchManager.m
//  App Search with Google
//
//  Created by Justin Dickow on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "GoogleAppStoreSearchManager.h"

#import <AFHTTPRequestOperationManager.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>

#import "GoogleAppResult.h"
#import "GoogleAppStoreSearchManagerDelegate.h"
#import "NetworkActivityIndicator.h"

@interface GoogleAppStoreSearchManager ()
@property (strong, nonatomic) UIWebView *web;
@property (strong, nonatomic) NSMutableSet *tasks;
@property (strong, nonatomic) NSMutableArray *results;
@end

@implementation GoogleAppStoreSearchManager

#pragma mark - Public Methods

- (instancetype)initWithDelegate:(id<GoogleAppStoreSearchManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        _tasks = [[NSMutableSet alloc] init];
        _results = [[NSMutableArray alloc] init];
        _delegate = delegate;
    }
    return self;
}

- (void)getAppsForSearchTerm:(NSString *)term withScope:(DeviceScope)scope {
    self.web = [[UIWebView alloc] init];
    self.web.delegate = self;
    
    NSArray *terms = [term componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *urlString = [GoogleAppStoreSearchManager getUrlWithSearchTerms:terms scope:scope];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    [NetworkActivityIndicator incrementActivityCount];

    [self.web loadRequest:requestObj];
}

#pragma mark - Private Helpers

+ (NSString *)getUrlWithSearchTerms:(NSArray *)terms scope:(DeviceScope)scope {
    
    NSMutableString *urlString = [[NSMutableString alloc] init];
    [urlString appendString:@"https://www.google.com/webhp?ion=1&espv=2&ie=UTF-8#safe=active&q="];

    NSString *scopeString = nil;
    switch (scope) {
        case DeviceScopeiPad: {
            scopeString = @"ipad";
        } break;
        case DeviceScopeiPhone: {
            scopeString = @"iphone";
        } break;
    }
    
    NSString *firstTerm = [NSString stringWithFormat:@"site:itunes.apple.com+%@", scopeString];
    
    [urlString appendString:firstTerm];
    
    for (NSString *term in terms) {
        [urlString appendString:@"+"];
        [urlString appendString:term];
    }
    
    return urlString;
}

+ (NSString *)getAppIdFromiTunesUrl:(NSString *)urlString {
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSArray *pathComponents = [components.path componentsSeparatedByString:@"/"];
    NSLog(@"%@", pathComponents);
    NSString *idComponent = pathComponents.lastObject;
    NSString *id = [idComponent substringFromIndex:2];
    return id;
}

#pragma mark - UIWebViewDelegate Methods
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:
                      @"document.body.innerHTML"];
    NSError *err = nil;
    self.results = [[NSMutableArray alloc] init];
    ONOXMLDocument *doc = [ONOXMLDocument HTMLDocumentWithString:html encoding:NSUTF8StringEncoding error:&err];
    for (ONOXMLElement *element in [doc CSS:@"h3.r a"]) {
        NSString *url = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@", [GoogleAppStoreSearchManager getAppIdFromiTunesUrl:element.attributes[@"href"]]];
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        AFHTTPRequestOperation *task = [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
            NSString *errorMessage = (NSString *)responseObject[@"errorMessage"];
            NSArray *results = (NSArray *)responseObject[@"results"];
            if (!errorMessage) {
                for (NSDictionary *result in results) {
                    NSString *title = (NSString *)result[@"trackName"];
                    NSNumber *ratingCount = (NSNumber *)result[@"userRatingCount"];
                    NSNumber *rating = (NSNumber *)result[@"averageUserRating"];
                    NSString *itunesUrl = (NSString *)result[@"trackViewUrl"];
                    NSNumber *price = (NSNumber *)result[@"price"];
                    GoogleAppResult *appResult = [[GoogleAppResult alloc] initWithUrl:itunesUrl name:title ratingCount:ratingCount rating:rating price:price];
                    NSLog(@"%@, %@, %@, %@, %@", title, ratingCount, rating, itunesUrl, price);
                    [self.results addObject:appResult];
                }
            }
            
            [self.tasks removeObject:operation];
            if (self.tasks.count == 0) {
                [NetworkActivityIndicator decrementActivityCount];
                [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:self.results]];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            [self.tasks removeObject:operation];
            if (self.tasks.count == 0) {
                [NetworkActivityIndicator decrementActivityCount];
                [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:self.results]];
            }
        }];
        [self.tasks addObject:task];
        [task start];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [self.delegate appSearchDidFailWithError:error];
}
@end
