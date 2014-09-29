//
//  ViewController.h
//  CentralCB
//
//  Created by Andrey Karaban on 21/07/14.
//  Copyright (c) 2014 AkA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, UIAlertViewDelegate>


@property (strong, nonatomic)CBCentralManager *centralManager;
@property (strong, nonatomic)CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic)NSMutableData *dataToRecieve;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UIButton *disconnectBtn;

//- (IBAction)connect:(id)sender;
//- (IBAction)disconnect:(id)sender;
//
@end
