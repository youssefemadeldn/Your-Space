/// Which classification management screen/cubit pair to show — Governorate
/// deliberately has no management screen (no dedicated entry point, no
/// entry in this enum) per the locked spec: users can create custom
/// governorates via the wizard's inline "+ Add new" but never rename/delete
/// them from mobile in this sprint.
enum ClassificationEntityKind { subgroup, city, neighborhood }
