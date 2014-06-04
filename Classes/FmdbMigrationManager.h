//
//  FmdbMigrationManager.h
//  FmdbMigrationManager
//
//  Created by Dr Nic Williams on 2008-09-06.
//  Copyright 2008 Mocra and Dr Nic Williams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FmdbMigrationManager : NSObject {
	FMDatabase *db_;
	NSArray *migrations_;
	NSUInteger currentVersion_;
	NSString *schemaMigrationsTableName_;
}
@property (retain, nonatomic) FMDatabase *db;
@property (retain, nonatomic) NSArray *migrations;
@property (assign,readonly, nonatomic) NSUInteger currentVersion;
@property (readonly, nonatomic) NSString *schemaMigrationsTableName;

+ (id)executeForDatabasePath:(NSString *)aPath withMigrations:(NSArray *)migrations;

- (id)initWithDatabasePath:(NSString *)aPath;
- (void)executeMigrations;

#pragma mark -
#pragma mark Internal methods

- (void)initializeSchemaMigrationsTable;
- (void)performMigrations;
- (void)recordVersionStateAfterMigrating:(NSUInteger)version;

#pragma mark -
#pragma mark Migration up to a defined version
+ (id)executeForDatabasePath:(NSString *)aPath withMigrations:(NSArray *)migrations andMatchVersion:(NSUInteger)aVersion;
- (void)executeMigrationsAndMatchVersion:(NSUInteger)aVersion;
- (void)performMigrationsAndMatchVersion:(NSUInteger)aVersion;
@end
