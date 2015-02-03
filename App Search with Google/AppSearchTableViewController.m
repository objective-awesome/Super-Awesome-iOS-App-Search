//
//  AppSearchTableViewController.m
//  App Search with Google
//
//  Created by Joel Fischer on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "AppSearchTableViewController.h"

#import "GoogleAppStoreSearchManager.h"
#import "GoogleAppStoreSearchManagerDelegate.h"
#import "GoogleAppResult.h"
#import "AppSearchResultTableViewCell.h"


@interface AppSearchTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, GoogleAppStoreSearchManagerDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UISegmentedControl *scopeSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem *scopeBarButtonItem;

@property (nonatomic, strong) GoogleAppStoreSearchManager *searchManager;
@property (nonatomic, strong) NSArray *resultsStore;

@end


@implementation AppSearchTableViewController

- (void)viewDidLoad {
    // Create some initial data for our private properties
    self.resultsStore = @[];
    self.searchManager = [[GoogleAppStoreSearchManager alloc] initWithDelegate:self];
    
    // Set up the search controller
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.navigationItem.titleView = self.searchController.searchBar;
    
    // Set up the search bar
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.delegate = self;
    searchBar.showsCancelButton = NO;
    searchBar.placeholder = NSLocalizedString(@"Search for an App", nil);
    [searchBar setKeyboardAppearance:UIKeyboardAppearanceDark];
    [searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    // Set up the scope control
    self.scopeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"iPhone", nil), NSLocalizedString(@"iPad", nil)]];
    self.scopeSegmentedControl.selectedSegmentIndex = 0;
    
    // Position the scope control
    self.scopeBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scopeSegmentedControl];
    self.navigationItem.rightBarButtonItem = self.scopeBarButtonItem;
}


#pragma mark - GoogleAppStoreSearchManagerDelegate

- (void)appSearchDidSucceedWithResults:(NSArray *)apps {
    NSLog(@"App search results to VC: %@", apps);
    self.resultsStore = apps;
    
    [self.tableView reloadData];
}

- (void)appSearchDidFailWithError:(NSError *)error {
    // TODO: Show a failure state on UI
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


#pragma mark - UISearchControllerDelegate

//- (void)willPresentSearchController:(UISearchController *)searchController {
//
//}
//
//- (void)didPresentSearchController:(UISearchController *)searchController {
//
//}
//
//- (void)willDismissSearchController:(UISearchController *)searchController {
//
//}
//
//- (void)didDismissSearchController:(UISearchController *)searchController {
//
//}

// Called after the search controller's search bar has agreed to begin editing or when 'active' is set to YES. If you choose not to present the controller yourself or do not implement this method, a default presentation is performed on your behalf.
//- (void)presentSearchController:(UISearchController *)searchController {
//
//}


#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSLog(@"Update Search Results for Search Controller: %@", searchController);
}


// TODO: Separate objects to handle this stuff, similar to table view data sources?
#pragma mark - UISearchBarDelegate

// called when text starts editing
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchController.searchBar.showsCancelButton = NO;
}

// called when text ends editing
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
}

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
}

@end
