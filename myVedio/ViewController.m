//
//  ViewController.m
//  myVedio
//
//  Created by Rawan Marzouq on 4/13/16.
//  Copyright © 2016 Rawan. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVKit/AVKit.h>
#include <CFNetwork/CFNetwork.h>
#import <Photos/Photos.h>
#import "Video.h"
#import "VideoDetailsViewController.h"
#import "AppointmentsListViewController.h"
#import <AFNetworking.h>


#define preURL @"http://salesappointmentsinabox.com/api/public"

enum {
    kSendBufferSize = 32768
};


@interface ViewController ()<UIDocumentInteractionControllerDelegate,NSStreamDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
    NSMutableArray *videosArray;
}
- (IBAction)recordButton:(id)sender;
//- (IBAction)playbackButton:(id)sender;


@property (nonatomic, strong, readwrite) NSOutputStream *  networkStream;
@property (nonatomic, strong, readwrite) NSInputStream *   fileStream;
@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;
@property (weak, nonatomic) IBOutlet UITableView *videosTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property(nonatomic, strong)UIAlertAction *okAction;
@end

@implementation ViewController
{
    uint8_t                     _buffer[kSendBufferSize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Custom Album App
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         //Checks for App Photo Album and creates it if it doesn't exist
         PHFetchOptions *fetchOptions = [PHFetchOptions new];
         fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title == %@", @"MyVideos"];
         PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:fetchOptions];
         PHAssetCollectionChangeRequest *albumRequest;
         if (fetchResult.count == 0)
         {
             //Create Album
             albumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"MyVideos"];
           
         }
         
         
         
     }
     
                                      completionHandler:^(BOOL success, NSError *error)
     {
         NSLog(@"Log here...");
         
         if (!success) {
             NSLog(@"Error creating album: %@", error);
         }else{
             NSLog(@"Perfecto");
             
         }
     }];
    self.loadingLabel.hidden = YES;
//    // Load Videos List
//    [self LoadVideos];
    
    self.navigationItem.title = @"All Videos";

}

-(void)viewDidAppear:(BOOL)animated
{
    // Load Videos List
    [self LoadVideos];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  pragma-mark Buttons
- (IBAction)recordButton:(id)sender {
    
    UIAlertController *alertRef = [UIAlertController alertControllerWithTitle:@"Video Title" message:@"Please enter your video title (3 characters at least)" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertRef addTextFieldWithConfigurationHandler:^(UITextField *textField) {
       
        textField.delegate = self;
    }];
    
    
    self.okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *videoTitle = [alertRef.textFields objectAtIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:videoTitle.text forKey:@"userVideoTitle"];
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            
            UIImagePickerController *picker = [[UIImagePickerController alloc]init];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.delegate = self;
            picker.allowsEditing = NO;
            picker.videoMaximumDuration = 30;
            
            NSArray *mediaTypes = [[NSArray alloc]initWithObjects:(NSString *)kUTTypeMovie, nil];
            
            picker.mediaTypes = mediaTypes;
            
            [self presentViewController:picker animated:YES completion:nil];
            
        } else {
            
            UIAlertController *alertView = [[UIAlertController alloc]  init];
            alertView.title = nil;
            alertView.message = @"I'm afraid there's no camera on this device!";
            
            [alertView presentationController];
        }

    }];

    self.okAction.enabled = NO;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }];
    [alertRef addAction:self.okAction];
    [alertRef addAction:cancelAction];
    [self presentViewController:alertRef animated:YES completion:nil];
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.okAction setEnabled:(finalString.length >= 3)];
    return YES;
}
//- (IBAction)playbackButton:(id)sender {
//    
//    // pick a video from the documents directory
//    NSURL *video = [self grabFileURL:@"video.mov"];
//    
//    // create a movie player view controller
//    MPMoviePlayerViewController * controller = [[MPMoviePlayerViewController alloc]initWithContentURL:video];
//    [controller.moviePlayer prepareToPlay];
//    [controller.moviePlayer play];
//    
//    // and present it
//    [self presentViewController:controller animated:YES completion:nil];
//    
//}
- (NSURL*)grabFileURL:(NSString *)fileName {
    
    // find Documents directory
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    // append a file name to it
    documentsURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    return documentsURL;
}


#pragma mark - Delegate Methods  - Photos Framework

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    // user hit cancel
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    // grab our movie URL
    NSURL *chosenMovie = [info objectForKey:UIImagePickerControllerMediaURL];
    NSLog(@"chosenMovie: %@",chosenMovie);
    // save it to the documents directory
    NSURL *fileURL = [self grabFileURL:@"video.mov"];
    NSLog(@"fileURL: %@",fileURL);
    NSData *movieData = [NSData dataWithContentsOfURL:chosenMovie];
    [movieData writeToURL:fileURL atomically:YES];
    
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *videoPath = [documentsDirectory stringByAppendingPathComponent:@"video.mov"];

    
    // save it to the Camera Roll
    UISaveVideoAtPathToSavedPhotosAlbum([chosenMovie path], nil, nil, nil);
    
    // Custom Album App
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         //Checks for App Photo Album and creates it if it doesn't exist
         PHFetchOptions *fetchOptions = [PHFetchOptions new];
         fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title == %@", @"MyVideos"];
         PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:fetchOptions];
         PHAssetCollectionChangeRequest *albumRequest;
         if (fetchResult.count == 0)
         {
             //Create Album
             albumRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"MyVideos"];
             PHAssetChangeRequest *createImageRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:videoPath]];
             NSLog(@"[NSURL URLWithString:videoPath]: %@",[NSURL URLWithString:videoPath]);
             [albumRequest addAssets:@[createImageRequest.placeholderForCreatedAsset]];
         }
         else
         {
             PHAssetCollection *collection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                   subtype:PHAssetCollectionSubtypeAny
                                                                   options:fetchOptions].firstObject;

             albumRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
             PHAssetChangeRequest *createImageRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:videoPath]];
             NSLog(@"[NSURL URLWithString:videoPath]: %@",[NSURL URLWithString:videoPath]);
             [albumRequest addAssets:@[createImageRequest.placeholderForCreatedAsset]];
         }
         
         
     }
     
                                      completionHandler:^(BOOL success, NSError *error)
     {
         NSLog(@"Log here...");
         
         if (!success) {
             NSLog(@"Error creating album: %@", error);
         }else{
             NSLog(@"Perfecto");
             
         }
     }];
    
    // Loading Shown
    self.loading.hidden = NO;
    
    // upload to the server
    // HTTP
    [self uploadVideo:fileURL];
    

    // and dismiss the picker
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark - HTTP Load
-(void)LoadVideos
{
    NSLog(@"LOAD Again");
    self.loading.hidden = NO;
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    //Create an URLRequest
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/videos?user_id=%@",preURL,[[NSUserDefaults standardUserDefaults] stringForKey:@"userId"]]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];

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
            NSArray *videos = [jsonObjects objectForKey:@"data"];
            if (videos) {
                videosArray = [[NSMutableArray alloc]init];
                for (int i = 0; i < [videos count]; i++) {
                    NSDictionary *videoData = (NSDictionary*) [videos objectAtIndex:i];
                    Video *currVideo = [[Video alloc]init];
                    currVideo.videoId = [[videoData objectForKey:@"id"] intValue];
                    currVideo.name = [videoData objectForKey:@"name"];
                    currVideo.date = [videoData objectForKey:@"created_at"];
                    [videosArray addObject:currVideo];
                    
                }
                [self.videosTable reloadData];
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
    [self.videosTable reloadData];
}
#pragma mark - HTTP Upload
-(void)uploadVideo:(NSURL*)path
{
    self.loadingLabel.hidden = NO;
    self.loading.hidden = NO;
    NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
    [_params setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"userId"] forKey:@"user_id"];
    [_params setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"userVideoTitle"] forKey:@"name"];
    [_params setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"key"] forKey:@"X-Authorization"];
    
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:[NSString stringWithFormat:@"%@/videos/store",preURL] parameters:_params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:path name:@"file" fileName:[[NSUserDefaults standardUserDefaults] stringForKey:@"userVideoTitle"] mimeType:@"video/quicktime" error:nil];
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask;
    uploadTask = [manager
                  uploadTaskWithStreamedRequest:request
                  progress:^(NSProgress * _Nonnull uploadProgress) {
                      // This is not called back on the main queue.
                      // You are responsible for dispatching to the main queue for UI updates
                      dispatch_async(dispatch_get_main_queue(), ^{
                          //Update the progress view
                          //                          [progressView setProgress:uploadProgress.fractionCompleted];
                          NSLog(@"PROGRESS: %f",uploadProgress.fractionCompleted);
                          self.loadingLabel.hidden = NO;
                          self.loading.hidden = NO;
                          self.loadingLabel.text = [NSString stringWithFormat:@"Uploading %.2f%% ...",uploadProgress.fractionCompleted * 100];
                          if (uploadProgress.fractionCompleted == 1) {
                              self.loadingLabel.text = [NSString stringWithFormat:@"Almost done..."];
                          }
                      });
                  }
                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                      if (error) {
                          NSLog(@"Error: %@", error);
                      } else {
                          NSLog(@"%@ %@", response, responseObject);
                          self.loadingLabel.hidden = YES;
                          self.loading.hidden = YES;
                          [self LoadVideos];
                      }
                  }];
    
    [uploadTask resume];
}

- (NSData *)generatePostDataForData:(NSData *)uploadData
{
    // Generate the post header:
    NSString *post = [NSString stringWithCString:"--AaB03x\r\nContent-Disposition: form-data; name=\"upload[file]\"; filename=\"somefile\"\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n" encoding:NSASCIIStringEncoding];
    
    // Get the post header int ASCII format:
    NSData *postHeaderData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    // Generate the mutable data variable:
    NSMutableData *postData = [[NSMutableData alloc] initWithLength:[postHeaderData length] ];
    [postData setData:postHeaderData];
    
    // Add the image:
    [postData appendData: uploadData];
    
    // Add the closing boundry:
    [postData appendData: [@"\r\n--AaB03x--" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    
    // Return the post data:
    return postData;
}

#pragma mark - Delegate Methods  - Table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [videosArray count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    NSString *cellIdentifier = @"cellIdentifier";
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        if ([videosArray count]) {
            Video *video = (Video*)[videosArray objectAtIndex:indexPath.row];
            cell.textLabel.text = video.name;
            cell.detailTextLabel.text = video.date;
            cell.tag = video.videoId;
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//        cell.textLabel.text = @"VideoName";
        
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.videosTable cellForRowAtIndexPath:indexPath];
    NSInteger videoId = cell.tag;
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)videoId] forKey:@"videoId"];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Actions" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *createAppointment = [UIAlertAction actionWithTitle:@"Create Appointment" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Appointment");
        
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        VideoDetailsViewController *video = [sb instantiateViewControllerWithIdentifier:@"VideoDetails"];
        [self.navigationController pushViewController:video animated:YES];

    }];
    [alert addAction:createAppointment];
    
    UIAlertAction *appointmentsList = [UIAlertAction actionWithTitle:@"Appointments List" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"LIST");
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AppointmentsListViewController *appList = [sb instantiateViewControllerWithIdentifier:@"AppointmentsList"];
        [self.navigationController pushViewController:appList animated:YES];

    }];
    [alert addAction:appointmentsList];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        NSLog(@"DELETE");
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Confirmation" message:@"You are going to delete this video with its appointments.\n Are you sure?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *DeleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSLog(@"YES DELETE");
            self.loading.hidden = NO;
            NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
            
            NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"userId"];
            UITableViewCell *cell = [self.videosTable cellForRowAtIndexPath:indexPath];
            NSInteger videoId = cell.tag;
            //Create an URLRequest
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/videos/delete/%@/%li",preURL,userId,(long)videoId]];
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
            
            [urlRequest setHTTPMethod:@"DELETE"];
            
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
                    if (![[jsonObjects objectForKey:@"data"]objectForKey:@"success"])
                    {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete opertation Failed!" message:[NSString stringWithFormat:@"%@",error] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        }];
                        [alert addAction:cancelAction];
                        [self presentViewController:alert animated:YES completion:nil];
                        NSLog(@"%@",error);
                    }
                    else
                    {
                        [self LoadVideos];
                    }
                }
                else
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Operation Failed!" message:@"Please check your internet connection" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    }];
                    [alert addAction:cancelAction];
                    [self presentViewController:alert animated:YES completion:nil];
                    NSLog(@"%@",error);
                    
                }
            }];
            
            [dataTask resume];
            

        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        
        [alert addAction:DeleteAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        

    }
}
#pragma mark-Sharing List

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
//    [self sendDidStopWithStatus:statusString];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
#pragma unused(aStream)
    assert(aStream == self.networkStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
//            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
//            [self updateStatus:@"Sending"];
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
                
                if (bytesRead == -1) {
                    [self stopSendWithStatus:@"File read error"];
                } else if (bytesRead == 0) {
                    [self stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}
#pragma mark * Core transfer code

// This is the code that actually does the networking.

// Because buffer is declared as an array, you have to use a custom getter.
// A synthesised getter doesn't compile.

- (uint8_t *)buffer
{
    return self->_buffer;
}
- (IBAction)SignOut:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:NULL forKey:@"key"];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *loginVC =  [storyboard instantiateViewControllerWithIdentifier:@"Login"];
    
    [self presentViewController:loginVC animated:NO completion:nil];
}



@end
