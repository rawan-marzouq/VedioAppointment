//
//  LoginViewController.m
//  myVedio
//
//  Created by Rawan Marzouq on 4/29/16.
//  Copyright © 2016 Rawan. All rights reserved.
//

#import "LoginViewController.h"
#import "ViewController.h"

#define preURL @"http://salesappointmentsinabox.com/api/public"

@interface LoginViewController ()<NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;
- (IBAction)Login:(id)sender;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.loading.hidden = YES;
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

- (IBAction)Login:(id)sender {
    
    [self.userName resignFirstResponder];
    [self.password resignFirstResponder];
    
    self.loading.hidden = NO;
    if (([self.userName.text length] > 0) && ([self.password.text length] > 0)) {
        [self auth];
    }
    else
    {
        self.loading.hidden = YES;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed!" message:@"Please Enter Your Username & Password" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

-(void)auth{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    //Create an URLRequest
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/authenticate",preURL]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    //Create POST Params and add it to HTTPBody
//    NSString *params = [NSString stringWithFormat:@"&username=%@&password=%@",@"info@testrep.com",@"rep1"];
    NSString *params = [NSString stringWithFormat:@"&username=%@&password=%@",self.userName.text,self.password.text];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
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
                self.loading.hidden = YES;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed!" message:@"Please Enter Your Username & Password Correctly" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
                self.userName.text = @"";
                self.password.text = @"";
                return;
                
            }
            NSLog(@"jsonObjects: %@",[jsonObjects allKeys]);
            NSString *key = [[jsonObjects objectForKey:@"data"] objectForKey:@"key"];
            NSString *userId = [[jsonObjects objectForKey:@"data"]objectForKey:@"user_id"];
            [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"key"];
            [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"userId"];
            NSLog(@"Key: %@",key);
            if (!key) {
                
                NSString *errMessage = [[jsonObjects objectForKey:@"error"] objectForKey:@"message"];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed!" message:errMessage preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
                self.userName.text = @"";
                self.password.text = @"";
            }
            else
            {
                UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                ViewController* videos = [sb instantiateViewControllerWithIdentifier:@"tabVC"];
                [self presentViewController:videos animated:YES completion:nil];
            }
        }
        else
        {
            self.loading.hidden = YES;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed!" message:@"Please check your internet connection" preferredStyle:UIAlertControllerStyleAlert];
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
