//
//  AppSearchTableViewController.m
//  App Search with Google
//
//  Created by Joel Fischer on 2/3/15.
//  Copyright (c) 2015 objective-awesome. All rights reserved.
//

#import "AppSearchTableViewController.h"

@interface AppSearchTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchController;

@end


@implementation AppSearchTableViewController

- (void)viewDidLoad {
    // Set up the search controller
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.navigationItem.titleView = self.searchController.searchBar;
    
    // Set up the search bar
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.delegate = self;
    searchBar.placeholder = NSLocalizedString(@"Search for an App", nil);
    [searchBar setKeyboardAppearance:UIKeyboardAppearanceDark];
}


// TODO: Separate objects. No massive VC.
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"TableView Did Select Row at IndexPath: %@", indexPath);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
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
    
}

// called when text ends editing
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
}

// called when text changes (including clear)
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"Search Bar Text did Change: %@", searchText);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Search Bar Search Button Clicked");
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Search Bar Cancel Clicked");
}

@end
