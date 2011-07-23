//
//  UYLPasswordManager.m
//
//  Created by Keith Harrison on 23-May-2011 http://useyourloaf.com
//  Copyright (c) 2011 Keith Harrison. All rights reserved.
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

@property (nonatomic,retain) NSString *keychainValue;
@property (nonatomic,copy) NSString *keychainAccessGroup;
@property (nonatomic,copy) NSString *keychainIdentifier;

@end

@implementation UYLPasswordManager

@synthesize migrate=_migrate;
@synthesize accessMode=_accessMode;
@synthesize keychainValue=_keychainValue;
@synthesize keychainIdentifier=_keychainIdentifier;
@synthesize keychainAccessGroup=_keychainAccessGroup;

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
		[_sharedInstance release];
		_sharedInstance = nil;
	}
}

#pragma mark -
#pragma mark === Init Methods ===
#pragma mark -

- (id)init {
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
    [_keychainAccessGroup release];
	[_keychainIdentifier release];
	[_keychainValue release];
	[super dealloc];
}

#pragma mark -
#pragma mark === Accessor Methods ===
#pragma mark -

- (void)setKeychainIdentifier:(NSString *)newValue {
	
	if (!_keychainIdentifier && !newValue)  {
		return;
	}
	
	[_keychainIdentifier release];
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
	
    [_keychainAccessGroup release];
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

        [searchDictionary setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
        [searchDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
        
        NSData *result = nil;
        SecItemCopyMatching((CFDictionaryRef)searchDictionary, (CFTypeRef *)&result);
        [searchDictionary release];
        
        if (result) {
            NSString *stringResult = [[NSString alloc] initWithData:result 
                                                           encoding:NSUTF8StringEncoding];
            self.keychainValue = stringResult;
            [stringResult release];
            [result release];
        }
    }
}

- (BOOL)createKeychainValue:(NSString *)password {
	
	NSMutableDictionary *dictionary = [self newSearchDictionary];

	NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
	[dictionary setObject:passwordData forKey:(id)kSecValueData];
    [dictionary setObject:(id)[self attributeAccess] forKey:(id)kSecAttrAccessible];
	
	OSStatus status = SecItemAdd((CFDictionaryRef)dictionary, NULL);
	[dictionary release];
	
	if (status == errSecSuccess) {
		return YES;
	}

	return NO;
}

- (BOOL)updateKeychainValue:(NSString *)password{
	
	NSMutableDictionary *searchDictionary = [self newSearchDictionary];
	NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
	NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
	[updateDictionary setObject:passwordData forKey:(id)kSecValueData];
    [updateDictionary setObject:(id)[self attributeAccess] forKey:(id)kSecAttrAccessible];
	
	OSStatus status = SecItemUpdate((CFDictionaryRef)searchDictionary, (CFDictionaryRef)updateDictionary);
	
	[searchDictionary release];
	[updateDictionary release];
	
	if (status == errSecSuccess) {
		return YES;
	}
	
	return NO;
}

- (void)deleteKeychainValue {
	
	NSMutableDictionary *searchDictionary = [self newSearchDictionary];
	
	if (searchDictionary) {
		SecItemDelete((CFDictionaryRef)searchDictionary);
		[searchDictionary release];
	}
	self.keychainValue = nil;
}

- (NSMutableDictionary *)newSearchDictionary {
	
	NSMutableDictionary *searchDictionary = nil;
	
	if (self.keychainIdentifier) {
		NSData *encodedIdentifier = [self.keychainIdentifier dataUsingEncoding:NSUTF8StringEncoding];
		
		searchDictionary = [[NSMutableDictionary alloc] init];
		[searchDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
		[searchDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
		[searchDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
		[searchDictionary setObject:kKeychainService forKey:(id)kSecAttrService];
        		
		if (self.keychainAccessGroup) {
			[searchDictionary setObject:self.keychainAccessGroup forKey:(id)kSecAttrAccessGroup];
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
			return [NSString stringWithFormat:@"Unknown error: %d",status];
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

@end
