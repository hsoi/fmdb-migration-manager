//
//  FmdbMigrationManager.h
//  FmdbMigrationManager
//
//  Created by Dr Nic Williams on 2008-09-06.
//  Copyright 2008 Mocra and Dr Nic Williams. All rights reserved.
//

#import "FmdbMigrationManager.h"
#import "FmdbMigration.h"
#import "FmdbMigrationColumn.h"
#import "FMResultSet.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@implementation FmdbMigrationManager

@synthesize db=db_, migrations=migrations_, schemaMigrationsTableName=schemaMigrationsTableName_;

+ (id)executeForDatabasePath:(NSString *)aPath withMigrations:(NSArray *)migrations
{
	FmdbMigrationManager *manager = [[[self alloc] initWithDatabasePath:aPath] autorelease];
	manager.migrations = migrations;
	[manager executeMigrations];
	return manager;
}

+ (id)executeForDatabasePath:(NSString *)aPath withMigrations:(NSArray *)migrations andMatchVersion:(NSUInteger)aVersion
{
	FmdbMigrationManager *manager = [[[self alloc] initWithDatabasePath:aPath] autorelease];
	manager.migrations = migrations;
	[manager executeMigrationsAndMatchVersion:aVersion];
	return manager;
}

- (void)executeMigrations
{
	[self performMigrations];
}

- (void)executeMigrationsAndMatchVersion:(NSUInteger)aVersion
{
	[self performMigrationsAndMatchVersion:aVersion];
}

#pragma mark -
#pragma mark Internal methods

- (void)initializeSchemaMigrationsTable
{
	// create schema_info table if doesn't already exist
	NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (version INTEGER unique default 0)", self.schemaMigrationsTableName];
	[db_ executeUpdate:sql];
	// TODO: add index on version column 'unique_schema_migrations'

	[self currentVersion]; // generates first version or stores version in currentVersion_
}

- (void)performMigrations
{
	NSUInteger i;
	for(i = self.currentVersion; i < [self.migrations count]; ++i) {
		FmdbMigration *migration = [self.migrations objectAtIndex:i];
		[migration upWithDatabase:self.db];
		[self recordVersionStateAfterMigrating:i + 1];
		currentVersion_ = i + 1;
	}
}

- (void)performMigrationsAndMatchVersion:(NSUInteger)aVersion
{
	NSUInteger i;

	aVersion = (aVersion>self.migrations.count)?self.migrations.count:aVersion;

	if (aVersion < self.currentVersion) {
		for(i = self.currentVersion; i > aVersion; --i) {
			FmdbMigration *migration = [self.migrations objectAtIndex:i - 1];
			[migration downWithDatabase:self.db];
			[self recordVersionStateAfterMigrating:i - 1];
			currentVersion_ = i - 1;
		}
	} else {
		for(i = self.currentVersion; i < aVersion; ++i) {
			FmdbMigration *migration = [self.migrations objectAtIndex:i];
			[migration upWithDatabase:self.db];
			[self recordVersionStateAfterMigrating:i + 1];
			currentVersion_ = i + 1;
		}
	}
}

- (NSUInteger)currentVersion
{
	return (NSUInteger)[db_ intForQuery:[NSString stringWithFormat:@"SELECT version FROM %@", self.schemaMigrationsTableName]];
}

- (void)recordVersionStateAfterMigrating:(NSUInteger)version
{
	[db_ executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET version = ?", self.schemaMigrationsTableName], @(version)];
}

- (NSString *)schemaMigrationsTableName
{
	schemaMigrationsTableName_ = @"schema_info";
	return schemaMigrationsTableName_;
}

- (id)initWithDatabasePath:(NSString *)aPath
{
	if ((self = [super init])) {
		self.db = [FMDatabase databaseWithPath:aPath];
		if (![db_ open]) {
			NSLog(@"error opening the database for migration");
            [self release];
			return nil;
		}

		[self initializeSchemaMigrationsTable];

		currentVersion_ = (NSUInteger)[db_ intForQuery:[NSString stringWithFormat:@"SELECT version FROM %@", self.schemaMigrationsTableName]];
		if(currentVersion_ == 0) {
			NSInteger anyRows = [db_ intForQuery:[NSString stringWithFormat:@"SELECT count(version) FROM %@", self.schemaMigrationsTableName]];
			if (anyRows == 0) {
				[db_ executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (version) VALUES (0)", self.schemaMigrationsTableName]];
			}
		}
		return self;
	}
	return nil;
}

- (void)dealloc
{
	[db_ close];
	[db_ release];
	[migrations_ release];
	[schemaMigrationsTableName_ release];

	[super dealloc];
}
@end
