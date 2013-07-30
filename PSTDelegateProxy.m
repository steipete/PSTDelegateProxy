//
// PSTDelegateProxy.m
//
// Copyright (c) 2013 Peter Steinberger (http://petersteinberger.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PSTDelegateProxy.h"
#import <objc/runtime.h>
#import <libkern/OSAtomic.h>

@interface PSTYESDefaultingDelegateProxy : PSTDelegateProxy @end

@implementation PSTDelegateProxy

static volatile CFDictionaryRef _cache = nil;

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithDelegate:(id)delegate {
    return [self initWithDelegate:delegate forceCreation:NO];
}

- (id)initWithDelegate:(id)delegate forceCreation:(BOOL)forceCreation {
    if (!delegate && !forceCreation) return nil; // Exit early if delegate is nil.
    if (self) {
        _delegate = delegate;

        // Ensure we cached all method signatures.
        if (!_cache || !CFDictionaryGetValueIfPresent(_cache, (__bridge const void *)([delegate class]), NULL)) {
            [self cacheMethodSignaturesForProtocolsInObject:delegate];
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p delegate:%@>", self.class, self, self.delegate];
}

- (BOOL)respondsToSelector:(SEL)selector {
    return [self.delegate respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
    id delegate = self.delegate;
    return [delegate respondsToSelector:selector] ? delegate : self;
}

// Required for delegates that don't implement certain methods.
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *signature = [self.delegate methodSignatureForSelector:sel];
    if (!signature) {
        // If the delegate is already nil, we still need the method signature to not crash.
        signature = CFDictionaryGetValue(_cache, sel);
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // ignore
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (instancetype)YESDefault {
    // When we create a proxy delegate with a different return type, we need to force creation.
    // Else we would return NO in the end.
    return [[PSTYESDefaultingDelegateProxy alloc] initWithDelegate:self.delegate forceCreation:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)cacheMethodSignaturesForProtocolsInObject:(id)object {
    static OSSpinLock _lock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&_lock);

    // Copy the signature cache to be mutable.
    CFMutableDictionaryRef newSignatureCache = nil;
    if (_cache) newSignatureCache = CFDictionaryCreateMutableCopy(NULL, 0, _cache);
    else        newSignatureCache = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);

    // Set this class and all parent classes to be cached.
    Class objectClass = [object class];
    do {
        CFDictionarySetValue(newSignatureCache, (__bridge const void *)(objectClass), kCFBooleanTrue);

        // We need to cache method signatures for each protocol.
        unsigned int protocolCount = 0;
        Protocol *__unsafe_unretained* protocols = class_copyProtocolList([object class], &protocolCount);
        for (NSUInteger idx = 0; idx < protocolCount; idx++) {
            [self cacheProtocol:protocols[idx] object:object cache:newSignatureCache];
        }
        free(protocols);
    }while ((objectClass = class_getSuperclass(objectClass)));

    // Save new signature cache.
    CFDictionaryRef oldSignatureCache = _cache;
    _cache = newSignatureCache;
    if (oldSignatureCache) CFRelease(oldSignatureCache);

    OSSpinLockUnlock(&_lock);
}

- (void)cacheProtocol:(Protocol *)protocol object:(id)object cache:(CFMutableDictionaryRef)cache {
    if (!CFDictionaryGetValueIfPresent(cache, (__bridge const void *)(protocol), NULL)) {
        // Set protocol to be cached.
        CFDictionarySetValue(cache, (__bridge const void *)(protocol), kCFBooleanTrue);

        // Get the required method signatures.
        NSUInteger methodCount;
        struct objc_method_description *descriptions = protocol_copyMethodDescriptionList(protocol, NO, YES, &methodCount);
        for (NSUInteger methodIndex = 0; methodIndex < methodCount; methodIndex++) {
            struct objc_method_description description = descriptions[methodIndex];
            NSMethodSignature *signature = [object methodSignatureForSelector:description.name];
            CFDictionarySetValue(cache, description.name, (__bridge const void *)(signature));
        }
        free(descriptions);

        // There might be sub-protocols we need to catch as well...
        unsigned int inheritedProtocolCount;
        Protocol *__unsafe_unretained* subprotocols = protocol_copyProtocolList(protocol, &inheritedProtocolCount);
        for (NSUInteger idx = 0; idx < inheritedProtocolCount; idx++) {
            [self cacheProtocol:subprotocols[idx] object:object cache:cache];
        }
        free(subprotocols);
    }
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSTYESDelegateProxy

@implementation PSTYESDefaultingDelegateProxy

- (void)forwardInvocation:(NSInvocation *)invocation {
    // If method is a BOOL, return YES.
    if (strncmp(invocation.methodSignature.methodReturnType, @encode(BOOL), 1) == 0) {
        BOOL retValue = YES;
        [invocation setReturnValue:&retValue];
    }
}

@end
