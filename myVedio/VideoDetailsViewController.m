//
//  VideoDetailsViewController.m
//  myVedio
//
//  Created by Rawan Marzouq on 4/30/16.
//  Copyright © 2016 Rawan. All rights reserved.
//

#import "VideoDetailsViewController.h"

#define preURL @"http://salesappointmentsinabox.com/api/public"

@interface VideoDetailsViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;
@property (weak, nonatomic) IBOutlet UITextField *customerName;
@property (weak, nonatomic) IBOutlet UIDatePicker *appDate;

@end

@implementation VideoDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    UIBarButtonItem *saveBtn = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveChanges)];
//    self.navigationController.navigationItem.leftBarButtonItem = saveBtn;
    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                              target:self
                                                                              action:@selector(saveChanges)];
    [self.navigationItem setRightBarButtonItem:menuItem];
    
    
//    [self LoadVideo];
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
-(void)saveChanges
{
    self.loading.hidden = NO;
    [self.customerName resignFirstResponder];
    NSDate *chosen = [self.appDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-d"];
    NSString *date = [dateFormat stringFromDate:chosen];
    [dateFormat setDateFormat:@"HH:mm:ss"];
    NSString *time = [dateFormat stringFromDate:chosen];
    NSLog(@"chosen: %@, time:%@",date,time);
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"userId"];
    NSString *videoId = [[NSUserDefaults standardUserDefaults] stringForKey:@"videoId"];
    
    // Call API
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    //Create an URLRequest
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/appointments/create",preURL]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    //Create POST Params and add it to HTTPBody
    NSString *params = [NSString stringWithFormat:@"&user_id=%@&video_id=%@&customer_name=%@&app_date=%@&app_time=%@",userId,videoId,self.customerName.text,date,time];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:[[NSUserDefaults standardUserDefaults] stringForKey:@"key"]  forHTTPHeaderField:@"X-Authorization"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"setHTTPBody: %@", urlRequest.HTTPBody);
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
            if ([[jsonObjects objectForKey:@"data"] objectForKey:@"success"]) {
                NSLog(@"%@",[[jsonObjects objectForKey:@"data"] objectForKey:@"confirmation_url"]);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation URL" message:[NSString stringWithFormat:@"%@",[[jsonObjects objectForKey:@"data"] objectForKey:@"confirmation_url"]] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%@",[[jsonObjects objectForKey:@"data"] objectForKey:@"confirmation_url"]]];
                    
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Create Appointment Operation Failed!" message:@"Please check your internet connection" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
            
        }
    }];
    
    [dataTask resume];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self view] endEditing:YES];
}
@end
