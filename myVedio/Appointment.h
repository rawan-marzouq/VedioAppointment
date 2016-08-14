//
//  Appointment.h
//  myVedio
//
//  Created by Rawan Marzouq on 5/1/16.
//  Copyright © 2016 Rawan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Appointment : NSObject
@property(nonatomic,retain) NSString *customerName;
@property(nonatomic, retain) NSString *date;
@property(nonatomic, retain) NSString *time;
@property(nonatomic, retain) NSString *URL;
@end
