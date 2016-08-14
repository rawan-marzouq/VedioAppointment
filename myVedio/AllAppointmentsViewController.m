//
//  AllAppointmentsViewController.m
//  myVedio
//
//  Created by Rawan Marzouq on 5/6/16.
//  Copyright © 2016 Rawan. All rights reserved.
//

#import "AllAppointmentsViewController.h"
#import "Appointment.h"


#define preURL @"http://salesappointmentsinabox.com/api/public"

@interface AllAppointmentsViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray *appointmentsArray;
}
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;
@property (weak, nonatomic) IBOutlet UITableView *appointmentsTable;
@end

@implementation AllAppointmentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // load all app list
//    [self LoadAppointmentsList];
    
    self.navigationItem.title = @"All Appointments";
}
-(void)viewDidAppear:(BOOL)animated
{
    // load all app list
    [self LoadAppointmentsList];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - IBActions

- (IBAction)SignOut:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:NULL forKey:@"key"];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *loginVC =  [storyboard instantiateViewControllerWithIdentifier:@"Login"];
    
    [self presentViewController:loginVC animated:NO completion:nil];
}

#pragma mark - Load Appointments List
-(void)LoadAppointmentsList
{
    self.loading.hidden = NO;
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    //Create an URLRequest
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/appointments-all/%@",preURL,[[NSUserDefaults standardUserDefaults] stringForKey:@"userId"]]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    NSLog(@"url: %@",url);
    [urlRequest setHTTPMethod:@"GET"];
    
    [urlRequest setValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"key"]  forHTTPHeaderField:@"X-Authorization"];
    
    NSLog(@"REQUEST: %@",urlRequest.allHTTPHeaderFields);
    //Create task
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //Handle your response here
        if (data.length > 0 && error == nil)
        {
            self.loading.hidden = YES;
            NSError *error = nil;
            id jsonObjects = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
            NSLog(@"callResult: %@",jsonObjects);
            if (error) {
                NSLog(@"error is %@", [error localizedDescription]);
                
                // Handle Error and return
                return;
                
            }
            NSLog(@"jsonObjects: %@",[jsonObjects allKeys]);
            
            NSArray *appointments = [jsonObjects objectForKey:@"data"];
            if (appointments)
            {
                appointmentsArray = [[NSMutableArray alloc]init];
                for (int i = 0; i < [appointments count]; i++) {
                    NSDictionary *appointmentData = (NSDictionary*) [appointments objectAtIndex:i];
                    Appointment *appointment = [[Appointment alloc]init];
                    appointment.customerName = [appointmentData objectForKey:@"customer_name"] ;
                    appointment.date = [appointmentData objectForKey:@"app_date"];
                    appointment.time = [appointmentData objectForKey:@"app_time"];
                    appointment.URL = [appointmentData objectForKey:@"confirmation_url"];
                    [appointmentsArray addObject:appointment];
                    
                }
                NSLog(@"appointmentsArray : %lu",(unsigned long)[appointmentsArray count]);
                [self.appointmentsTable reloadData];
            }
            else
            {
                self.loading.hidden = YES;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"API Internal Error!" message:@"Ops! Something Went Wrong." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
        }
        else
        {
            self.loading.hidden = YES;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Loading Failed!" message:@"Please check your internet connection" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
            NSLog(@"%@",error);
            
        }
    }];
    
    [dataTask resume];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [appointmentsArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    NSString *cellIdentifier = @"cellIdentifier";
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (appointmentsArray) {
            Appointment *app = (Appointment*)[appointmentsArray objectAtIndex:indexPath.row];
            cell.textLabel.text = app.customerName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",app.date,app.time];
        }
    }
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Appointment *app = (Appointment*)[appointmentsArray objectAtIndex:indexPath.row];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation URL" message:app.URL preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%@",app.URL]];
        
        
    }];
    [alert addAction:copyAction];
    [self presentViewController:alert animated:YES completion:nil];
}



@end
