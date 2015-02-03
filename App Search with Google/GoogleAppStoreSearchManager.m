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

@interface GoogleAppStoreSearchManager ()
@property (strong, nonatomic) UIWebView *web;
@end

@implementation GoogleAppStoreSearchManager

#pragma mark - Public Methods

- (instancetype)initWithDelegate:(id<GoogleAppStoreSearchManagerDelegate>)delegate {
    self = [super init];
    if (self) {
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
    [self.web loadRequest:requestObj];
}

#pragma mark - Private Helpers

+ (NSString *)getUrlWithSearchTerms:(NSArray *)terms scope:(DeviceScope)scope {
    
    NSMutableString *urlString = [[NSMutableString alloc] init];
    [urlString appendString:@"https://www.google.com/webhp?ion=1&espv=2&ie=UTF-8#safe=active&q="];

    NSString *scopeString = nil;
    switch (scope) {
        case DeviceScopeiPad:
            scopeString = @"ipad";
            break;
        case DeviceScopeiPhone:
            scopeString = @"iphone";
            break;
        default: // TODO: Not necessary, remove
            scopeString = @"iphone";
            break;
    }
    
    NSString *firstTerm = [NSString stringWithFormat:@"site:itunes.apple.com+%@", scopeString];
    
    [urlString appendString:firstTerm];
    
    for (NSString *term in terms) {
        [urlString appendString:@"+"];
        [urlString appendString:term];
    }
    
    return urlString;
}

#pragma mark - UIWebViewDelegate Methods
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:
                      @"document.body.innerHTML"];
    NSError *err = nil;
    ONOXMLDocument *doc = [ONOXMLDocument HTMLDocumentWithString:html encoding:NSUTF8StringEncoding error:&err];
    NSMutableArray *appResults = [[NSMutableArray alloc] init];
    for (ONOXMLElement *element in [doc CSS:@"h3.r a"]) {
        GoogleAppResult *result = [[GoogleAppResult alloc] initWithUrl:element.attributes[@"href"] name:element.stringValue];
        [appResults addObject:result];
    }
    [self.delegate appSearchDidSucceedWithResults:[NSArray arrayWithArray:appResults]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.delegate appSearchDidFailWithError:error];
}
@end
