//
//  User.m
//  MPQRPayment
//
//  Created by Muchamad Chozinul Amri on 25/10/17.
//  Copyright © 2017 Muchamad Chozinul Amri. All rights reserved.
//

#import "User.h"

@implementation User

- (BOOL) isEqual:(id _Nullable)object
{
    if (![object isKindOfClass:[User class]]) {
        return false;
    }
    if (self == object) {
        return true;
    }
    User* other = (User*) object;
    BOOL idEqual = self.id == other.id;
    BOOL firstNameEqual = (!self.firstName && !other.firstName) ||[self.firstName isEqualToString:other.firstName];
    BOOL lastNameEqual = (!self.lastName && !other.lastName) ||[self.lastName isEqualToString:other.lastName];
    BOOL paymentInstrumentsEqual = (!self.paymentInstruments && !other.paymentInstruments) || [self.paymentInstruments isEqual:other.paymentInstruments];
    BOOL transactionsEqual = (!self.transactions && !other.transactions) || [self.transactions isEqual:other.transactions];
    
    return idEqual
    && firstNameEqual
    && lastNameEqual
    && paymentInstrumentsEqual
    && transactionsEqual;
}

- (NSUInteger)hash
{
    NSUInteger totalInt=0;
    totalInt += _id;
    totalInt += [_firstName hash];
    totalInt += [_lastName hash];
    totalInt += [_paymentInstruments hash];
    totalInt += [_transactions hash];
    return totalInt;
}

@end