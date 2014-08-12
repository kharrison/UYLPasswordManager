//
//  PasswordManager.h
//  
//  Created by Keith Harrison on 23-May-2011 http://useyourloaf.com
//  Copyright (c) 2012-2014 Keith Harrison. All rights reserved.
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


#import <Foundation/Foundation.h>

/**
 `UYLPasswordManager` provides a simple wrapper around Apple Keychain Services on iOS devices. The class is designed to make it quick and easy to create, read, update and delete keychain items. Keychain groups are also supported as is the ability to set the data migration and protection attributes of keychain items.
 */

typedef enum _UYLPMAccessMode {
    UYLPMAccessibleWhenUnlocked = 0,
    UYLPMAccessibleAfterFirstUnlock = 1,
    UYLPMAccessibleAlways = 2
} UYLPMAccessMode;

@interface UYLPasswordManager : NSObject {

}

/**-----------------------------------
 * @name Properties
 * -----------------------------------
 */

/**
 Allow an item added to the keychain to be migrated to a new device. Set before adding or updating an item. Default is YES.
 */

@property (nonatomic,assign) BOOL migrate;

/**
 Accessibility of the keychain item. Valid values are:
 + **UYLPMAccessibileWhenUnlocked** - data can only be accessed when the device is unlocked.
 + **UYLPMAccessibileAfterFirstUnlock** - data can be accessed when the device is locked provided it has been unlocked at least once since the device was started.
 + **UYLPMAccessibleAlways** - the data is accessible always even when the device is locked
 
 The default is UYLPMAccessibleWhenUnlocked
 */

@property (nonatomic,assign) UYLPMAccessMode accessMode;

/**-----------------------------------
 * @name Accessing the Shared Instance
 * -----------------------------------
 */

/**
 Returns the shared `UYLPasswordManager` instance, creating it if necessary

 @return The shated `UYLPasswordManager` instance.
 */

+ (UYLPasswordManager *)sharedInstance;

/**
 Release the shared instance.
 */

+ (void)dropShared;

/**-----------------------------------
 * @name Miscellaneous Methods
 * -----------------------------------
 */

/**
 Remove any cached keychain data. Use this method to ensure that all sensitive keychain data is removed from memory. This method is automatically invoked when the device is locked or when the application enters the background.
 */

- (void)purge;

/**-----------------------------------
 * @name Keychain Access Methods
 * -----------------------------------
 */

/**
 Add an item or update an existing item to the keychain.
 
 @param key The key value to be stored in the keychain. This is typically the password, or preferably a hash of the actual password that you want to store.
 @param identifier The identifier of the keychain item to be stored.
 @param group The keychain access group. This parameter is optional and may be set to nil.
 
  @see -registerKey:forIdentifier:
 */

- (void)registerKey:(NSString *)key forIdentifier:(NSString *)identifier inGroup:(NSString *)group;

/**
 Delete an item from the keychain.
 
 @param identifier The identifier of the keychain item to be deleted.
 @param group The keychain access group. This parameter is optional and may be set to nil.
 
 @see -deleteKeyForIdentifier:
 */

- (void)deleteKeyForIdentifier:(NSString *)identifier inGroup:(NSString *)group;

/**
 Search the keychain for the identifier and compare the value of the key. If you do not care about the value of the key you can pass it as nil.
 
 @param key The value of the key that you want to validate. This parameter can be nil in which case the method returns true if an item is found for the identifier.
 @param identifier The identifier of the keychain item to search for.
 @param group The keychain access group. This parameter is optional and may be set to nil.

 @see -validKey:forIdentifier:
 */

- (BOOL)validKey:(NSString *)key forIdentifier:(NSString *)identifier inGroup:(NSString *)group;

/**
 Search the keychain for the identifier and if present return the value of the associated key.
 
 @param identifier The identifier of the keychain item to search for.
 @param group The keychain access group. This parameter is optional and may be set to nil.

 @see -keyForIdentifier:
 */

- (NSString *)keyForIdentifier:(NSString *)identifier inGroup:(NSString *)group;

/**
 Add an item or update an existing item to the keychain. Equivalent to calling registerKey:forIdentifier:inGroup: with group set to nil.
 
 @param key The key value to be stored in the keychain. This is typically the password, or preferably a hash of the actual password that you want to store.
 @param identifier The identifier of the keychain item to be stored.
 
 @see -registerKey:forIdentifier:inGroup:
 */

- (void)registerKey:(NSString *)key forIdentifier:(NSString *)identifier;

/**
 Delete an item from the keychain. Equivalent to calling deleteKeyForIdentifier:inGroup: with group set to nil.
 
 @param identifier The identifier of the keychain item to be deleted.
 
 @see -deleteKeyForIdentifier:InGroup:
 */

- (void)deleteKeyForIdentifier:(NSString *)identifier;

/**
 Search the keychain for the identifier and compare the value of the key. If you do not care about the value of the key you can pass it as nil. Equivalent to calling validKey:forIdentifier:inGroup: with group set to nil.
 
 @param key The value of the key that you want to validate. This parameter can be nil in which case the method returns true if an item is found for the identifier.
 @param identifier The identifier of the keychain item to search for.
 
 @see -validKey:forIdentifier:inGroup:
 */

- (BOOL)validKey:(NSString *)key forIdentifier:(NSString *)identifier;

/**
 Search the keychain for the identifier and if present return the value of the associated key. Equivalent to calling keyForIdentifier:InGroup: with group set to nil.
 
 @param identifier The identifier of the keychain item to search for.
 
 @see -keyForIdentifier:inGroup:
 */

- (NSString *)keyForIdentifier:(NSString *)identifier;

@end
