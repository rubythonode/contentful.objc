//
//  CoreDataBasicTests.m
//  ContentfulSDK
//
//  Created by Boris Bügling on 15/04/14.
//
//

#import <OHHTTPStubs/OHHTTPStubs.h>

#import "Asset.h"
#import "ManagedCat.h"
#import "CoreDataManager.h"
#import "SyncBaseTestCase.h"
#import "SyncInfo.h"

@interface CoreDataBasicTests : SyncBaseTestCase

@property (nonatomic) CoreDataManager* coreDataManager;
@property (nonatomic) NSDate* lastSyncTimestamp;

@end

#pragma mark -

@implementation CoreDataBasicTests

-(void)assertNumberOfAssets:(NSUInteger)numberOfAssets numberOfEntries:(NSUInteger)numberOfEntries {
    XCTAssertEqual(numberOfAssets, [self.coreDataManager fetchAssetsFromDataStore].count, @"");
    XCTAssertEqual(numberOfEntries, [self.coreDataManager fetchEntriesFromDataStore].count, @"");
    
    NSDate* timestamp = [self.coreDataManager fetchSpaceFromDataStore].lastSyncTimestamp;
    XCTAssertNotEqualObjects(self.lastSyncTimestamp, timestamp, @"");
    self.lastSyncTimestamp = timestamp;
}

-(void)buildCoreDataManagerWithDefaultClient:(BOOL)defaultClient {
    CDAClient* client = defaultClient ? [CDAClient new] : self.client;
    
    self.coreDataManager = [[CoreDataManager alloc] initWithClient:client
                                                     dataModelName:@"CoreDataExample"];
    self.coreDataManager.classForAssets = [Asset class];
    self.coreDataManager.classForEntries = [ManagedCat class];
    self.coreDataManager.classForSpaces = [SyncInfo class];
    
    NSMutableDictionary* mapping = [@{ @"contentType.identifier": @"contentTypeIdentifier",
                                       @"fields.color": @"color",
                                       @"fields.lives": @"livesLeft",
                                       @"fields.image": @"picture" } mutableCopy];
    
    if (defaultClient) {
        mapping[@"fields.name"] = @"name";
    } else {
        mapping[@"fields.title"] = @"name";
    }
    
    self.coreDataManager.mappingForEntries = mapping;
}

-(void)setUp {
    [super setUp];
    
    self.lastSyncTimestamp = nil;
    
    /*
     Map URLs to JSON response files
     
     The tests are based on a sync session with five subsequent syncs where each one either added,
     removed or updated Resources.
     */
    NSDictionary* stubs = @{ @"https://cdn.contentful.com/spaces/emh6o2ireilu/sync?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac&initial=true": @"initial", @"https://cdn.contentful.com/spaces/emh6o2ireilu/sync?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac&sync_token=w5ZGw6JFwqZmVcKsE8Kow4grw45QdyYxwoHDtsKywrXDmQs_WcOvIcOzwotYw6PCgcOsAcOYYcO4YsKCw7TCnsK_clnClS7Csx9lwoFcw6nCqnnCpWh3w7k7SkI-CcOuQyXDlw_Dlh9RwqkcElwpW30sw4k": @"added", @"https://cdn.contentful.com/spaces/emh6o2ireilu/sync?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac&sync_token=w5ZGw6JFwqZmVcKsE8Kow4grw45QdyY0w4bCiMKOWDIFw61bwqQ_w73CnMKsB8KpwrFZPsOZw5ZQwqDDnUA0w5tOPRtwwoAkwpJMTzghdEnDjCkiw5fCuynDlsO5DyvCsjgQa2TDisKNZ8Kqw4TCjhZIGQ": @"deleted", @"https://cdn.contentful.com/spaces/emh6o2ireilu/sync?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac&sync_token=w5ZGw6JFwqZmVcKsE8Kow4grw45QdyZew5xDN04dJg3DkmBAw4XDh8OEw5o5UVhIw6nDlFjDoBxIasKIDsKIw4VcIV18GicdwoTDjCtoMiFAfcKiwrRKIsKYwrzCmMKBw4ZhwrdhwrsGa8KTwpQ6w6A": @"added-asset", @"https://cdn.contentful.com/spaces/emh6o2ireilu/sync?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac&sync_token=w5ZGw6JFwqZmVcKsE8Kow4grw45QdyZ_NnHDoQzCtcKoMh9KZHtAWcObw7XCimZgVGPChUfDuxQHwoHDosO6CcKodsO2MWJQwrrCrsOswpl5w6LCuV0tw4Njwo9Ww5fCl8KqEgB6XgAJNVF2wpk3Lg": @"deleted-asset", @"https://cdn.contentful.com/spaces/emh6o2ireilu/sync?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac&sync_token=w5ZGw6JFwqZmVcKsE8Kow4grw45QdyYHPUPDhggxwr5qw5RBbMKWw4VjOg3DumTDg0_CgsKcYsO8UcOZfMKLw4sKUcOnJcKxfDUkGWwxNMOVw4AiacK5Bmo4ScOhI0g2cXLClxTClsOyE8OOc8O3": @"update", @"https://cdn.contentful.com/spaces/emh6o2ireilu/?access_token=1bf1261e0225089be464c79fff1a0773ca8214f1e82dd521f3ecf9690ba888ac": @"space", };
    
    [self stubHTTPRequestUsingFixtures:stubs inDirectory:@"SyncTests"];
    
    [self buildCoreDataManagerWithDefaultClient:NO];
    [[NSFileManager defaultManager] removeItemAtURL:self.coreDataManager.storeURL
                                              error:nil];
}

-(void)tearDown {
    [super tearDown];
    
    self.coreDataManager = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.coreDataManager.storeURL
                                              error:nil];
}

#pragma mark -

-(void)testContinueSyncFromDataStore {
    StartBlock();
    
    [self.coreDataManager performSynchronizationWithSuccess:^{
        [self assertNumberOfAssets:1U numberOfEntries:1U];
        [self buildCoreDataManagerWithDefaultClient:NO];
        
        Asset* asset = [[self.coreDataManager fetchAssetsFromDataStore] firstObject];
        XCTAssertEqualObjects(@"512_black.png", asset.url.lastPathComponent, @"");
        ManagedCat* cat = [[self.coreDataManager fetchEntriesFromDataStore] firstObject];
        XCTAssertEqualObjects(@"Test", cat.name, @"");
        
        [self.coreDataManager performSynchronizationWithSuccess:^{
            [self assertNumberOfAssets:1U numberOfEntries:2U];
            [self buildCoreDataManagerWithDefaultClient:NO];
            
            [self.coreDataManager performSynchronizationWithSuccess:^{
                [self assertNumberOfAssets:1U numberOfEntries:1U];
                [self buildCoreDataManagerWithDefaultClient:NO];
                
                [self.coreDataManager performSynchronizationWithSuccess:^{
                    [self assertNumberOfAssets:2U numberOfEntries:1U];
                    [self buildCoreDataManagerWithDefaultClient:NO];
                    
                    [self.coreDataManager performSynchronizationWithSuccess:^{
                        [self assertNumberOfAssets:1U numberOfEntries:1U];
                        [self buildCoreDataManagerWithDefaultClient:NO];
                        
                        [self.coreDataManager performSynchronizationWithSuccess:^{
                            [self assertNumberOfAssets:1U numberOfEntries:1U];
                            
                            Asset* asset = [[self.coreDataManager fetchAssetsFromDataStore] firstObject];
                            XCTAssertEqualObjects(@"vaa4by0.png", asset.url.lastPathComponent, @"");
                            ManagedCat* cat = [[self.coreDataManager fetchEntriesFromDataStore] firstObject];
                            XCTAssertEqualObjects(@"Test (changed)", cat.name, @"");
                            
                            EndBlock();
                        } failure:^(CDAResponse *response, NSError *error) {
                            XCTFail(@"Error: %@", error);
                            
                            EndBlock();
                        }];
                    } failure:^(CDAResponse *response, NSError *error) {
                        XCTFail(@"Error: %@", error);
                        
                        EndBlock();
                    }];
                    
                } failure:^(CDAResponse *response, NSError *error) {
                    XCTFail(@"Error: %@", error);
                    
                    EndBlock();
                }];
                
            } failure:^(CDAResponse *response, NSError *error) {
                XCTFail(@"Error: %@", error);
                
                EndBlock();
            }];
        } failure:^(CDAResponse *response, NSError *error) {
            XCTFail(@"Error: %@", error);
            
            EndBlock();
        }];
    } failure:^(CDAResponse *response, NSError *error) {
        XCTFail(@"Error: %@", error);
        
        EndBlock();
    }];
    
    WaitUntilBlockCompletes();
}

-(void)testContinueSyncWithSameManager {
    StartBlock();
    
    [self.coreDataManager performSynchronizationWithSuccess:^{
        [self assertNumberOfAssets:1U numberOfEntries:1U];
        
        Asset* asset = [[self.coreDataManager fetchAssetsFromDataStore] firstObject];
        XCTAssertEqualObjects(@"512_black.png", asset.url.lastPathComponent, @"");
        ManagedCat* cat = [[self.coreDataManager fetchEntriesFromDataStore] firstObject];
        XCTAssertEqualObjects(@"Test", cat.name, @"");
        
        [self.coreDataManager performSynchronizationWithSuccess:^{
            [self assertNumberOfAssets:1U numberOfEntries:2U];
            
            [self.coreDataManager performSynchronizationWithSuccess:^{
                [self assertNumberOfAssets:1U numberOfEntries:1U];
                
                [self.coreDataManager performSynchronizationWithSuccess:^{
                    [self assertNumberOfAssets:2U numberOfEntries:1U];
                    
                    [self.coreDataManager performSynchronizationWithSuccess:^{
                        [self assertNumberOfAssets:1U numberOfEntries:1U];
                        
                        [self.coreDataManager performSynchronizationWithSuccess:^{
                            [self assertNumberOfAssets:1U numberOfEntries:1U];
                            
                            Asset* asset = [[self.coreDataManager fetchAssetsFromDataStore] firstObject];
                            XCTAssertEqualObjects(@"vaa4by0.png", asset.url.lastPathComponent, @"");
                            ManagedCat* cat = [[self.coreDataManager fetchEntriesFromDataStore] firstObject];
                            XCTAssertEqualObjects(@"Test (changed)", cat.name, @"");
                            
                            EndBlock();
                        } failure:^(CDAResponse *response, NSError *error) {
                            XCTFail(@"Error: %@", error);
                            
                            EndBlock();
                        }];
                    } failure:^(CDAResponse *response, NSError *error) {
                        XCTFail(@"Error: %@", error);
                        
                        EndBlock();
                    }];
                    
                } failure:^(CDAResponse *response, NSError *error) {
                    XCTFail(@"Error: %@", error);
                    
                    EndBlock();
                }];
                
            } failure:^(CDAResponse *response, NSError *error) {
                XCTFail(@"Error: %@", error);
                
                EndBlock();
            }];
        } failure:^(CDAResponse *response, NSError *error) {
            XCTFail(@"Error: %@", error);
            
            EndBlock();
        }];
    } failure:^(CDAResponse *response, NSError *error) {
        XCTFail(@"Error: %@", error);
        
        EndBlock();
    }];
    
    WaitUntilBlockCompletes();
}

-(void)testInitialSync {
    [OHHTTPStubs removeAllStubs];
    [self buildCoreDataManagerWithDefaultClient:YES];
    
    StartBlock();
    
    [self.coreDataManager performSynchronizationWithSuccess:^{
        XCTAssertEqual(4U, [self.coreDataManager fetchAssetsFromDataStore].count, @"");
        XCTAssertEqual(10U, [self.coreDataManager fetchEntriesFromDataStore].count, @"");
        
        EndBlock();
    } failure:^(CDAResponse *response, NSError *error) {
        XCTFail(@"Error: %@", error);
        
        EndBlock();
    }];
    
    WaitUntilBlockCompletes();
}

-(void)testMappingOfFields {
    [OHHTTPStubs removeAllStubs];
    [self buildCoreDataManagerWithDefaultClient:YES];
    
    StartBlock();
    
    [self.coreDataManager performSynchronizationWithSuccess:^{
        NSString* predicate = @"contentTypeIdentifier == 'cat'";
        for (ManagedCat* cat in [self.coreDataManager fetchEntriesMatchingPredicate:predicate]) {
            XCTAssertNotNil(cat.color, @"");
            XCTAssertNotNil(cat.name, @"");
            XCTAssert(cat.livesLeft > 0, @"");
        }
        
        EndBlock();
    } failure:^(CDAResponse *response, NSError *error) {
        XCTFail(@"Error: %@", error);
        
        EndBlock();
    }];
    
    WaitUntilBlockCompletes();
}

-(void)testUseExistingDatabase {
    NSURL* documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* toURL = [documentsDirectory URLByAppendingPathComponent:@"CoreDataExample.sqlite"];
    
    NSError* error;
    BOOL result = [[NSFileManager defaultManager] copyItemAtURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"CoreDataExample" withExtension:@"sqlite" subdirectory:@"Fixtures"]
                                                          toURL:toURL
                                                          error:&error];
    XCTAssert(result, @"Error: %@", error);
    
    XCTAssertEqual(1U, [self.coreDataManager fetchAssetsFromDataStore].count, @"");
    XCTAssertEqual(2U, [self.coreDataManager fetchEntriesFromDataStore].count, @"");
    
    [[NSFileManager defaultManager] removeItemAtURL:toURL error:nil];
}

@end
