//
//  LocationProfileView.m
//  Pinball
//
//  Created by Frank Michael on 4/13/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "LocationProfileView.h"
#import "InformationCell.h"
#import "LocationMapCell.h"
@import CoreLocation;
@import MapKit;
#import "Machine.h"
#import "MapView.h"
#import "MachineConditionView.h"
#import "NewMachineLocationView.h"
#import "NSDate+DateFormatting.h"
#import "InputCell.h"
#import "MachineProfileView.h"
#import "TextEditorView.h"
#import <ReuseWebView.h>

@interface LocationProfileView () <TextEditorDelegate,NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *machinesFetch;
    UIImage *mapSnapshot;

    UISegmentedControl *dataSetSeg;
}
@end

@implementation LocationProfileView

- (id)initWithStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = _currentLocation.name;
    // Sort the machines by name.
    NSFetchRequest *locationMachines = [NSFetchRequest fetchRequestWithEntityName:@"MachineLocation"];
    locationMachines.predicate = [NSPredicate predicateWithFormat:@"location.locationId = %@",_currentLocation.locationId];
    locationMachines.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"conditionUpdate" ascending:YES]];
    machinesFetch = [[NSFetchedResultsController alloc] initWithFetchRequest:locationMachines managedObjectContext:[[CoreDataManager sharedInstance] managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    machinesFetch.delegate = self;
    [machinesFetch performFetch:nil];
    
    
    NSSortDescriptor *asc = [NSSortDescriptor sortDescriptorWithKey:@"machine.name" ascending:YES];

    dataSetSeg = [[UISegmentedControl alloc] init];
    dataSetSeg.frame = CGRectMake(5, 7, 310, 29);
    [dataSetSeg insertSegmentWithTitle:@"Info" atIndex:0 animated:YES];
    [dataSetSeg insertSegmentWithTitle:@"Machines" atIndex:1 animated:YES];
    [dataSetSeg addTarget:self action:@selector(changeData:) forControlEvents:UIControlEventValueChanged];
    [dataSetSeg setSelectedSegmentIndex:0];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    UIBarButtonItem *addMachine = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewMachine:)];
    self.navigationItem.rightBarButtonItem = addMachine;
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)showMap{
    MapView *map = [[[self.storyboard instantiateViewControllerWithIdentifier:@"MapView"] viewControllers] lastObject];
    map.currentLocation = _currentLocation;
    [self.navigationController pushViewController:map animated:YES];
}
#pragma mark - Class Actions
- (IBAction)saveLocation:(id)sender{
    #pragma message("TODO: API interaction to save new location information")
}
- (IBAction)changeData:(id)sender{
    [self.tableView reloadData];
}
- (IBAction)addNewMachine:(id)sender{
    NewMachineLocationView *vc = (NewMachineLocationView *)[[[self.storyboard instantiateViewControllerWithIdentifier:@"NewMachineLocationView"] viewControllers] lastObject];
    vc.location = _currentLocation;
    [self.navigationController presentViewController:vc.parentViewController animated:YES completion:nil];
}
#pragma mark - TextEditor Delegate
- (void)editorDidComplete:(NSString *)text{
    NSLog(@"%@",text);
#pragma message ("TODO: API interaction to update location description")
}
- (void)editorDidCancel{
    
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0){
        return 1;
    }else{
        if (dataSetSeg.selectedSegmentIndex == 0){
            return 4;
        }else if (dataSetSeg.selectedSegmentIndex == 1){
            NSInteger rows = 0;
            if ([[machinesFetch sections] count] > 0) {
                id <NSFetchedResultsSectionInfo> sectionInfo = [[machinesFetch sections] objectAtIndex:0];
                rows = [sectionInfo numberOfObjects];
            }
            return rows;
        }
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 1){
        return 44;
    }
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 1){
        UIView *dataSegView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
        [dataSegView setBackgroundColor:[UIColor whiteColor]];
        [dataSegView addSubview:dataSetSeg];
        return dataSegView;
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        // Map image.
        return 122;
    }else if (indexPath.section == 1){
        if (dataSetSeg.selectedSegmentIndex == 0){
            NSString *detailText;
            if (indexPath.row == 0){
                detailText = _currentLocation.phone;
            }else if (indexPath.row == 1){
                detailText = _currentLocation.fullAddress;
            }else if (indexPath.row == 2){
                detailText = _currentLocation.locationDescription;
            }else if (indexPath.row == 3){
                detailText = _currentLocation.website;
            }

            CGRect textLabel = [detailText boundingRectWithSize:CGSizeMake(280, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]} context:nil];
            textLabel.size.height = textLabel.size.height+45;
            if (textLabel.size.height <= 67){
                return 67;
            }
            return textLabel.size.height;

        }else if (dataSetSeg.selectedSegmentIndex == 1){
            MachineLocation *currentMachine = [machinesFetch objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
            NSString *cellDetail = [NSString stringWithFormat:@"%@ updated on %@",currentMachine.condition,[currentMachine.conditionUpdate monthDayYearPretty:YES]];
            
            CGRect titleLabel = [currentMachine.machine.machineTitle boundingRectWithSize:CGSizeMake(238, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
            CGRect detailLabel = [cellDetail boundingRectWithSize:CGSizeMake(238, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil];
            // Add 6 pixel padding present in subtitle style.
            CGRect stringSize = CGRectMake(0, 0, 290, titleLabel.size.height+detailLabel.size.height+6);
            
            if (stringSize.size.height+10 < 44){
                return 44;
            }else{
                return stringSize.size.height+10;
            }
        }
    }
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        // Map Cell
        LocationMapCell *cell = (LocationMapCell *)[tableView dequeueReusableCellWithIdentifier:@"MapCell" forIndexPath:indexPath];
        if (!mapSnapshot){
            [cell.loadingView startAnimating];
            
            if (_currentLocation.mapShot){
                [cell.loadingView stopAnimating];
                cell.mapImage.image = _currentLocation.mapShot;
                mapSnapshot = _currentLocation.mapShot;
                [cell addAnnotation];
            }else{
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([_currentLocation.latitude doubleValue],[_currentLocation.longitude doubleValue]);
                
                MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
                options.size = cell.mapImage.frame.size;
                options.region = MKCoordinateRegionMake(coord, MKCoordinateSpanMake(.002, .002));
                options.mapType = MKMapTypeHybrid;
                options.showsPointsOfInterest = NO;
                MKMapSnapshotter *snapShooter2 = [[MKMapSnapshotter alloc] initWithOptions:options];
                [snapShooter2 startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
                    NSLog(@"Loaded Snap");
                    if (error){
                        NSLog(@"%@",error);
                    }else{
                        [cell.loadingView stopAnimating];
                        cell.mapImage.image = snapshot.image;
                        mapSnapshot = snapshot.image;
                        [cell addAnnotation];
                        [_currentLocation saveMapShot:snapshot.image];
                    }
                }];
            }
        }
        return cell;
    }else if (indexPath.section == 1){
        if (dataSetSeg.selectedSegmentIndex == 0){
            // Profile data with InfoCell
            InformationCell *cell = (InformationCell *)[tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
            if (indexPath.row == 0){
                cell.infoLabel.text = @"Phone";
                cell.dataLabel.text = _currentLocation.phone;
            }else if (indexPath.row == 1){
                cell.infoLabel.text = @"Location";
                cell.dataLabel.text = _currentLocation.fullAddress;
            }else if (indexPath.row == 2){
                cell.infoLabel.text = @"Description";
                cell.dataLabel.text = _currentLocation.locationDescription;
            }else  if (indexPath.row == 3){
                cell.infoLabel.text = @"Website";
                cell.dataLabel.text = _currentLocation.website;
            }
            return cell;
        }else if (dataSetSeg.selectedSegmentIndex == 1){

            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MachineCell" forIndexPath:indexPath];
                // Machine cell.
            MachineLocation *currentMachine = [machinesFetch objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
            cell.textLabel.attributedText = currentMachine.machine.machineTitle;
            cell.detailTextLabel.numberOfLines = 0;
            // If no condition is available, just don't set the detail text label.
            if (![currentMachine.condition isEqualToString:@"N/A"]){
                if (currentMachine.conditionUpdate){
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ updated on %@",currentMachine.condition,[currentMachine.conditionUpdate monthDayYearPretty:YES]];
                }else{
                    cell.detailTextLabel.text = currentMachine.condition;
                }
            }else{
                cell.detailTextLabel.text = nil;
            }
            return cell;

        }
    }
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0){
        [self showMap];
    }else if (indexPath.section == 1){
        if (dataSetSeg.selectedSegmentIndex == 0){
            if (indexPath.row == 0){
                if (_currentLocation.phone.length > 0 && ![_currentLocation.phone isEqualToString:@"Tap to edit"]){
                    NSString *contactsPhoneNumber = [@"tel:+" stringByAppendingString:_currentLocation.phone];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:contactsPhoneNumber]];
                }else if ([_currentLocation.phone isEqualToString:@"Tap to edit"]){
                    TextEditorView *editor = [[[self.storyboard instantiateViewControllerWithIdentifier:@"TextEditorView"] viewControllers] lastObject];
                    editor.delegate = self;
                    editor.editorTitle = @"Location Phone";
                    [self.navigationController presentViewController:editor.parentViewController animated:YES completion:nil];
                }
            }else if (indexPath.row == 1){
                [self showMap];
            }else if (indexPath.row == 2){
                TextEditorView *editor = [[[self.storyboard instantiateViewControllerWithIdentifier:@"TextEditorView"] viewControllers] lastObject];
                editor.delegate = self;
                editor.editorTitle = @"Location Description";
                if (![_currentLocation.locationDescription isEqualToString:@"Tap to edit"]){
                    editor.textContent  =_currentLocation.locationDescription;
                }
                [self.navigationController presentViewController:editor.parentViewController animated:YES completion:nil];
            }else if (indexPath.row == 3){
                if (_currentLocation.website.length > 0 && ![_currentLocation.website isEqualToString:@"Tap to edit"]){
                    ReuseWebView *webView = [[ReuseWebView alloc] initWithURL:[NSURL URLWithString:_currentLocation.website]];
                    webView.webTitle = _currentLocation.name;
                    [self.navigationController presentViewController:[[UINavigationController alloc] initWithRootViewController:webView] animated:YES completion:nil];
                }else{
                    TextEditorView *editor = [[[self.storyboard instantiateViewControllerWithIdentifier:@"TextEditorView"] viewControllers] lastObject];
                    editor.delegate = self;
                    editor.editorTitle = @"Location Website";
                    [self.navigationController presentViewController:editor.parentViewController animated:YES completion:nil];
                }
            }
        }else if (dataSetSeg.selectedSegmentIndex == 1){
            MachineConditionView *vc = (MachineConditionView *)[[[self.storyboard instantiateViewControllerWithIdentifier:@"MachineCondition"] viewControllers] lastObject];
            vc.currentMachine = [machinesFetch objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
            [tableView setEditing:NO];
            [self.navigationController presentViewController:vc.parentViewController animated:YES completion:nil];
        }
    }
}
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){
        MachineLocation *currentMachine = [machinesFetch objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        MachineProfileView *machineProfile = [self.storyboard instantiateViewControllerWithIdentifier:@"MachineProfile"];
        machineProfile.currentMachine = currentMachine.machine;
        [self.navigationController pushViewController:machineProfile animated:YES];
    }
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1 && dataSetSeg.selectedSegmentIndex == 1){
        return YES;
    }
    return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        MachineConditionView *vc = (MachineConditionView *)[[[self.storyboard instantiateViewControllerWithIdentifier:@"MachineCondition"] viewControllers] lastObject];
        vc.currentMachine = [machinesFetch objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [tableView setEditing:NO];
        [self.navigationController presentViewController:vc.parentViewController animated:YES completion:nil];
    }
}
#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:newIndexPath.row inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if (dataSetSeg.selectedSegmentIndex == 1){
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}

@end
