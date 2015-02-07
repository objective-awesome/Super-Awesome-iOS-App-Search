//
//  AppSearchTableViewController.m
//  App Search with Google
//
//  Created by Joel Fischer on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "AppSearchTableViewController.h"

#import <SpinKit/RTSpinKitView.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
@import StoreKit;

#import "GoogleAppStoreSearchManager.h"
#import "GoogleAppStoreSearchManagerDelegate.h"
#import "GoogleAppResult.h"
#import "AppSearchResultTableViewCell.h"
#import "UIColor+Utilities.h"


#ifdef DEBUG
static const int ddLogLevel = DDLogLevelDebug;
#else
static const int ddLogLevel = DDLogLevelError;
#endif


@interface AppSearchTableViewController () <UISearchBarDelegate, GoogleAppStoreSearchManagerDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *scopeSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem *scopeBarButtonItem;

@property (nonatomic, strong) GoogleAppStoreSearchManager *searchManager;
@property (nonatomic, strong) NSArray *resultsStore;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign, readonly) DeviceScope scope;
@property (nonatomic, strong) NSTimer *inputLimiter;
@property (nonatomic, strong) NSString *lastSearchedString;
@property (nonatomic, strong) NSNumberFormatter *appIdNumberFormatter;

@end


@implementation AppSearchTableViewController

- (void)viewDidLoad {
    // Create some initial data for our private properties
    self.resultsStore = @[];
    self.searchManager = [[GoogleAppStoreSearchManager alloc] initWithDelegate:self];
    self.appIdNumberFormatter = [[NSNumberFormatter alloc] init];
    self.appIdNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    // Set nav controller bar style to change the status bar style to light
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    // Set up some things about our tableview
    self.tableView.scrollsToTop = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    // Set up the search bar
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    self.searchBar.showsCancelButton = NO;
    self.searchBar.placeholder = NSLocalizedString(@"Search for an App", nil);
    
    // Set up the scope control
    self.scopeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"iPhone", nil), NSLocalizedString(@"iPad", nil)]];
    self.scopeSegmentedControl.selectedSegmentIndex = 0;
    
    // Position the scope control
    self.scopeBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scopeSegmentedControl];
    self.navigationItem.rightBarButtonItem = self.scopeBarButtonItem;
    
    // Set up color
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRGBRed:192 green:57 blue:43 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    self.scopeSegmentedControl.tintColor = [UIColor whiteColor];
    self.navigationItem.titleView = self.searchBar;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.searchBar becomeFirstResponder];
}


#pragma mark - Setters

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    if (_loading && ([MBProgressHUD allHUDsForView:self.view].count == 0)) {
        RTSpinKitView *spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave color:[UIColor whiteColor] spinnerSize:37.0];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.square = YES;
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = spinner;
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}


#pragma mark - Getters

- (DeviceScope)scope {
    DeviceScope scope = DeviceScopeiPhone;
    
    switch (self.scopeSegmentedControl.selectedSegmentIndex) {
        case 0: {
            scope = DeviceScopeiPhone;
        } break;
        case 1: {
            scope = DeviceScopeiPad;
        } break;
        default: {
            NSAssert(NO, @"Device Scope type not handled: %@", @(self.scopeSegmentedControl.selectedSegmentIndex));
        } break;
    }
    
    return scope;
}


#pragma mark - GoogleAppStoreSearchManagerDelegate

- (void)appSearchDidSucceedWithResults:(NSArray *)apps {
    DDLogInfo(@"App Search succeeded");
    if (apps.count == 0) {
        return;
    }
    
    self.resultsStore = [apps sortedArrayUsingComparator:^NSComparisonResult(GoogleAppResult *obj1, GoogleAppResult *obj2) {
        return [obj1.rank compare:obj2.rank];
    }];
    
    [self.tableView reloadData];
    self.loading = NO;
}

- (void)appSearchDidFailWithError:(NSError *)error {
    // TODO: Show a failure state on UI
    DDLogError(@"App search failed with error: %@", error);
    self.loading = NO;
}


// TODO: Separate objects. No massive VC.
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultsStore.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppSearchResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AppSearchResultTableViewCell class])];
    GoogleAppResult *app = self.resultsStore[indexPath.row];
    
    if (app != nil) {
        cell.nameLabel.text = app.name;
    } else {
        cell.nameLabel.text = @"";
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchBar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    GoogleAppResult *app = self.resultsStore[indexPath.row];
    NSNumber *appId = [self.appIdNumberFormatter numberFromString:app.iTunesId];
    
    SKStoreProductViewController *storeVC = [[SKStoreProductViewController alloc] init];
    storeVC.delegate = self;
    self.loading = YES;
    [storeVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: appId} completionBlock:^(BOOL result, NSError *error) {
        self.loading = NO;
        
        if (error != nil) {
            DDLogError(@"Error loading product for app id: %@", appId);
        } else {
            DDLogInfo(@"Loaded product for app id successfully? %@", (result ? @"YES" : @"NO"));
            
            if (result) {
                [self presentViewController:storeVC animated:YES completion:^{
                    DDLogDebug(@"Presented store view controller successfully");
                }];
            }
        }
    }];
    
    // TODO: Setting to use this instead?
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:app.url]];
}


// TODO: Separate objects to handle this stuff, similar to table view data sources?
#pragma mark - UISearchBarDelegate

// called when text changes (including clear)
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    DDLogDebug(@"Search Bar Text did Change: %@", searchText);
    
    // TODO This is done broke
//    if (self.inputLimiter != nil) {
//        [self.inputLimiter invalidate];
//        self.inputLimiter = nil;
//    }
//    
//    self.inputLimiter = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(search) userInfo:nil repeats:NO];
//    [[NSRunLoop mainRunLoop] addTimer:self.inputLimiter forMode:NSDefaultRunLoopMode];
}

- (void)search {
    if (![self.lastSearchedString isEqualToString:self.searchBar.text]) {
        self.lastSearchedString = self.searchBar.text;
        [self.searchManager getAppsForSearchTerm:self.searchBar.text withScope:self.scope];
        
        self.loading = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self search];
    [self.searchBar resignFirstResponder];
}


#pragma mark - SKStoreProductViewController Delegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    if (viewController != nil) {
        [self dismissViewControllerAnimated:YES completion:^{
            DDLogDebug(@"Store VC did dismiss");
        }];
    }
}

@end
