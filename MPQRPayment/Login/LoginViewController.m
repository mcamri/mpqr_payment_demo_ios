//
//  LoginViewController.m
//  MPQRPayment
//
//  Created by Muchamad Chozinul Amri on 26/10/17.
//  Copyright © 2017 Mastercard. All rights reserved.
//

#import "LoginViewController.h"
#import "MPQRService.h"
#import "LoginManager.h"
#import "User.h"
#import "PaymentInstrument.h"
#import "DialogViewController.h"
#import "LoginRequest.h"

@interface LoginViewController ()


@property LoginViewControllerCompletionBlock _Nullable completionBlockSuccess;
@property LoginViewControllerCompletionBlock _Nullable completionBlockFail;

@property (weak, nonatomic) IBOutlet UITextField *accessCode;
@property (weak, nonatomic) IBOutlet UITextField *pin;
@property (weak, nonatomic) IBOutlet UIView *section4;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    // Do any additional setup after loading the view.
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
    
    [self setInitialAccesscode];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
- (IBAction)signIn:(id)sender {
    NSString* strAccessCode = _accessCode.text;
    NSString* strPin = _pin.text;
    
    if (![self isValidAccessCode:strAccessCode pin:strPin]) {
        DialogViewController* dialogVC = [DialogViewController new];
        dialogVC.dialogMessage = @"Invalid access code or pin, please enter a valid access code and 6 digit pin.";
        dialogVC.positiveResponse = @"OK";
        [dialogVC showDialogWithContex:self
                     withYesBlock:^(DialogViewController* dialog){
                     } withNoBlock:^(DialogViewController* dialog){
                     }];
        return;
    }
    
    
    LoginRequest* lRequest = [[LoginRequest alloc] initWithAccessCode:strAccessCode pin:strPin];
    
    [[MPQRService sharedInstance] loginWithParameters:lRequest
                                              success:^(LoginResponse* lResponse){
                                                  [LoginManager sharedInstance].loginInfo = lResponse;
                                                  [self dismissViewControllerAnimated:YES completion:^(){
                                                      _completionBlockSuccess(self);
                                                  }];
                                              } failure:^(NSError* error){
                                                  DialogViewController* dialogVC = [DialogViewController new];
                                                  dialogVC.dialogMessage = @"Login failed, please enter a valid access code and 6 digit pin.";
                                                  dialogVC.positiveResponse = @"OK";
                                                  [dialogVC showDialogWithContex:self
                                                                    withYesBlock:^(DialogViewController* dialog){
                                                                    } withNoBlock:^(DialogViewController* dialog){
                                                                    }];
                                              }];
    
}

- (BOOL) isValidAccessCode:(NSString*) accessCode pin:(NSString*) pin
{
    if (accessCode.length == 0) {
        return false;
    }
    if (pin.length != 6) {
        return false;
    }
    return true;
}


#pragma mark - textfield movement
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void) setInitialAccesscode
{
    if (_accessCode.text.length == 0) {
        _accessCode.text = [LoginManager sharedInstance].lastUser;
    }
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

#pragma mark - Present Self
- (void) showDialogWithContex:(UIViewController* _Nonnull) vc withYesBlock:(nullable void (^)(LoginViewController* _Nonnull loginVC)) success withNoBlock:(nullable void (^)(LoginViewController* _Nonnull loginVC)) failure
{
    _completionBlockFail = failure;
    _completionBlockSuccess = success;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext | UIModalPresentationFullScreen;
    [vc presentViewController:self animated:NO completion:nil];
}
@end
