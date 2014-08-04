//
//  PasswordManagerTests.m
//  Created by Keith Harrison on 25/05/2011 http://useyourloaf.com
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

#import "PasswordManagerTests.h"
#import "UYLPasswordManager.h"

@implementation PasswordManagerTests

@synthesize passwordManager;

static NSString *testIdentifier = @"com.useyourloaf.passwordmanager";
static NSString *testKey = @"secret";

- (void) setUp {
	NSLog(@"%@ setUp", self.name);
    self.passwordManager = [UYLPasswordManager sharedInstance];
    STAssertNotNil(self.passwordManager, @"Did not init password manager");

    [self.passwordManager deleteKeyForIdentifier:testIdentifier];
}

- (void) tearDown {
	NSLog(@"%@ tearDown", self.name);
    [UYLPasswordManager dropShared];
    self.passwordManager = nil;
}

#pragma mark -
#pragma mark === Unit Tests ===
#pragma mark -

- (void)testNoIdentifierSet {
    
    BOOL result = [self.passwordManager validKey:nil forIdentifier:nil];
    STAssertFalse(result, @"Identifier not set - should fail");
}

- (void)testKeyNotFound {
    
    BOOL result = [self.passwordManager validKey:nil forIdentifier:testIdentifier];
    STAssertFalse(result, @"Keychain should not contain identifier %@", testIdentifier);
}

- (void)testRegisterAndFindKey {
    
    [self.passwordManager registerKey:testKey forIdentifier:testIdentifier];
    
    BOOL result = [self.passwordManager validKey:testKey forIdentifier:testIdentifier];
    STAssertTrue(result, @"Keychain should contain identifier %@", testIdentifier);
}

- (void)testRegisterAndFindIdentifier {
    
    [self.passwordManager registerKey:testKey forIdentifier:testIdentifier];
    
    BOOL result = [self.passwordManager validKey:nil forIdentifier:testIdentifier];
    STAssertTrue(result, @"Keychain should contain identifier %@", testIdentifier);
}

- (void)testRegisterPurgeAndFindKey {

    [self.passwordManager registerKey:testKey forIdentifier:testIdentifier];
    [self.passwordManager purge];
    
    BOOL result = [self.passwordManager validKey:testKey forIdentifier:testIdentifier];
    STAssertTrue(result, @"Keychain should contain identifier %@", testIdentifier);
}

- (void)testKeyForIdentifier {
    
    [self.passwordManager registerKey:testKey forIdentifier:testIdentifier];
    
    NSString *key = [self.passwordManager keyForIdentifier:testIdentifier];
    STAssertTrue([key isEqualToString:testKey], @"Keychain should return %@ got %@", testKey, key);
}

- (void)testDeleteKey {
    
    [self.passwordManager registerKey:testKey forIdentifier:testIdentifier];
    BOOL result = [self.passwordManager validKey:testKey forIdentifier:testIdentifier];
    STAssertTrue(result, @"Keychain should contain identifier %@", testIdentifier);
    
    [self.passwordManager deleteKeyForIdentifier:testIdentifier];
    
    result = [self.passwordManager validKey:testKey forIdentifier:testIdentifier];
    STAssertFalse(result, @"Keychain should not contain identifier %@", testIdentifier);
}

@end
