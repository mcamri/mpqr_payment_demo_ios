//
//  PaymentViewController.m
//  MPQRPayment
//
//  Created by Muchamad Chozinul Amri on 26/10/17.
//  Copyright © 2017 Muchamad Chozinul Amri. All rights reserved.
//

#import "PaymentViewController.h"
#import "PaymentData.h"
#import "Merchant.h"
#import "MPQRService.h"
#import "Transaction.h"
#import "DialogViewController.h"
#import "PinDialogViewController.h"
#import "LoginManager.h"
#import "ReceiptViewController.h"
#import "CardChooserViewController.h"
#import "UserManager.h"
#import "PaymentInstrument.h"
#import "Receipt.h"
#import "LoginRequest.h"
#import "LoginResponse.h"
#import "ChangeDefaultCardRequest.h"
#import "MakePaymentRequest.h"

@import MasterpassQRCoreSDK;

/*
 @property  long userId;
 @property  long cardId;
 @property  BOOL isDynamic;
 @property  double transactionAmount;
 @property  TipConvenienceIndicator tipType;
 @property  double tip;
 @property  NSString* currencyNumericCode;
 @property  NSString* mobile;
 @property  Merchant* merchant;
 */
@interface PaymentViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *merchantName;
@property (weak, nonatomic) IBOutlet UILabel *merchantCity;
@property (weak, nonatomic) IBOutlet UILabel *currency;
@property (weak, nonatomic) IBOutlet UILabel *currencySecond;
@property (weak, nonatomic) IBOutlet UITextField *amount;
@property (weak, nonatomic) IBOutlet UILabel *flatTipTitle;
@property (weak, nonatomic) IBOutlet UITextField *flatTip;
@property (weak, nonatomic) IBOutlet UILabel *totalAmount;
@property (weak, nonatomic) IBOutlet UILabel *maskedIdentifier;
@property (weak, nonatomic) IBOutlet UIView *section4;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfSecondSection;
@property (weak, nonatomic) IBOutlet UIView *tipSection;

@end

@implementation PaymentViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _merchantName.text = _paymentData.merchant.name;
    _merchantCity.text = _paymentData.merchant.city;
    _currency.text = [CurrencyEnumLookup getAlphaCode:[CurrencyEnumLookup enumFor:_paymentData.currencyNumericCode]];
    _currencySecond.text = _currency.text;
    PaymentInstrument* instrument = [[UserManager sharedInstance] getuserCardWithID:_paymentData.cardId];
    _maskedIdentifier.text = instrument.maskedIdentifier;
    
    //amount of money
    [self setInitialAmount];
    _amount.delegate = self;
    _flatTip.delegate = self;
    [_amount addTarget:self
                    action:@selector(textFieldDidChange:)
          forControlEvents:UIControlEventEditingChanged];
    [_flatTip addTarget:self
                    action:@selector(textFieldDidChange:)
          forControlEvents:UIControlEventEditingChanged];
    
    //back button
    self.navigationItem.hidesBackButton = TRUE;
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backBtnImage = [UIImage imageNamed:@"back"]  ;
    [backBtn setImage:backBtnImage forState:UIControlStateNormal];
    [backBtn setTitle:@" Back" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(showCancelDialog) forControlEvents:UIControlEventTouchUpInside];
    backBtn.frame = CGRectMake(0, 0, 54, 20);
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn] ;
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    CGRect f = self.section4.frame;
    f.origin.y = self.view.bounds.size.height - f.size.height;
    f.origin.x = 0;
    f.size.width = self.view.bounds.size.width;
    self.section4.frame = f;
    
    [self updateUITotalAmount];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Actions
- (IBAction)changeCard:(id)sender {
    CardChooserViewController* dvg = [CardChooserViewController new];
    dvg.dialogHeight = 400;
    dvg.positiveResponse = @"Select";
    dvg.negativeResponse = @"Cancel";
    [dvg showDialogWithContex:self.navigationController
                 withYesBlock:^(DialogViewController* dialog){
                     CardChooserViewController* cardChooser = (CardChooserViewController*) dialog;
                     int index = (int)cardChooser.selectedIndex;
                     NSString* accessCode = [LoginManager sharedInstance].loginInfo.accessCode;
                     ChangeDefaultCardRequest* request = [[ChangeDefaultCardRequest alloc] initWithAccessCode:accessCode index:index];
                     [[MPQRService sharedInstance] changeDefaultCardWithParameters:request
                                                                           success:^(User* user){
                                                                               [UserManager sharedInstance].currentUser = user;
                                                                               PaymentInstrument* instrument = [[UserManager sharedInstance] getDefaultCard];
                                                                               _paymentData.cardId = instrument.id;
                                                                               _maskedIdentifier.text = instrument.maskedIdentifier;
                                                                           } failure:^(NSError* error){
                                                                               [self showAlertWithTitle:@"Error" message:@"Cannot change default card at this moment. Please try again."];
                                                                           }];
                 } withNoBlock:^(DialogViewController* dialog){
                     
                 }];
}
- (IBAction)pay:(id)sender {
    PinDialogViewController* dvg = [PinDialogViewController new];
    dvg.dialogTitle = @"Enter PIN";
    dvg.dialogDescription = @"Please enter your 6-digit PIN";
    dvg.positiveResponse = @"OK";
    dvg.negativeResponse = @"Cancel";
    [dvg showDialogWithContex:self.navigationController
                 withYesBlock:^(DialogViewController* dialog){
                     
                     PinDialogViewController* pinDialog = (PinDialogViewController*) dialog;
                     NSString* strAccessCode = [LoginManager sharedInstance].loginInfo.accessCode;
                     NSString* strPin = pinDialog.pin;
                     
                     LoginRequest* lRequest = [[LoginRequest alloc] initWithAccessCode:strAccessCode pin:strPin];
                     
                     [[MPQRService sharedInstance] loginWithParameters:lRequest
                                                               success:^(LoginResponse* lResponse){
                                                                   [LoginManager sharedInstance].loginInfo = lResponse;
                                                                   NSNumber* senderId = [NSNumber numberWithInteger:_paymentData.userId];
                                                                   NSNumber* cardID = [NSNumber numberWithInteger:_paymentData.cardId];
                                                                   NSString* mastercardID = _paymentData.merchant.identifierMastercard04;
                                                                   NSString* merchantName = _paymentData.merchant.name;
                                                                   NSString* currency = _paymentData.currencyNumericCode;
                                                                   NSNumber* transactionAmountTotal = [NSNumber numberWithDouble:[self calculateTotalAmount]];
                                                                   NSNumber* tip = [NSNumber numberWithDouble:[self calculateTipAmount]];
                                                                   NSString* terminalNumber = _paymentData.merchant.terminalNumber;
//                                                                   NSDictionary* parameter = @{@"sender_id":senderId,
//                                                                                               @"sender_card_id":cardID,
//                                                                                               @"receiver_card_number":mastercardID?mastercardID:@"",
//                                                                                               @"receiver_name":merchantName?merchantName:@"",
//                                                                                               @"currency": currency?currency:@"",
//                                                                                               @"transaction_amount_total": transactionAmount,
//                                                                                               @"tip":tip,
//                                                                                               @"terminal_number": terminalNumber?terminalNumber:@""
//                                                                                               };
                                                                   
                                                                   MakePaymentRequest* request = [[MakePaymentRequest alloc]
                                                                                                  initWithAccesCode:strAccessCode
                                                                                                  senderID:senderId.integerValue
                                                                                                  senderCardID:cardID.integerValue
                                                                                                  receiverCardNumber:mastercardID?mastercardID:@""
                                                                                                  receiverName:merchantName?merchantName:@""
                                                                                                  currency:currency?currency:@""
                                                                                                  transactionAmountTotal:transactionAmountTotal.doubleValue
                                                                                                  tipAmount:tip.doubleValue
                                                                                                  terminalNumber:terminalNumber?terminalNumber:@""];
                                                                   [[MPQRService sharedInstance] makePaymentWithParameters:request
                                                                                                                   success:^(Transaction* transaction){
                                                                                                                           ReceiptViewController* receiptVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                                                                                                                                               instantiateViewControllerWithIdentifier:@"ReceiptViewController"];
                                                                                                                           receiptVC.receipt = [[Receipt alloc] initWithTransaction:transaction paymentData:_paymentData];
                                                                                                                           [self.navigationController pushViewController:receiptVC animated:YES];
                                                                                                                   } failure:^(NSError* error){
                                                                                                                       
                                                                                                                   }];
                                                               } failure:^(NSError* error){
                                                                   [self showAlertWithTitle:@"Verifiecation failed" message:@"Please enter valid 6 digit pin."];
                                                               }];
                 } withNoBlock:^(DialogViewController* dialog){
                     
                 }];
}

- (void) showCancelDialog{
    DialogViewController* dvg = [DialogViewController new];
    dvg.dialogMessage = @"Do you want to cancel?";
    dvg.positiveResponse = @"YES";
    dvg.negativeResponse = @"NO";
    [dvg showDialogWithContex:self.navigationController
                 withYesBlock:^(DialogViewController* dialog){
                     [self.navigationController popViewControllerAnimated:YES];
                 } withNoBlock:^(DialogViewController* dialog){
                 }];
}


#pragma mark - textfield movement
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    text = [text stringByReplacingOccurrencesOfString:@"." withString:@""];
    double number = [text intValue] * 0.01;
    textField.text = [NSString stringWithFormat:@"%.2lf", number];
    [self textFieldDidChange:textField];
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self updateUITotalAmount];
}

#pragma mark - Tips and Amount Calculation
- (void) setInitialAmount
{

    _amount.text = [NSString stringWithFormat:@"%.2lf", _paymentData.transactionAmount];
    if((int)_paymentData.transactionAmount)
    {
        _amount.enabled = false;
    }else
    {
        _amount.enabled = true;
    }
    
    switch (_paymentData.tipType) {
        case percentageConvenienceFee:
            _flatTip.text = [NSString stringWithFormat:@"%.2lf %%", _paymentData.tip];
            _flatTip.enabled = false;
            break;
        case flatConvenienceFee:
            _flatTip.text = [NSString stringWithFormat:@"%.2lf", _paymentData.tip];
            _flatTip.enabled = false;
            break;
        case promptedToEnterTip:
            _flatTip.text = [NSString stringWithFormat:@"%.2lf", _paymentData.tip];
            _flatTip.enabled = true;
            break;
        default:
            _tipSection.hidden = TRUE;
            _heightOfSecondSection.constant = 98;
            break;
    }
}

- (void) updateUITotalAmount
{
    _totalAmount.text = [NSString stringWithFormat:@"%.2lf", [self calculateTotalAmount]];
    switch (_paymentData.tipType) {
        case percentageConvenienceFee:
        case flatConvenienceFee:
        case promptedToEnterTip:
            break;
        default:
            _tipSection.hidden = TRUE;
            _heightOfSecondSection.constant = 98;
            break;
    }
}


- (double) calculateTotalAmount
{
    double totalAmount = 0;
    switch (_paymentData.tipType) {
        case percentageConvenienceFee:
        case flatConvenienceFee:
            totalAmount = _amount.text.doubleValue + [_paymentData getTipAmount];
            break;
        case promptedToEnterTip:
            totalAmount = _amount.text.doubleValue + _flatTip.text.doubleValue;
            break;
        default:
            totalAmount = _amount.text.doubleValue;
            break;
    }
    return totalAmount;
}


- (double) calculateTipAmount
{
    double tipAmount = 0;
    switch (_paymentData.tipType) {
        case percentageConvenienceFee:
        case flatConvenienceFee:
            tipAmount = [_paymentData getTipAmount];
            break;
        case promptedToEnterTip:
            tipAmount = _flatTip.text.doubleValue;
            break;
        default:
            break;
    }
    return tipAmount;
}

#pragma mark - keyboard movements
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.section4.frame;
        f.origin.y = self.view.bounds.size.height - f.size.height - keyboardSize.height;
        self.section4.frame = f;
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.section4.frame;
        f.origin.y = self.view.bounds.size.height - f.size.height;
        self.section4.frame = f;
    }];
}

#pragma mark - Helper

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    DialogViewController* dialogVC = [DialogViewController new];
    dialogVC.dialogMessage = message;
    dialogVC.positiveResponse = @"OK";
    [dialogVC showDialogWithContex:self
                      withYesBlock:^(DialogViewController* dialog){
                      } withNoBlock:^(DialogViewController* dialog){
                      }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
