//
//  BaseRequest.m
//  MPQRPayment
//
//  Created by Muchamad Chozinul Amri on 31/10/17.
//  Copyright © 2017 Mastercard. All rights reserved.
//

#import "BaseRequest.h"

@implementation BaseRequest

///Initializer of the request with acceess code
- (id _Nonnull) initWithAccessCode:(NSString* _Nonnull) accessCode
{
    if (self = [super init]) {
        _accessCode = accessCode;
    }
    return self;
}

@end
