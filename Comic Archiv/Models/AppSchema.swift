//
//  AppSchema.swift
//  Comic Archiv
//
//  Versioned schema for SwiftData migrations.
//
//  HOW TO ADD A NEW VERSION (e.g. V2):
//
//  1. Copy the current live @Model classes into a frozen SchemaV2 enum
//     (same pattern as SchemaV1 below, bump version to 2, 0, 0).
//  2. Make your changes to the live @Model classes.
//  3. Add a MigrationStage:
//       .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
//     for additive/optional changes (new optional properties, new models).
//     For destructive changes use .custom(...) and write the migration closure.
//  4. Update AppMigrationPlan.schemas to [SchemaV1.self, SchemaV2.self].
//  5. Update AppMigrationPlan.stages with the new stage.

import SwiftData

// MARK: - V1  (current schema as of March 2026)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Comic.self, ComicList.self, ReadingOrderEntry.self, PlaceholderComic.self]
    }
}

// MARK: - Migration Plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
