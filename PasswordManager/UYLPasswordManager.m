//
//  UYLPasswordManager.m
//
//  Created by Keith Harrison on 23-May-2011 http://useyourloaf.com
//  Copyright (c) 2014 Keith Harrison. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//
//  Neither the name of Keith Harrison nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 


#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import "UYLPasswordManager.h"

NSString * const kKeychainService = @"UYLPasswordManager";

@interface UYLPasswordManager ()
- (void)searchKeychain;
- (BOOL)createKeychainValue:(NSString *)password;
- (BOOL)updateKeychainValue:(NSString *)password;
- (void)deleteKeychainValue;
- (NSMutableDictionary *)newSearchDictionary;
- (NSString *)resultCode:(OSStatus)status;
- (CFTypeRef)attributeAccess;
- (void)deviceWillLockOrBackground:(NSNotification *)notification;

@property (nonatomic,strong) NSString *keychainValue;
@property (nonatomic,copy) NSString *keychainAccessGroup;
@property (nonatomic,copy) NSString *keychainIdentifier;

@end

@implementation UYLPasswordManager

#pragma mark -
#pragma mark === Shared Instance Methods ===
#pragma mark -

static UYLPasswordManager *_sharedInstance = nil;

+ (UYLPasswordManager *)sharedInstance {
	
	if (_sharedInstance == nil) {
		
		_sharedInstance = [[self alloc] init];
	}
	
	return _sharedInstance;
}

+ (void)dropShared {
	
	if (_sharedInstance) {
		_sharedInstance = nil;
	}
}

#pragma mark -
#pragma mark === Init Methods ===
#pragma mark -

- (instancetype)init {
    self = [super init];
    if (self) {
        _migrate = YES;
        _accessMode = UYLPMAccessibleWhenUnlocked;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceWillLockOrBackground:) 
                                                     name:UIApplicationProtectedDataWillBecomeUnavailable 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceWillLockOrBackground:) 
                                                     name:UIApplicationDidEnterBackgroundNotification 
                                                   object:nil];

    }
    return self;
}

- (void)dealloc {
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark === Accessor Methods ===
#pragma mark -

- (void)setKeychainIdentifier:(NSString *)newValue {
	
	if (!_keychainIdentifier && !newValue)  {
		return;
	}
	
	_keychainIdentifier = nil;
	self.keychainValue = nil;

	if (newValue) {
		_keychainIdentifier = [newValue copy];
	}
}

- (void)setKeychainAccessGroup:(NSString *)newValue {

	if (!_keychainAccessGroup && !newValue)  {
		return;
	}
	
	self.keychainValue = nil;
    
	if (newValue) {
		_keychainAccessGroup = [newValue copy];
	}
}

#pragma mark -
#pragma mark === Private Methods ===
#pragma mark -

- (void)searchKeychain {

    if (self.keychainValue == nil) {
        NSMutableDictionary *searchDictionary = [self newSearchDictionary];

        searchDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
        searchDictionary[(__bridge id)kSecReturnData] = (id)kCFBooleanTrue;
        
        CFTypeRef cfResult = nil;
        SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &cfResult);
        
        if (cfResult) {
            NSData *result = (__bridge NSData *)cfResult;
            NSString *stringResult = [[NSString alloc] initWithData:result 
                                                           encoding:NSUTF8StringEncoding];
            self.keychainValue = stringResult;
            CFRelease(cfResult);
        }
    }
}

- (BOOL)createKeychainValue:(NSString *)password {
	
	NSMutableDictionary *dictionary = [self newSearchDictionary];

	NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
	dictionary[(__bridge id)kSecValueData] = passwordData;
    dictionary[(__bridge id)kSecAttrAccessible] = (id)[self attributeAccess];
	
	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
	
	if (status == errSecSuccess) {
		return YES;
	}

	return NO;
}

- (BOOL)updateKeychainValue:(NSString *)password{
	
	NSMutableDictionary *searchDictionary = [self newSearchDictionary];
	NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
	NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
	updateDictionary[(__bridge id)kSecValueData] = passwordData;
    updateDictionary[(__bridge id)kSecAttrAccessible] = (id)[self attributeAccess];
	
	OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary, (__bridge CFDictionaryRef)updateDictionary);
	
	
	if (status == errSecSuccess) {
		return YES;
	}
	
	return NO;
}

- (void)deleteKeychainValue {
	
	NSMutableDictionary *searchDictionary = [self newSearchDictionary];
	
	if (searchDictionary) {
		SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
	}
	self.keychainValue = nil;
}

- (NSMutableDictionary *)newSearchDictionary {
	
	NSMutableDictionary *searchDictionary = nil;
	
	if (self.keychainIdentifier) {
		NSData *encodedIdentifier = [self.keychainIdentifier dataUsingEncoding:NSUTF8StringEncoding];
		
		searchDictionary = [[NSMutableDictionary alloc] init];
		searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
		searchDictionary[(__bridge id)kSecAttrGeneric] = encodedIdentifier;
		searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
		searchDictionary[(__bridge id)kSecAttrService] = kKeychainService;
        		
		if (self.keychainAccessGroup) {
			searchDictionary[(__bridge id)kSecAttrAccessGroup] = self.keychainAccessGroup;
		}
	}
	return searchDictionary;
}

- (NSString *)resultCode:(OSStatus) status {
	
	switch (status) {
		case 0:
			return @"No error";
			break;
		case -4:
			return @"Function or operation not implemented";
			break;
		case -50:
			return @"One or more parameters passed to the function were not valid";
			break;
		case -108:
			return @"Failed to allocate memory";
			break;
		case -25291:
			return @"No trust results are available";
			break;
		case -25299:
			return @"The item already exists";
			break;
		case -25300:
			return @"The item cannot be found";
			break;
		case -25308:
			return @"Interaction with the Security Server is not allowed";
			break;
		case -26275:
			return @"Unable to decode the provided data";
			break;
		default:
			return [NSString stringWithFormat:@"Unknown error: %ld",(long)status];
			break;
	}
}

- (CFTypeRef)attributeAccess {
    
    switch (self.accessMode) {
        case UYLPMAccessibleWhenUnlocked:
            return self.migrate ? kSecAttrAccessibleWhenUnlocked : kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
            break;
        case UYLPMAccessibleAfterFirstUnlock:
            return self.migrate ? kSecAttrAccessibleAfterFirstUnlock : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
            break;
        case UYLPMAccessibleAlways:
            return self.migrate ? kSecAttrAccessibleAlways : kSecAttrAccessibleAlwaysThisDeviceOnly;
            break;
        default:
            return self.migrate ? kSecAttrAccessibleWhenUnlocked : kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
            break;
    }
}

- (void)deviceWillLockOrBackground:(NSNotification *)notification {
    [self purge];
}

#pragma mark -
#pragma mark === Public Methods ===
#pragma mark -

- (void)purge {
    self.keychainAccessGroup = nil;
    self.keychainIdentifier = nil;
    self.keychainValue = nil;
}

- (void)registerKey:(NSString *)key forIdentifier:(NSString *)identifier inGroup:(NSString *)group {
    
    self.keychainAccessGroup = group;
    self.keychainIdentifier = identifier;
    [self searchKeychain];

	if (self.keychainValue == nil) {
		
		[self createKeychainValue:key];
		
	} else {
		
		[self updateKeychainValue:key];
	}
	
	[self searchKeychain];
	
}

// Check for a valid key. If key is passed as nil then we do not
// check the value of the key only that we have a key.
- (BOOL)validKey:(NSString *)key forIdentifier:(NSString *)identifier inGroup:(NSString *)group {
    
	BOOL result = NO;
    
    if (identifier) {
        self.keychainAccessGroup = group;
        self.keychainIdentifier = identifier;
        [self searchKeychain];
        
        if (self.keychainValue != nil) {
            
            if (key != nil) {
                
                if ([self.keychainValue isEqual:key]) {
                    result = YES;
                }
                
            } else {
                
                result = YES;
            }
        }
    }
	return result;
}

- (NSString *)keyForIdentifier:(NSString *)identifier inGroup:(NSString *)group {
    if (identifier) {
        self.keychainAccessGroup = group;
        self.keychainIdentifier = identifier;
        [self searchKeychain];
        return self.keychainValue;
    } else {
        return nil;
    }
}

- (void)deleteKeyForIdentifier:(NSString *)identifier inGroup:(NSString *)group {

    self.keychainAccessGroup = group;
    self.keychainIdentifier = identifier;
    [self deleteKeychainValue];
}

- (void)registerKey:(NSString *)key forIdentifier:(NSString *)identifier {
    [self registerKey:key forIdentifier:identifier inGroup:nil];
}

- (void)deleteKeyForIdentifier:(NSString *)identifier {
    [self deleteKeyForIdentifier:identifier inGroup:nil];
}

- (BOOL)validKey:(NSString *)key forIdentifier:(NSString *)identifier {
    BOOL result = [self validKey:key forIdentifier:identifier inGroup:nil];
	return result;
}

- (NSString *)keyForIdentifier:(NSString *)identifier {
    NSString *result = [self keyForIdentifier:identifier inGroup:nil];
  return result;
}

@end
