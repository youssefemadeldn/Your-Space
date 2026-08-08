using System.Security.Cryptography;
using System.Text;
using Bogus;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using YourSpace.Data.Contexts;
using YourSpace.Data.Entities;
using YourSpace.Data.Enums;
using YourSpace.Services.Services.AuthService;
using YourSpace.Services.Services.OtpService;
using Person = YourSpace.Data.Entities.Person; // disambiguates from Bogus.Person, used by the Faker<Person> below

namespace YourSpace.WebAPI.Helpers;

// Development-only sample data — never runs outside app.Environment.IsDevelopment() (CLAUDE.md
// "Development Data Seeding"). Distinct from IdentitySeeder, which bootstraps real, production-needed
// data (roles, the first SuperAdmin) and therefore runs in every environment.
public static class MockDataSeeder
{
    private const string ActiveUserEmail = "seed.active@yourspace.dev";
    private const string LockedUserEmail = "seed.locked@yourspace.dev";
    private const string SeedUserPassword = "Seed!Pass123";

    public static async Task SeedAsync(YourSpaceDbContext context, UserManager<AppUser> userManager)
    {
        var (activeUserId, lockedUserId) = await SeedDevUsersAsync(userManager);

        await SeedRefreshTokensAsync(context, activeUserId, lockedUserId);
        await SeedEmailConfirmationCodesAsync(context, activeUserId, lockedUserId);
        await SeedPasswordResetCodesAsync(context, activeUserId, lockedUserId);

        await SeedGroupsAsync(context, activeUserId, lockedUserId);
        await SeedSubGroupsAsync(context, activeUserId, lockedUserId);
        await SeedGovernoratesAsync(context, activeUserId);
        await SeedCitiesAsync(context, activeUserId);
        await SeedNeighborhoodsAsync(context, activeUserId);
        await SeedPersonsAsync(context, activeUserId, lockedUserId);
        await SeedPersonImagesAsync(context, activeUserId);
        await SeedEventsAsync(context, activeUserId, lockedUserId);
        await SeedEventGuestsAsync(context, activeUserId);
        await SeedPersonOccasionHistoriesAsync(context, activeUserId);
        await SeedPersonRelationshipsAsync(context, activeUserId);
        await SeedUserSettingsAsync(context, activeUserId, lockedUserId);
    }

    // Dedicated, disposable local-dev fixture accounts — distinct from IdentitySeeder's real SuperAdmin
    // bootstrap — that exist only to give RefreshToken/EmailConfirmationCode/PasswordResetCode sample
    // rows a valid UserId to attach to. Created via UserManager (not a raw context insert) so password
    // hashing and the security stamp are set up the same way a real registration would.
    private static async Task<(string ActiveUserId, string LockedUserId)> SeedDevUsersAsync(UserManager<AppUser> userManager)
    {
        var activeUser = await GetOrCreateSeedUserAsync(userManager, ActiveUserEmail, "Seed", "Active", Gender.Male);
        var lockedUser = await GetOrCreateSeedUserAsync(userManager, LockedUserEmail, "Seed", "Locked", Gender.Female);
        return (activeUser.Id, lockedUser.Id);
    }

    private static async Task<AppUser> GetOrCreateSeedUserAsync(UserManager<AppUser> userManager, string email, string firstName, string lastName, Gender gender)
    {
        var existing = await userManager.FindByEmailAsync(email);
        if (existing is not null)
        {
            return existing;
        }

        var user = new AppUser
        {
            UserName = email,
            Email = email,
            FirstName = firstName,
            LastName = lastName,
            Gender = gender,
            EmailConfirmed = true
        };

        var createResult = await userManager.CreateAsync(user, SeedUserPassword);
        if (!createResult.Succeeded)
        {
            throw new InvalidOperationException(
                $"Failed to seed dev user {email}: {string.Join(", ", createResult.Errors.Select(e => e.Description))}");
        }

        await userManager.AddToRoleAsync(user, RoleNames.User);
        return user;
    }

    private static async Task SeedRefreshTokensAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.RefreshTokens.AnyAsync())
        {
            return;
        }

        await context.RefreshTokens.AddRangeAsync(
            new RefreshToken // normal case — active, unexpired session
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                TokenHash = HashSeedValue("seed-refresh-active"),
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                CreatedAt = DateTime.UtcNow
            },
            new RefreshToken // edge case — expired
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                TokenHash = HashSeedValue("seed-refresh-expired"),
                ExpiresAt = DateTime.UtcNow.AddDays(-1),
                CreatedAt = DateTime.UtcNow.AddDays(-8)
            },
            new RefreshToken // edge case — revoked via a completed rotation
            {
                Id = Guid.NewGuid(),
                UserId = lockedUserId,
                TokenHash = HashSeedValue("seed-refresh-rotated-out"),
                ExpiresAt = DateTime.UtcNow.AddDays(6),
                CreatedAt = DateTime.UtcNow.AddDays(-1),
                RevokedAt = DateTime.UtcNow.AddHours(-2),
                ReplacedByTokenHash = HashSeedValue("seed-refresh-post-rotation")
            });

        await context.SaveChangesAsync();
    }

    private static async Task SeedEmailConfirmationCodesAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.EmailConfirmationCodes.AnyAsync())
        {
            return;
        }

        var now = DateTime.UtcNow;
        await context.EmailConfirmationCodes.AddRangeAsync(
            new EmailConfirmationCode // normal case — still valid, unconsumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("111111"),
                CreatedAt = now,
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes),
                AttemptCount = 0
            },
            new EmailConfirmationCode // edge case — already consumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("222222"),
                CreatedAt = now.AddMinutes(-30),
                ExpiresAt = now.AddMinutes(-20),
                AttemptCount = 1,
                ConsumedAt = now.AddMinutes(-25)
            },
            new EmailConfirmationCode // edge case — locked out after max failed attempts
            {
                Id = Guid.NewGuid(),
                UserId = lockedUserId,
                CodeHash = HashSeedValue("333333"),
                CreatedAt = now.AddMinutes(-5),
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes - 5),
                AttemptCount = OtpConstants.MaxAttempts,
                ConsumedAt = now.AddMinutes(-1)
            });

        await context.SaveChangesAsync();
    }

    private static async Task SeedPasswordResetCodesAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.PasswordResetCodes.AnyAsync())
        {
            return;
        }

        var now = DateTime.UtcNow;
        await context.PasswordResetCodes.AddRangeAsync(
            new PasswordResetCode // normal case — still valid, unconsumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("444444"),
                CreatedAt = now,
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes),
                AttemptCount = 0
            },
            new PasswordResetCode // edge case — already consumed
            {
                Id = Guid.NewGuid(),
                UserId = activeUserId,
                CodeHash = HashSeedValue("555555"),
                CreatedAt = now.AddMinutes(-30),
                ExpiresAt = now.AddMinutes(-20),
                AttemptCount = 1,
                ConsumedAt = now.AddMinutes(-25)
            },
            new PasswordResetCode // edge case — locked out after max failed attempts
            {
                Id = Guid.NewGuid(),
                UserId = lockedUserId,
                CodeHash = HashSeedValue("666666"),
                CreatedAt = now.AddMinutes(-5),
                ExpiresAt = now.AddMinutes(OtpConstants.ExpiryMinutes - 5),
                AttemptCount = OtpConstants.MaxAttempts,
                ConsumedAt = now.AddMinutes(-1)
            });

        await context.SaveChangesAsync();
    }

    private static async Task SeedGroupsAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.Groups.AnyAsync())
        {
            return;
        }

        await context.Groups.AddRangeAsync(
            new Group { OwnerUserId = activeUserId, Name = "Relatives", NameAr = "الأقارب" },
            new Group { OwnerUserId = activeUserId, Name = "Village Friends", NameAr = "أصدقاء القرية" },
            new Group { OwnerUserId = activeUserId, Name = "University Friends", NameAr = "أصدقاء الجامعة" },
            new Group { OwnerUserId = activeUserId, Name = new string('A', 200) }, // edge case — max-length name
            new Group // edge case — soft-deleted
            {
                OwnerUserId = activeUserId,
                Name = "Old Neighbors (Archived)",
                DeletedAt = DateTime.UtcNow.AddDays(-10)
            },
            new Group { OwnerUserId = lockedUserId, Name = "Neighboring Village Friends" });

        await context.SaveChangesAsync();
    }

    private static async Task SeedSubGroupsAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.SubGroups.AnyAsync())
        {
            return;
        }

        var relatives = await context.Groups.SingleAsync(g => g.OwnerUserId == activeUserId && g.Name == "Relatives");
        var lockedUserGroup = await context.Groups.SingleAsync(g => g.OwnerUserId == lockedUserId);

        await context.SubGroups.AddRangeAsync(
            new SubGroup { OwnerUserId = activeUserId, GroupId = relatives.Id, Name = "Immediate Family", NameAr = "العائلة المباشرة" }, // normal case
            new SubGroup { OwnerUserId = activeUserId, GroupId = relatives.Id, Name = "Extended Family", NameAr = "العائلة الممتدة" }, // normal case
            new SubGroup { OwnerUserId = activeUserId, GroupId = relatives.Id, Name = new string('D', 200) }, // edge case — max-length name
            new SubGroup { OwnerUserId = lockedUserId, GroupId = lockedUserGroup.Id, Name = "Locked User's Subgroup" });

        await context.SaveChangesAsync();
    }

    // Global/seeded rows (OwnerUserId null, IsLocked true) plus one user-owned custom row — the
    // only entity in this codebase with that dual shape (see Governorate.cs's own comment).
    private static async Task SeedGovernoratesAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.Governorates.AnyAsync())
        {
            return;
        }

        (string En, string Ar)[] seeded =
        [
            ("Cairo", "القاهرة"), ("Giza", "الجيزة"), ("Alexandria", "الإسكندرية"),
            ("Al Qalyubia", "القليوبية"), ("Port Said", "بورسعيد"), ("Suez", "السويس"),
            ("Dakahlia", "الدقهلية"), ("Al Sharqia", "الشرقية"), ("Al Gharbia", "الغربية"),
            ("Al Monufia", "المنوفية"), ("Al Beheira", "البحيرة"), ("Kafr El Sheikh", "كفر الشيخ"),
            ("Damietta", "دمياط"), ("Ismailia", "الإسماعيلية"), ("Faiyum", "الفيوم"),
            ("Beni Suef", "بني سويف"), ("Minya", "المنيا"), ("Assiut", "أسيوط"),
            ("Sohag", "سوهاج"), ("Qena", "قنا"), ("Aswan", "أسوان"),
            ("Luxor", "الأقصر"), ("Red Sea", "البحر الأحمر"), ("New Valley", "الوادي الجديد"),
            ("Matrouh", "مطروح"), ("North Sinai", "شمال سيناء"), ("South Sinai", "جنوب سيناء")
        ];

        var governorates = seeded
            .Select(n => new Governorate { OwnerUserId = null, IsLocked = true, Name = n.En, NameAr = n.Ar })
            .ToList();

        // Edge case — a user-owned custom governorate, exercising the "global OR mine" visibility
        // rule and the not-locked/fully-editable path.
        governorates.Add(new Governorate { OwnerUserId = activeUserId, IsLocked = false, Name = "Custom Region (Seed)" });

        await context.Governorates.AddRangeAsync(governorates);
        await context.SaveChangesAsync();
    }

    private static async Task SeedCitiesAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.Cities.AnyAsync())
        {
            return;
        }

        var cairo = await context.Governorates.SingleAsync(g => g.OwnerUserId == null && g.Name == "Cairo");
        var giza = await context.Governorates.SingleAsync(g => g.OwnerUserId == null && g.Name == "Giza");

        await context.Cities.AddRangeAsync(
            new City { OwnerUserId = activeUserId, GovernorateId = cairo.Id, Name = "Nasr City", NameAr = "مدينة نصر" }, // normal case
            new City { OwnerUserId = activeUserId, GovernorateId = cairo.Id, Name = "Heliopolis", NameAr = "مصر الجديدة" }, // normal case
            new City { OwnerUserId = activeUserId, GovernorateId = giza.Id, Name = "6th of October", NameAr = "السادس من أكتوبر" }, // normal case, different parent
            new City { OwnerUserId = activeUserId, GovernorateId = cairo.Id, Name = new string('E', 200) }); // edge case — max-length name

        await context.SaveChangesAsync();
    }

    private static async Task SeedNeighborhoodsAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.Neighborhoods.AnyAsync())
        {
            return;
        }

        var nasrCity = await context.Cities.SingleAsync(c => c.OwnerUserId == activeUserId && c.Name == "Nasr City");

        await context.Neighborhoods.AddRangeAsync(
            new Neighborhood { OwnerUserId = activeUserId, CityId = nasrCity.Id, Name = "Zone 1", NameAr = "الحي الأول" }, // normal case
            new Neighborhood { OwnerUserId = activeUserId, CityId = nasrCity.Id, Name = "Zone 3", NameAr = "الحي الثالث" }, // normal case
            new Neighborhood // edge case — soft-deleted
            {
                OwnerUserId = activeUserId,
                CityId = nasrCity.Id,
                Name = "Old Zone (Archived)",
                DeletedAt = DateTime.UtcNow.AddDays(-15)
            });

        await context.SaveChangesAsync();
    }

    private static async Task SeedPersonsAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.People.AnyAsync())
        {
            return;
        }

        var relatives = await context.Groups.SingleAsync(g => g.OwnerUserId == activeUserId && g.Name == "Relatives");
        var villageFriends = await context.Groups.SingleAsync(g => g.OwnerUserId == activeUserId && g.Name == "Village Friends");
        var universityFriends = await context.Groups.SingleAsync(g => g.OwnerUserId == activeUserId && g.Name == "University Friends");
        var lockedUserGroup = await context.Groups.SingleAsync(g => g.OwnerUserId == lockedUserId);

        var immediateFamily = await context.SubGroups.SingleAsync(s => s.OwnerUserId == activeUserId && s.Name == "Immediate Family");
        var lockedUserSubGroup = await context.SubGroups.SingleAsync(s => s.OwnerUserId == lockedUserId);

        // Person.GovernorateId is required — every row below (Faker-generated and hand-literal
        // edge cases alike) needs one, per the migration that made this column NOT NULL.
        var cairo = await context.Governorates.SingleAsync(g => g.OwnerUserId == null && g.Name == "Cairo");
        var giza = await context.Governorates.SingleAsync(g => g.OwnerUserId == null && g.Name == "Giza");
        var nasrCity = await context.Cities.SingleAsync(c => c.OwnerUserId == activeUserId && c.Name == "Nasr City");
        var zone1 = await context.Neighborhoods.SingleAsync(n => n.OwnerUserId == activeUserId && n.Name == "Zone 1");

        var faker = new Faker<Person>()
            .RuleFor(p => p.OwnerUserId, _ => activeUserId)
            .RuleFor(p => p.Name, f => f.Name.FullName())
            .RuleFor(p => p.PhoneNumber, f => f.Random.Replace("+2010#######"))
            .RuleFor(p => p.Gender, f => f.PickRandom<Gender>())
            .RuleFor(p => p.GroupId, f => f.PickRandom(relatives.Id, villageFriends.Id, universityFriends.Id))
            .RuleFor(p => p.GovernorateId, f => f.PickRandom(cairo.Id, giza.Id))
            .RuleFor(p => p.CityId, (f, p) => p.GovernorateId == cairo.Id && f.Random.Bool() ? nasrCity.Id : (int?)null)
            .RuleFor(p => p.NeighborhoodId, (f, p) => p.CityId == nasrCity.Id && f.Random.Bool() ? zone1.Id : (int?)null);

        var persons = faker.Generate(15); // enough rows to exercise pagination

        persons.Add(new Person { OwnerUserId = activeUserId, Name = "Friend With No Phone", Gender = Gender.Male, GroupId = villageFriends.Id, GovernorateId = cairo.Id }); // edge case — null PhoneNumber
        persons.Add(new Person // edge case — max-length name, every classification field set
        {
            OwnerUserId = activeUserId,
            Name = new string('B', 200),
            Gender = Gender.Female,
            GroupId = relatives.Id,
            SubGroupId = immediateFamily.Id,
            GovernorateId = cairo.Id,
            CityId = nasrCity.Id,
            NeighborhoodId = zone1.Id
        });
        persons.Add(new Person // edge case — soft-deleted
        {
            OwnerUserId = activeUserId,
            Name = "Departed Contact",
            Gender = Gender.Male,
            GroupId = relatives.Id,
            GovernorateId = cairo.Id,
            DeletedAt = DateTime.UtcNow.AddDays(-5)
        });

        persons.Add(new Person
        {
            OwnerUserId = lockedUserId,
            Name = "Locked User's Friend",
            PhoneNumber = "+201111111111",
            Gender = Gender.Female,
            GroupId = lockedUserGroup.Id,
            SubGroupId = lockedUserSubGroup.Id,
            GovernorateId = giza.Id
        });

        await context.People.AddRangeAsync(persons);
        await context.SaveChangesAsync();
    }

    // ObjectKeys here are deliberately fake — they were never actually uploaded to R2, so a presigned
    // URL built from one will 404 if the app tries to fetch it. Seeding can't realistically call the
    // live R2 API for fabricated Bogus rows with no real file bytes behind them; this still satisfies
    // Rule 9's shape requirement (a normal 0-image person by omission, a 1-image person, and the 6-image
    // boundary with exactly one primary) so pagination/UI states have something to render against.
    private static async Task SeedPersonImagesAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.PersonImages.AnyAsync())
        {
            return;
        }

        var persons = await context.People
            .Where(p => p.OwnerUserId == activeUserId && p.DeletedAt == null)
            .OrderBy(p => p.Id)
            .Take(2)
            .ToListAsync();

        var onePhotoPerson = persons[0];
        var sixPhotoPerson = persons[1];

        var images = new List<PersonImage>
        {
            new() { PersonId = onePhotoPerson.Id, ObjectKey = $"people/{onePhotoPerson.Id}/seed-fake-1.jpg", IsPrimary = true }
        };

        for (var i = 1; i <= 6; i++)
        {
            images.Add(new PersonImage
            {
                PersonId = sixPhotoPerson.Id,
                ObjectKey = $"people/{sixPhotoPerson.Id}/seed-fake-{i}.jpg",
                IsPrimary = i == 1 // exactly one primary — enforced by the partial unique index too
            });
        }

        await context.PersonImages.AddRangeAsync(images);
        await context.SaveChangesAsync();
    }

    private static async Task SeedEventsAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.Events.AnyAsync())
        {
            return;
        }

        await context.Events.AddRangeAsync(
            new Event // normal case — upcoming, with date and notes
            {
                OwnerUserId = activeUserId,
                Name = "Brother's Wedding",
                NameAr = "فرح أخي",
                EventDate = DateTime.UtcNow.AddMonths(2),
                Notes = "Village hall, evening reception."
            },
            new Event // normal case — already happened
            {
                OwnerUserId = activeUserId,
                Name = "Cousin's Engagement",
                EventDate = DateTime.UtcNow.AddMonths(-3)
            },
            new Event { OwnerUserId = activeUserId, Name = "Graduation Party" }, // edge case — no date set yet, still being planned
            new Event // edge case — soft-deleted (cancelled)
            {
                OwnerUserId = activeUserId,
                Name = "Cancelled Gathering",
                DeletedAt = DateTime.UtcNow.AddDays(-1)
            },
            new Event { OwnerUserId = lockedUserId, Name = "Locked User's Event" });

        await context.SaveChangesAsync();
    }

    private static async Task SeedEventGuestsAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.EventGuests.AnyAsync())
        {
            return;
        }

        var wedding = await context.Events.SingleAsync(e => e.OwnerUserId == activeUserId && e.Name == "Brother's Wedding");
        var persons = await context.People
            .Where(p => p.OwnerUserId == activeUserId && p.DeletedAt == null)
            .OrderBy(p => p.Id)
            .Take(5)
            .ToListAsync();

        var now = DateTime.UtcNow;
        await context.EventGuests.AddRangeAsync(
            new EventGuest // normal case — invited via WhatsApp
            {
                EventId = wedding.Id,
                PersonId = persons[0].Id,
                Status = EventGuestStatus.Invited,
                InviteMethod = InviteMethod.WhatsApp,
                InvitedAt = now.AddDays(-2)
            },
            new EventGuest // normal case — invited via phone call
            {
                EventId = wedding.Id,
                PersonId = persons[1].Id,
                Status = EventGuestStatus.Invited,
                InviteMethod = InviteMethod.PhoneCall,
                InvitedAt = now.AddDays(-1)
            },
            new EventGuest // normal case — invited in person
            {
                EventId = wedding.Id,
                PersonId = persons[2].Id,
                Status = EventGuestStatus.Invited,
                InviteMethod = InviteMethod.Physical,
                InvitedAt = now
            },
            new EventGuest { EventId = wedding.Id, PersonId = persons[3].Id, Status = EventGuestStatus.NotInvited }, // normal case — not reached yet
            new EventGuest { EventId = wedding.Id, PersonId = persons[4].Id, Status = EventGuestStatus.Skipped }); // edge case — deliberately excluded

        await context.SaveChangesAsync();
    }

    private static async Task SeedPersonOccasionHistoriesAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.PersonOccasionHistories.AnyAsync())
        {
            return;
        }

        var persons = await context.People
            .Where(p => p.OwnerUserId == activeUserId && p.DeletedAt == null)
            .OrderBy(p => p.Id)
            .Take(3)
            .ToListAsync();

        await context.PersonOccasionHistories.AddRangeAsync(
            new PersonOccasionHistory // normal case — invited the user via WhatsApp
            {
                PersonId = persons[0].Id,
                InvitedMe = true,
                InviteMethod = InviteMethod.WhatsApp,
                OccasionName = "His Wedding",
                OccasionDate = DateTime.UtcNow.AddYears(-1)
            },
            new PersonOccasionHistory // normal case — did not invite the user
            {
                PersonId = persons[0].Id,
                InvitedMe = false,
                OccasionName = "Her Graduation",
                OccasionDate = DateTime.UtcNow.AddMonths(-6)
            },
            new PersonOccasionHistory // edge case — max-length notes, no name/date recorded
            {
                PersonId = persons[1].Id,
                InvitedMe = true,
                InviteMethod = InviteMethod.PhoneCall,
                Notes = new string('C', 2000)
            },
            new PersonOccasionHistory // edge case — minimal detail, invited via a physical visit
            {
                PersonId = persons[2].Id,
                InvitedMe = true,
                InviteMethod = InviteMethod.Physical
            });

        await context.SaveChangesAsync();
    }

    // Bypasses PersonRelationshipService (raw context inserts), so it must manually replicate the
    // two-row-plus-cross-link shape from PersonRelationshipService.CreateAsync — insert both rows,
    // save (real Ids), cross-link InverseRelationshipId, save again.
    private static async Task SeedPersonRelationshipsAsync(YourSpaceDbContext context, string activeUserId)
    {
        if (await context.PersonRelationships.AnyAsync())
        {
            return;
        }

        var persons = await context.People
            .Where(p => p.OwnerUserId == activeUserId && p.DeletedAt == null)
            .OrderBy(p => p.Id)
            .Take(4)
            .ToListAsync();

        // Normal case — a Father/Son pair.
        await AddSeedRelationshipPairAsync(context, personId: persons[1].Id, relatedPersonId: persons[0].Id, relationType: RelationType.Father, inverseType: RelationType.Son);

        // Normal case — a Husband/Wife pair (different two people than the pair above).
        await AddSeedRelationshipPairAsync(context, personId: persons[2].Id, relatedPersonId: persons[3].Id, relationType: RelationType.Wife, inverseType: RelationType.Husband);

        // Every other seeded person (there's no explicit row for this — it's simply everyone not
        // referenced above) is left with zero relationships, the natural normal case for most
        // people, who won't have a family graph entered yet.
    }

    private static async Task AddSeedRelationshipPairAsync(
        YourSpaceDbContext context, int personId, int relatedPersonId, RelationType relationType, RelationType inverseType)
    {
        var original = new PersonRelationship { PersonId = personId, RelatedPersonId = relatedPersonId, RelationType = relationType };
        var inverse = new PersonRelationship { PersonId = relatedPersonId, RelatedPersonId = personId, RelationType = inverseType };

        await context.PersonRelationships.AddRangeAsync(original, inverse);
        await context.SaveChangesAsync(); // real Ids needed before the two rows can cross-link

        original.InverseRelationshipId = inverse.Id;
        inverse.InverseRelationshipId = original.Id;
        await context.SaveChangesAsync();
    }

    private static async Task SeedUserSettingsAsync(YourSpaceDbContext context, string activeUserId, string lockedUserId)
    {
        if (await context.UserSettings.AnyAsync())
        {
            return;
        }

        await context.UserSettings.AddRangeAsync(
            new UserSettings { UserId = activeUserId, ReciprocitySuggestionsEnabled = true }, // edge case — enabled
            new UserSettings { UserId = lockedUserId, ReciprocitySuggestionsEnabled = false }); // normal case — default off

        await context.SaveChangesAsync();
    }

    // Mirrors TokenService.HashToken's SHA-256 hex algorithm — these seed rows are never presented by a
    // real client, but using the same hash shape keeps them realistic rather than placeholder text.
    private static string HashSeedValue(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}
