using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YourSpace.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddGovernorateSyncVersion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Monotonic delta-sync cursor (doc/local-first-sync-design.md §6) — bumped explicitly
            // by ISyncVersionProvider/GovernorateService on every create/update/soft-delete, never
            // left to its column default after the first write (a bigserial-style column only
            // auto-populates on INSERT, never on UPDATE).
            migrationBuilder.Sql("CREATE SEQUENCE IF NOT EXISTS \"Governorates_SyncVersion_seq\";");

            migrationBuilder.AddColumn<long>(
                name: "SyncVersion",
                table: "Governorates",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            // Backfill existing rows (both global seeded rows and any user-owned custom rows)
            // with an increasing version consistent with creation order (not all left at the
            // column default 0, which would make them indistinguishable to a
            // `WHERE SyncVersion > @since` pull), then advance the sequence past the backfilled
            // max so the very next real write can't collide with a backfilled value.
            migrationBuilder.Sql("""
                WITH ordered AS (
                    SELECT "Id", ROW_NUMBER() OVER (ORDER BY "CreatedAt", "Id") AS rn FROM "Governorates"
                )
                UPDATE "Governorates" g SET "SyncVersion" = ordered.rn FROM ordered WHERE g."Id" = ordered."Id";
                """);
            migrationBuilder.Sql(
                "SELECT setval('\"Governorates_SyncVersion_seq\"', (SELECT COALESCE(MAX(\"SyncVersion\"), 0) FROM \"Governorates\"));");

            migrationBuilder.CreateIndex(
                name: "IX_Governorates_SyncVersion",
                table: "Governorates",
                column: "SyncVersion");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Governorates_SyncVersion",
                table: "Governorates");

            migrationBuilder.DropColumn(
                name: "SyncVersion",
                table: "Governorates");

            migrationBuilder.Sql("DROP SEQUENCE IF EXISTS \"Governorates_SyncVersion_seq\";");
        }
    }
}
