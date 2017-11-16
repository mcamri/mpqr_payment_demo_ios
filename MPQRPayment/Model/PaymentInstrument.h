//
//  PaymentInstrument.h
//  MPQRPayment
//
//  Created by Muchamad Chozinul Amri on 25/10/17.
//  Copyright © 2017 Mastercard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLMPaymentInstrument;
/**
 Used to store cards information of the user
 The class is used both in server and app
 */
@interface PaymentInstrument : NSObject

@property long id;
@property NSString* acquirerName;
@property NSString* issuerName;
@property NSString* name;
@property NSString* methodType;
@property double balance;
@property NSString* maskedIdentifier;
@property NSString* currencyNumericCode;
@property BOOL isDefault;

+ (instancetype) PaymentInstrumentFromRLMPaymentInstrument:(RLMPaymentInstrument*) rlmPaymentInstrument;

@end
