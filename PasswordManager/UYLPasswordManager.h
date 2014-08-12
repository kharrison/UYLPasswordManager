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
 
 UYLPasswordManager is tested with iOS version 6.0 and later. The password manager code makes use of ARC for memory management and the modern Objective-C language.
 
 The Shared Instance
 ===================
 
 The UYLPasswordManager class provides a shared instance for convenience.
 
 Accessing the shared instance
 -----------------------------
 
 To access the shared instance of the UYLPasswordManager use the sharedInstance class method:
 
 UYLPasswordManager *manager = [UYLPasswordManager sharedInstance];
 
 Deleting Cached Items
 ---------------------
 
 The UYLPasswordManager class caches the last access to the keychain. This is efficient when the same item is accessed multiple times by an application. You should flush these cache entries when you no longer need then. The cache is automatically cleared when the device is locked or when moving to the background.
 
 [manager purge];
 
 Using the Keychain
 ==================
 
 Adding an Item to the Keychain
 ------------------------------
 
 Any key that you store in the keychain is associated with an identifier. The identifier is also used when you need to retrieve the key. Both the key and the identifier are of class NSString.
 
 For example, to store a password you might use the user name as the identifier.
 
 [manager registerKey:password forIdentifier:username];
 
 Retrieving an Item from the Keychain
 ---------------------
 
 To retrieve a key for an identifier:
 
 NSString *result = [manager keyForIdentifier:username];
 
 If there is no matching identifier in the Keychain this will return nil.
 
 
 Searching for an Item
 ---------------------
 
 To determine if an existing key exists in the keychain:
 
 BOOL result = [manager validKey:password forIdentifier:username];
 
 If you just need to check for the presence of the identifier in the keychain you can pass nil for the key:
 
 BOOL result = [manager validKey:nil for Identifier:username];
 
 Deleting an Item
 ----------------
 
 To remove an item from the keychain:
 
 [manager deleteKeyForIdentifier:username];
 
 Data Protection Classes
 =======================
 
 When storing items in the Keychain you can set the accessibility of the data and whether it should be allowed to migrate to a new device. You should set these properties before adding or updating items to the keychain.
 
 Keychain Migration
 ------------------
 
 If a user restores an encrypted backup to a new device keychain items which are set to be migratable will be restored to that device. This allows a user to migrate to a new device without having to manually enter password data.
 
 The migrate property is a BOOL which controls whether items added or updated are migratable. By default the migrate property is set to YES. If you want to set an item to be non-migratable set the migrate property to NO before adding or updating the item.
 
 manager.migrate = NO;
 
 Data Accessibility
 ------------------
 
 The accessMode property controls the accessibility of the keychain item. There are three possible values as follows:
 
 + **UYLPMAccessibileWhenUnlocked** - data can only be accessed when the device is unlocked.
 
 + **UYLPMAccessibileAfterFirstUnlock** - data can be accessed when the device is locked provided it has been unlocked at least once since the device was started.
 
 + **UYLPMAccessibleAlways** - the data is accessible always even when the device is locked
 
 The default is UYLPMAccessibleWhenUnlocked which prevents access to the item when the device is locked. Note that if you need to access the keychain when running in the background it is recommend to allow access after first unlock:
 
 manager.accessMode = UYLPMAccessibleAfterFirstUnlock;
 
 Group Access
 ============
 
 If you need to share keychain items between applications you need to use an access group. The main prerequisite for shared keychain access is that all of the applications have a **common bundle seed ID**. An App ID consists of two parts as follows:
 
 <Bundle Seed ID> . <Bundle Identifier>
 
 The bundle seed ID is a unique (with the App Store) ten character string that is generated by Apple when you first create an App ID. The bundle identifier is  generally set to be a reverse domain name string identifying your app (e.g. com.yourcompany.appName) and is what you specify in the application Info.plist file in Xcode.
 
 To create an app that can share keychain access with an existing app you need to make sure that you use the bundle seed ID of the existing app. You do this when you create the new App ID in the iPhone Provisioning Portal. Instead of generating a new value you select the existing value from the list of all your previous bundle seed IDs.
 
 With a common bundle seed ID you need to choose a name for the common keychain access group. The group name needs to start with the bundle seed ID. For example:
 
 <Bundle Seed ID>.yourcompany
 
 You then need to add an entitlements plist file to the Xcode project (use Add -> New File and choose the Entitlements template). Add a new array item named keychain-access-groups and create a string item in the array containing the name of the access group.
 
 Accessing a Keychain Group
 --------------------------
 
 The UYLPasswordManager methods for adding, retrieving, and searching for keychain items are all available in a form that takes an additional group parameter:
 
 [manager registerKey:password forIdentifier:username inGroup:group];
 
 BOOL result = [manager validKey:nil for Identifier:username inGroup:group];
 */

typedef enum _UYLPMAccessMode {
    UYLPMAccessibleWhenUnlocked = 0,
    UYLPMAccessibleAfterFirstUnlock = 1,
    UYLPMAccessibleAlways = 2
} UYLPMAccessMode;

@interface UYLPasswordManager : NSObject {

}

/**
 Allow an item added to the keychain to be migrated to a new device. Set before adding or updating an item. Default is YES.
 */

@property (nonatomic,assign) BOOL migrate;

/**
 Accessibility of the keychain item. See the description on data accessibility for details. The default is UYLPMAccessibleWhenUnlocked.
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
