//
//  RecentlyAddedView.m
//  PinballMap
//
//  Created by Frank Michael on 9/14/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "RecentlyAddedView.h"
#import "UIAlertView+Application.h"
#import "RecentMachine.h"

@interface RecentlyAddedView ()

@property (nonatomic) NSMutableArray *recentMachines;

@end

@implementation RecentlyAddedView

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recentMachines = [NSMutableArray new];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissView:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    
    [[PinballMapManager sharedInstance] recentlyAddedMachinesWithCompletion:^(NSDictionary *status) {
        if (status[@"errors"]){
            NSString *errors;
            if ([status[@"errors"] isKindOfClass:[NSArray class]]){
                errors = [status[@"errors"] componentsJoinedByString:@","];
            }else{
                errors = status[@"errors"];
            }
            [UIAlertView simpleApplicationAlertWithMessage:errors cancelButton:@"Ok"];
        }else{
            NSArray *recentMachines = status[@"location_machine_xrefs"];
            [recentMachines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                RecentMachine *machine = [[RecentMachine alloc] initWithData:obj];
                [self.recentMachines addObject:machine];
            }];

            self.recentMachines = [self.recentMachines sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdOn" ascending:NO]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
            NSLog(@"%@",recentMachines);
        }
    }];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Class Actions
- (IBAction)dismissView:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - TableView Datasource/Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.recentMachines.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"RecentMachineCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    RecentMachine *machine = [self.recentMachines objectAtIndex:indexPath.row];
    cell.textLabel.text = machine.machine.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)",machine.location.name,machine.location.city];

    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end