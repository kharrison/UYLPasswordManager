UYLPasswordManager - Simple Access to the iOS Keychain
======================================================

The UYLPasswordManager class provides a simple wrapper around Apple Keychain Services on iOS devices. The class is designed to make it quick and easy to create, read, update and delete keychain items. Keychain groups are also supported as is the ability to set the data migration and protection attributes of keychain items.

UYLPasswordManager is tested with iOS version 7.1 and later. That does not mean it will not work on earlier versions just that I no longer test on earlier versions. The password manager code makes use of ARC for memory management and the modern Objective-C language.

Installation
------------

To use the UYLPasswordManager class in an iOS application copy the following files to an existing Xcode project:

+ UYLPasswordManager.h
+ UYLPasswordManager.m

Using CocoaPods
---------------

To install with the [CocoaPods](http://cocoapods.org/) dependency manager create of modify a Podfile in the project directory as follows (assuming you target iOS 7):

    platform :ios, '7.1'
    pod "UYLPasswordManager", "~> 1.1"

Then install:

    $ pod install

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


Class Documentation
===================

Shared Instance Class Methods
-----------------------------

### sharedInstance

    + (UYLPasswordManager *)sharedInstance

Returns a reference to the UYLPasswordManager shared instance. The shared instance is allocated the first time it is accessed. All subsequent access to this method returns a reference to the existing instance.

### dropShared

    + (void)dropShared

Force the shared instance to be released. There should not normally be a reason to do this as the shared instance uses only a small amount of memory.

Keychain Access Methods
-----------------------

### registerKey:forIdentifier:inGroup:

Add an item or update an existing item to the keychain.

    - (void)registerKey:(NSString *)key forIdentifier:(NSString *)identifier inGroup:(NSString *)group

#### Parameters

*key*
The key value to be stored in the keychain. This is typically the password, or preferably a hash of the actual password that you want to store.

*identifier*
The identifier of the keychain item to be stored.

*group*
The keychain access group. This parameter is optional and may be set to nil.

### deleteKeyForIdentifier:inGroup:

Delete an item from the keychain.

    - (void)deleteKeyForIdentifier:(NSString *)identifier inGroup:(NSString *)group

#### Parameters

*identifier*
The identifier of the keychain item to be deleted.

*group*
The keychain access group. This parameter is optional and may be set to nil.

### validKey:forIdentifier:inGroup:

Search the keychain for the identifier and compare the value of the key. If you do not care about the value of the key you can pass it as nil.

    - (BOOL)validKey:(NSString *)key forIdentifier:(NSString *)identifier inGroup:(NSString *)group

#### Parameters

*key*
The value of the key that you want to validate. This parameter can be nil in which case the method returns true if an item is found for the identifier.

*identifier*
The identifier of the keychain item to search for.

*group*
The keychain access group. This parameter is optional and may be set to nil.

### keyForIdentifier:inGroup:

Search the keychain for the identifier and if present return the value of the associated key.

    - (NSString *)keyForIdentifier:(NSString *)identifier inGroup:(NSString *)group

#### Parameters

*identifier*
The identifier of the keychain item to search for.

*group*
The keychain access group. This parameter is optional and may be set to nil.

### registerKey:forIdentifier:

Add an item or update an existing item to the keychain. Equivalent to calling registerKey:forIdentifier:inGroup: with group set to nil.

    - (void)registerKey:(NSString *)key forIdentifier:(NSString *)identifier

#### Parameters

*key*
The key value to be stored in the keychain. This is typically the password, or preferably a hash of the actual password that you want to store.

*identifier*
The identifier of the keychain item to be stored.

### deleteKeyForIdentifier:

Delete an item from the keychain. Equivalent to calling deleteKeyForIdentifier:inGroup: with group set to nil.

    - (void)deleteKeyForIdentifier:(NSString *)identifier

#### Parameters

*identifier*
The identifier of the keychain item to be deleted.

### validKey:forIdentifier:

Search the keychain for the identifier and compare the value of the key. If you do not care about the value of the key you can pass it as nil. Equivalent to calling validKey:forIdentifier:inGroup: with group set to nil.

    - (BOOL)validKey:(NSString *)key forIdentifier:(NSString *)identifier

#### Parameters

*key*
The value of the key that you want to validate. This parameter can be nil in which case the method returns true if an item is found for the identifier.

*identifier*
The identifier of the keychain item to search for.

### keyForIdentifier:

Search the keychain for the identifier and if present return the value of the associated key. Equivalent to calling keyForIdentifier:InGroup: with group set to nil.

    - (NSString *)keyForIdentifier:(NSString *)identifier

#### Parameters

*identifier*
The identifier of the keychain item to search for.

Miscellaneous Methods
---------------------

### purge

    - (void)purge

Removes any cached keychain data. Use this method to ensure that all sensitive keychain data is removed from memory. This method is automatically invoked when the device is locked or when the application enters the background.

Properties
----------

### migrate

    @property (nonatomic, assign) BOOL migrate

### accessMode

    @property (nonatomic, assign) UYLPMAccessMode accessMode