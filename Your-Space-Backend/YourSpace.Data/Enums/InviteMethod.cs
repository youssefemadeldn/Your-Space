namespace YourSpace.Data.Enums;

// Reused by EventGuest (the method chosen live when inviting for the user's own event) and by
// PersonOccasionHistory (how a person invited the user in the past) — same 3 real-world channels.
public enum InviteMethod
{
    WhatsApp,
    PhoneCall,
    Physical
}
