using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YourSpace.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddGovernorateGlobalNameUniqueIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Governorates_Name",
                table: "Governorates",
                column: "Name",
                unique: true,
                filter: "\"OwnerUserId\" IS NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Governorates_Name",
                table: "Governorates");
        }
    }
}
