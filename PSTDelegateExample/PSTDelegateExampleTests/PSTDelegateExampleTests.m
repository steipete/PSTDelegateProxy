//
//  PSTDelegateExampleTests.m
//  PSTDelegateExampleTests
//
//  Created by Peter Steinberger on 30/07/13.
//  Copyright (c) 2013 Peter Steinberger. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../PSTDelegateExample/PSTExampleDelegate.h"
#import "../../PSTDelegateProxy.h"

@interface TestDelegate : NSObject<PSTExampleDelegate> @end
@implementation TestDelegate @end

@interface PSTDelegateExampleTests : XCTestCase <PSTExampleDelegate> {
    NSString *_delegateString;
}
@end

@implementation PSTDelegateExampleTests

- (void)testDelegateBeingCalled {
    _delegateString = nil;

    PSTDelegateProxy *delegateProxy = [[PSTDelegateProxy alloc] initWithDelegate:self];
    [(id<PSTExampleDelegate>)delegateProxy exampleDelegateCalledWithString:@"Test"];
    XCTAssertEqualObjects(_delegateString, @"Test");
}

- (void)testDelegateBeingCalledWithReturnValue {
    PSTDelegateProxy *delegateProxy = [[PSTDelegateProxy alloc] initWithDelegate:self];

    BOOL delegateReturnNO = [(id<PSTExampleDelegate>)delegateProxy exampleDelegateThatReturnsBOOL];
    XCTAssertFalse(delegateReturnNO, @"Must be false.");

    BOOL delegateReturnYES = [(id<PSTExampleDelegate>)(delegateProxy.YESDefault) exampleDelegateThatReturnsBOOL];
    XCTAssertTrue(delegateReturnYES, @"Must be true.");
}

- (void)testDelegateBeingCalledWithReturnValueThatIsImplemented {
    PSTDelegateProxy *delegateProxy = [[PSTDelegateProxy alloc] initWithDelegate:self];

    BOOL delegateReturnYES = [(id<PSTExampleDelegate>)delegateProxy exampleDelegateThatReturnsBOOLAndIsImplemented];
    XCTAssertTrue(delegateReturnYES, @"Must be true.");
}

- (void)testRespondsToSelectorForwarding {
    PSTDelegateProxy *delegateProxy = [[PSTDelegateProxy alloc] initWithDelegate:self];
    XCTAssertTrue([delegateProxy respondsToSelector:@selector(exampleDelegateCalledWithString:)], @"Must be true.");
    XCTAssertFalse([delegateProxy respondsToSelector:@selector(exampleDelegateThatReturnsBOOL)], @"Must be false.");
}

- (void)testThatProxyCanDealWithNilledOutDelegates {
    PSTDelegateProxy *delegateProxy;
    @autoreleasepool {
        TestDelegate *delegate = [TestDelegate new];
        delegateProxy = [[PSTDelegateProxy alloc] initWithDelegate:delegate];
    }
    // At this stage, delegate must be nil
    XCTAssertTrue(delegateProxy.delegate == nil, @"Delegate must be nil");
    [(id<PSTExampleDelegate>)delegateProxy exampleDelegateCalledWithString:@"Test"];
}

// Ensure caching works.
- (void)testThatProxyCanDealWithNilledOutDelegatesCached {
    [self testThatProxyCanDealWithNilledOutDelegates];

    PSTDelegateProxy *delegateProxy;
    @autoreleasepool {
        TestDelegate *delegate = [TestDelegate new];
        delegateProxy = [[PSTDelegateProxy alloc] initWithDelegate:delegate];
    }
    // At this stage, delegate must be nil
    XCTAssertTrue(delegateProxy.delegate == nil, @"Delegate must be nil");
    [(id<PSTExampleDelegate>)delegateProxy exampleDelegateCalledWithString:@"Test"];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSTExampleDelegate

- (void)exampleDelegateCalledWithString:(NSString *)string {
    _delegateString = string;
}

- (BOOL)exampleDelegateThatReturnsBOOLAndIsImplemented {
    return YES;
}

@end
