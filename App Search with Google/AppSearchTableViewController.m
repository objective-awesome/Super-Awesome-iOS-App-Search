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

#import "GoogleAppStoreSearchManager.h"
#import "GoogleAppStoreSearchManagerDelegate.h"
#import "GoogleAppResult.h"
#import "AppSearchResultTableViewCell.h"


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
    
    // Set up the search bar
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.showsCancelButton = NO;
    self.searchBar.placeholder = NSLocalizedString(@"Search for an App", nil);
    [self.searchBar setKeyboardAppearance:UIKeyboardAppearanceDark];
    [self.searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
    self.navigationItem.titleView = self.searchBar;
    
    // Set up the scope control
    self.scopeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"iPhone", nil), NSLocalizedString(@"iPad", nil)]];
    self.scopeSegmentedControl.selectedSegmentIndex = 0;
    
    // Position the scope control
    self.scopeBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scopeSegmentedControl];
    self.navigationItem.rightBarButtonItem = self.scopeBarButtonItem;
}


#pragma mark - Setters

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    // TODO: Dim / Blur & Show SpinKit
    if (_loading) {
        RTSpinKitView *spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyle9CubeGrid color:[UIColor whiteColor] spinnerSize:37.0];
        
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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GoogleAppResult *app = self.resultsStore[indexPath.row];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:app.url]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppSearchResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AppSearchResultTableViewCell class])];
    GoogleAppResult *app = self.resultsStore[indexPath.row];
    
    if (app != nil) {
        cell.nameLabel.text = app.name;
        cell.urlLabel.text = app.url;
    } else {
        cell.nameLabel.text = @"";
        cell.urlLabel.text = @"";
    }
    
    return cell;
}


// TODO: Separate objects to handle this stuff, similar to table view data sources?
#pragma mark - UISearchBarDelegate

// called when text changes (including clear)
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"Search Bar Text did Change: %@", searchText);
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
