//
//  PSTExampleDelegate.h
//  PSTDelegateExample
//
//  Created by Peter Steinberger on 30/07/13.
//  Copyright (c) 2013 Peter Steinberger. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PSTExampleDelegate <NSObject>

@optional

- (void)exampleDelegateCalledWithString:(NSString *)string;

- (BOOL)exampleDelegateThatReturnsBOOL;

- (BOOL)exampleDelegateThatReturnsBOOLAndIsImplemented;

@property (nonatomic, assign, readonly) BOOL delegateProperty;

@end
