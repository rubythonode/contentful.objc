//
//  CoreDataManager.h
//  ContentfulSDK
//
//  Created by Boris Bügling on 14/04/14.
//
//

#import <ContentfulDeliveryAPI/CDAPersistenceManager.h>

/**
 *  A specialization of `CDAPersistenceManager` which allows you to use Core Data.
 *
 *  This is a pretty basic implementation, mostly based on the Core Data example project by Apple.
 *  Depending on your use case, you might want to modify this class to your liking - that's why it is
 *  not a part of the Contentful SDK itself.
 *
 */
@interface CoreDataManager : CDAPersistenceManager

/** @name Initialising the CoreDataManager Object */

/**
*  Initialise a new instance of `CoreDataManager`.
*
*  @param client        The client to be used for fetching Resources from Contentful.
*  @param dataModelName The name of your data model file (*.mom* or *.momd*).
*
*  @return An initialised instance of `CoreDataManager` or `nil` if an error occured.
*/
-(id)initWithClient:(CDAClient *)client dataModelName:(NSString*)dataModelName;

/** @name Fetching Resources */

/**
*  Fetch all Assets from the store.
*
*  @return An array of all Assets.
*/
-(NSArray*)fetchAssetsFromDataStore;

/**
 *  Fetch all Entries from the store.
 *
 *  @return An array of all Entries.
 */
-(NSArray*)fetchEntriesFromDataStore;

/**
 *  Fetch Entries matching a predicate.
 *
 *  @param predicate A string which will be converted to a `NSPredicate`.
 *
 *  @return An array of all Entries matching the given predicate.
 */
-(NSArray*)fetchEntriesMatchingPredicate:(NSString*)predicate;

/** @name Testing Support */

/** 
 URL of the underlying store file.
 
 Only needed for unit testing.
 */
@property (nonatomic, readonly) NSURL* storeURL;

@end