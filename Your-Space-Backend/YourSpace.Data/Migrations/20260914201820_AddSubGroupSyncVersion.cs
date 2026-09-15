using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YourSpace.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSubGroupSyncVersion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Monotonic delta-sync cursor (doc/local-first-sync-design.md §6) — bumped explicitly
            // by ISyncVersionProvider/SubGroupService on every create/update/soft-delete, never
            // left to its column default after the first write (a bigserial-style column only
            // auto-populates on INSERT, never on UPDATE).
            migrationBuilder.Sql("CREATE SEQUENCE IF NOT EXISTS \"SubGroups_SyncVersion_seq\";");

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "SubGroups",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            // Backfill existing rows with an increasing version consistent with creation order
            // (not all left at the column default 0, which would make them indistinguishable to
            // a `WHERE SyncVersion > @since` pull), then advance the sequence past the backfilled
            // max so the very next real write can't collide with a backfilled value.
            migrationBuilder.Sql("""
                WITH ordered AS (
                    SELECT "Id", ROW_NUMBER() OVER (ORDER BY "CreatedAt", "Id") AS rn FROM "SubGroups"
                )
                UPDATE "SubGroups" s SET "SyncVersion" = ordered.rn FROM ordered WHERE s."Id" = ordered."Id";
                """);
            // GREATEST(...,1) plus the is_called flag guards against Postgres's own setval bounds
            // check on an empty table: setval(seq, 0) errors ("value 0 is out of bounds") because
            // the sequence's default MINVALUE is 1. Passing is_called = false when there are no
            // rows yet makes the *next* nextval() return exactly 1 instead of skipping it — fixes
            // the empty-table setval bug flagged since row 8.17, applied solution-wide in row 9.5.
            migrationBuilder.Sql("""
                SELECT setval(
                    '"SubGroups_SyncVersion_seq"',
                    GREATEST((SELECT COALESCE(MAX("SyncVersion"), 0) FROM "SubGroups"), 1),
                    (SELECT COUNT(*) FROM "SubGroups") > 0
                );
                """);

            migrationBuilder.CreateIndex(
                name: "IX_SubGroups_OwnerUserId_SyncVersion",
                table: "SubGroups",
                columns: new[] { "OwnerUserId", "SyncVersion" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SubGroups_OwnerUserId_SyncVersion",
                table: "SubGroups");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "SubGroups");

            migrationBuilder.Sql("DROP SEQUENCE IF EXISTS \"SubGroups_SyncVersion_seq\";");
        }
    }
}
