//
//  ViewController.m
//  MPQRPayment
//
//  Created by Muchamad Chozinul Amri on 25/10/17.
//  Copyright © 2017 Muchamad Chozinul Amri. All rights reserved.
//

#import "MainViewController.h"
#import "MPQRService.h"
#import "LoginResponse.h"
#import "Transaction.h"
#import "PaymentInstrument.h"
#import "User.h"
#import "LoginViewController.h"
#import "LoginManager.h"
#import "UserManager.h"
#import "PaymentManager.h"
#import "PaymentViewController.h"
#import "TransactionListViewController.h"
#import "DialogViewController.h"
#import "CardChooserViewController.h"
#import "CurrencyFormatter.h"
#import "GetUserInfoRequest.h"
#import "LogoutRequest.h"
#import "ChangeDefaultCardRequest.h"

@import FSPagerView;
@import MasterpassQRScanSDK;
@import AVFoundation;

@interface MainViewController ()<FSPagerViewDataSource, FSPagerViewDelegate>
{
    UIImageView* logoView;
}
@property (weak, nonatomic) IBOutlet UIView *sectionOne;
@property (weak, nonatomic) IBOutlet FSPagerView *pagerView;
@property (weak, nonatomic) IBOutlet UILabel *balanceDisplay;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor blackColor]];
    [[UINavigationBar appearance] setTranslucent:NO];
    

    
    
    _pagerView.dataSource = self;
    _pagerView.delegate = self;
    _pagerView.itemSize = CGSizeMake(180*294/187, 180);
    _pagerView.transformer = [[FSPagerViewTransformer alloc] initWithType:FSPagerViewTransformerTypeOverlap];
    [_pagerView registerClass:[FSPagerViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    UIImage* logo = [UIImage imageNamed:@"masterpassqr_logo"];
    logoView = [[UIImageView alloc] initWithImage:logo];
//
//    UIBarButtonItem* barBtnSetting = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_settings"]
//                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(btnSettingPressed)];
    
    UIBarButtonItem* barBtnLogout = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_logout"]
                                                                     style:UIBarButtonItemStylePlain target:self action:@selector(btnLogoutPressed)];
    self.navigationItem.rightBarButtonItems = @[barBtnLogout
//                                                , barBtnSetting
                                                ];
    
    LoginViewController* loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self.navigationController presentViewController:loginVC animated:YES completion:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSString* strAccessCode = [LoginManager sharedInstance].loginInfo.accessCode;
    if (strAccessCode) {
        GetUserInfoRequest* request = [[GetUserInfoRequest alloc] initWithAccessCode:strAccessCode];
        [[MPQRService sharedInstance] getUserWithParameters:request
                                                    success:^(User* user){
                                                        [UserManager sharedInstance].currentUser = user;
                                                        [self reloadUserInterface];
                                                    } failure:^(NSError* error){
                                                        [self showAlertWithTitle:@"User Not Found" message:@"Related user with this account is not found. Please try again later or contact our administrator."];
                                                    }];
        
    }
    [self reloadUserInterface];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.titleView = logoView;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.titleView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions

- (void) btnSettingPressed
{
}

- (void) btnLogoutPressed
{
    DialogViewController* dvg = [DialogViewController new];
    dvg.dialogMessage = @"Are you sure you want to logout?";
    dvg.positiveResponse = @"YES";
    dvg.negativeResponse = @"CANCEL";
    [dvg showDialogWithContex:self.navigationController
                 withYesBlock:^(DialogViewController* dialog){
                     
                     [LoginManager sharedInstance].loginInfo = nil;
                     [UserManager sharedInstance].currentUser = nil;
                     LoginViewController* loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewController"];
                     [self.navigationController presentViewController:loginVC animated:YES completion:nil];
                     NSString* strAccessCode = [LoginManager sharedInstance].loginInfo.accessCode;
                     [[MPQRService sharedInstance] logoutWithParameters:[[LogoutRequest alloc] initWithAccessCode:strAccessCode]
                                                                success:^(LoginResponse* response){
                                                                } failure:^(NSError* error){
                                                                }];
                     
                 } withNoBlock:^(DialogViewController* dialog){
                 }];
}

- (IBAction)openTransactionHistory:(id)sender {
    
    TransactionListViewController* transactionVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TransactionListViewController"];
    [self.navigationController pushViewController:transactionVC animated:YES];
}

- (IBAction)startScan:(id)sender {
    if (![QRCodeReader isAvailable] || ![QRCodeReader supportsQRCode]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self checkCameraPermission: ^{
        
        __block __weak QRCodeReader* reader;
        QRCodeReaderViewController* qrVC = [QRCodeReaderViewController readerWithBuilderBlock:^(QRCodeReaderViewControllerBuilder *builder){
            reader = builder.reader;
        }];
        
        //block to read the result
        [reader setCompletionWithBlock:^(NSString *result) {
            [reader stopScanning];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [[PaymentManager sharedInstance] parseScannedCode:result withCompletionBlock:^(PaymentData* pdata, NSError* error){
                    if (pdata) {
                        PaymentViewController* pVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PaymentViewController"];
                        pVC.paymentData = pdata;
                        [self.navigationController pushViewController:pVC animated:YES];
                    }else{
                        [self showAlertWithTitle:@"Error while scanning" message:@"Cannot scan QR code successfully. Please try again."];
                    }
                }];
            }];
        }];
        
        //block when cancel is pressed
        [qrVC setCompletionWithBlock:^(NSString *result) {
            [reader stopScanning];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }];
        
        [weakSelf.navigationController presentViewController:qrVC animated:true completion:nil];
    }];
}

# pragma mark - QRCodeReaderViewController
// Check camera permissions
- (void)checkCameraPermission:(void (^)(void))completion {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied) {
        [self showAlertWithTitle:@"Error" message: @"Camera permissions are required for scanning QR. Please turn on Settings -> MasterpassQR Demo -> Camera"];
        return;
    } else if (status == AVAuthorizationStatusRestricted) {
        [self showAlertWithTitle:@"Error" message: @"Camera permissions are restricted for scanning QR"];
        return;
    } else if (status == AVAuthorizationStatusAuthorized) {
        completion();
    } else if (status == AVAuthorizationStatusNotDetermined) {
        __weak __typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    completion();
                } else {
                    [weakSelf showAlertWithTitle:@"Error" message: @"Camera permissions are required for scanning QR. Please turn on Settings -> MasterpassQR Demo -> Camera"];
                }
            });
        }];
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    DialogViewController* dialogVC = [DialogViewController new];
    dialogVC.dialogMessage = message;
    dialogVC.positiveResponse = @"OK";
    [dialogVC showDialogWithContex:self
                      withYesBlock:^(DialogViewController* dialog){
                      } withNoBlock:^(DialogViewController* dialog){
                      }];
}

#pragma mark - Update UI
- (void) reloadUserInterface
{
    [_pagerView reloadData];
    [self reloadCarfInfo];
}

- (void) reloadCarfInfo
{
    int index = [[UserManager sharedInstance] getDefaultCardIndex];
    if (index != -1) {
        // Delay 2 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_pagerView scrollToItemAtIndex:index animated:NO];
            RLMArray<PaymentInstrument*><PaymentInstrument> *instruments = [UserManager sharedInstance].currentUser.paymentInstruments;
            PaymentInstrument* instr = [instruments objectAtIndex:index];
            _balanceDisplay.text = [CurrencyFormatter getFormattedAmountWithValue:instr.balance];
        });
    }
}

#pragma mark - FSPagerViewDataSource

- (NSInteger)numberOfItemsInPagerView:(FSPagerView * _Nonnull)pagerView {
    return [UserManager sharedInstance].currentUser.paymentInstruments.count;
}

- (FSPagerViewCell * _Nonnull)pagerView:(FSPagerView * _Nonnull)pagerView cellForItemAtIndex:(NSInteger)index {
    FSPagerViewCell *cell = [pagerView dequeueReusableCellWithReuseIdentifier:@"cell" atIndex:index];
    
    RLMArray<PaymentInstrument*><PaymentInstrument> *instruments = [UserManager sharedInstance].currentUser.paymentInstruments;
    PaymentInstrument* instr = [instruments objectAtIndex:index];
    
    NSString* strImageName = @"mastercard_black";
    if ([instr.methodType isEqualToString:@"DebitCard"]) {
        strImageName = @"mastercard_gold";
    }else
    if ([instr.methodType isEqualToString:@"CreditCard"]) {
        strImageName = @"mastercard_black";
    }else
    if ([instr.methodType isEqualToString:@"SavingsAccount"]) {
        strImageName = @"saving_account";
    }
    
    UIImage* image = [UIImage imageNamed:strImageName];
    cell.imageView.image = image;
    return cell;
}


#pragma mark - FSPagerViewDelegate
- (void)pagerView:(FSPagerView *)pagerView didSelectItemAtIndex:(NSInteger)index
{
}

- (void)pagerView:(FSPagerView *)pagerView didHighlightItemAtIndex:(NSInteger)index
{
}

- (void) pagerViewDidScroll:(FSPagerView *)pagerView
{
    static int index;
    if (index != pagerView.currentIndex) {
        index = (int) pagerView.currentIndex;
        NSString* accessCode = [LoginManager sharedInstance].loginInfo.accessCode;
        ChangeDefaultCardRequest* request = [[ChangeDefaultCardRequest alloc] initWithAccessCode:accessCode index:index];
        [[MPQRService sharedInstance] changeDefaultCardWithParameters:request
                                                              success:^(User* user){
                                                                  [UserManager sharedInstance].currentUser = user;
                                                                  [self reloadCarfInfo];
                                                              } failure:^(NSError* error){
                                                                  [self showAlertWithTitle:@"Error" message:@"Cannot change default card at this moment. Please try again."];
                                                              }];
    }
}

@end
