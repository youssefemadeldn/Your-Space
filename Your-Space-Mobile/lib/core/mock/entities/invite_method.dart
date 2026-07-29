/// Shared between [PersonOccasionHistoryEntry] and `EventGuest` — the backend
/// reuses this exact enum for both (confirmed against the backend DTO brief).
enum InviteMethod { whatsApp, phoneCall, physical }
