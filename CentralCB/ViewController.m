//
//  ViewController.m
//  CentralCB
//
//  Created by Andrey Karaban on 21/07/14.
//  Copyright (c) 2014 AkA. All rights reserved.
//

#import "ViewController.h"
#import "TransferService.h"

@interface ViewController ()

@end

@implementation ViewController


@synthesize centralManager, discoveredPeripheral, dataToRecieve;

#pragma mark LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    NSLog(@"TTTTT-->%@", centralManager);
    
    dataToRecieve = [[NSMutableData alloc]init];
    _disconnectBtn.hidden = YES;
    _connectBtn.hidden = YES;
    [self scan];
}

 - (void)viewWillDisappear:(BOOL)animated
{
    [centralManager.self stopScan];
    NSLog(@"D I S A P P E A R");
    [super viewWillDisappear:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma  mark - Alerts

- (void)AlertNotSupportedLE
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"WARNING" message:@"Your device doesn't support BTLE" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    alert.tag = 111;
    [alert show];
}

- (void)ALertRecievedData
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Hello World!!" message:@"GO YANKIES!!!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    alert.tag = 222;
    [alert show];
}

#pragma mark - Central Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch(central.state)
    {
        case CBCentralManagerStatePoweredOn:
            return;
            break;
        default:
            break;
    }
}

- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
    
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -35) {
        return;
    }
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral)
    {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.centralManager connectPeripheral:peripheral options:nil];
        _disconnectBtn.hidden = YES;
    }
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}

/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.dataToRecieve setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
        NSLog(@"D I S C O V E R E D _ S E R V I C E %@", service);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"111"])
    {
        
        [self ALertRecievedData];
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
    if ([stringFromData isEqualToString:@"222"])
    {
        
        [self AlertNotSupportedLE];
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
    
    if ([stringFromData isEqualToString:@"0"])
    {
        
                                    // It is notifying, so unsubscribe
                [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                 centralManager = nil;
                   NSLog(@"KAK TUT NASH MANAGER --- %@", centralManager);
                centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
                 NSLog(@"KAK TUT NASH MANAGER BL9Tb--- %@", centralManager);
                 [self scan];
                
                _connectBtn.hidden = YES;
                _disconnectBtn.hidden = YES;
                 // And we're done.
                NSLog(@"S CA N mat' Ego opyat");
     
    
    // Otherwise, just add the data on to what we already have
    [self.dataToRecieve appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];

    }
}

- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!self.discoveredPeripheral.isConnected)
    {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services == nil)
    {
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                    options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    }
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying == NO) {
                          
                            NSLog(@"B O O O MMMM");
                    }
                }
            }
        }
    }
    }
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
//    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


//#pragma mark - ActionBtn
//
//- (IBAction)connect:(id)sender
//{
//    centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
//    [self scan];
//    NSLog(@"Scanning for peripherals...");
//
//}
//
//- (IBAction)disconnect:(id)sender
//{
//    centralManager = nil;
//    if (discoveredPeripheral.isConnected == YES)
//    {
//        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
//        NSLog(@"  ------->>>>  %@", discoveredPeripheral);
//        discoveredPeripheral = nil;
//        NSLog(@"  ------->>>>  %@", discoveredPeripheral);
//    }else
//    {
//        NSLog(@"D-S-C-o-n-N-E-C-T-Ed!!!");
//        _connectBtn.hidden = NO;
//        _disconnectBtn.hidden = YES;
//    }
// 
//}
//




@end
