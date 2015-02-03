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


@interface AppSearchTableViewController () <UISearchBarDelegate, GoogleAppStoreSearchManagerDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *scopeSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem *scopeBarButtonItem;

@property (nonatomic, strong) GoogleAppStoreSearchManager *searchManager;
@property (nonatomic, strong) NSArray *resultsStore;
@property (nonatomic, assign) BOOL loading;

@end


@implementation AppSearchTableViewController

- (void)viewDidLoad {
    // Create some initial data for our private properties
    self.resultsStore = @[];
    self.searchManager = [[GoogleAppStoreSearchManager alloc] initWithDelegate:self];
    
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
        
    self.searchBar.translucent = YES;
    self.navigationItem.titleView = self.searchBar;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.searchBar becomeFirstResponder];
}


#pragma mark - Setters

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    // TODO: Dim / Blur & Show SpinKit
    if (_loading) {
        RTSpinKitView *spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave color:[UIColor whiteColor] spinnerSize:37.0];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.square = YES;
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = spinner;
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}


#pragma mark - GoogleAppStoreSearchManagerDelegate

- (void)appSearchDidSucceedWithResults:(NSArray *)apps {
    self.resultsStore = apps;
    
    [self.tableView reloadData];
    self.loading = NO;
}

- (void)appSearchDidFailWithError:(NSError *)error {
    // TODO: Show a failure state on UI
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
    
    GoogleAppResult *app = self.resultsStore[indexPath.row];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:app.url]];
}


// TODO: Separate objects to handle this stuff, similar to table view data sources?
#pragma mark - UISearchBarDelegate

// called when text changes (including clear)
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    DDLogDebug(@"Search Bar Text did Change: %@", searchText);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *searchString = searchBar.text;
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
    
    [self.searchManager getAppsForSearchTerm:searchString withScope:scope];
    self.loading = YES;
    
    [self.searchBar resignFirstResponder];
}

@end
