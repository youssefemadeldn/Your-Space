# Release Note — 007 v5.0.1+10 · Person Search & Groups

**Date:** 2026-09-09  
**Version:** 5.0.1+10  
**Platform:** Google Play  
**Commit range:** 9983b28..4f32588 (mobile-facing: 4f32588)

---

## Play Console — copy this block

```
<en-US>
• Family search: When linking a relative to a person, search now covers all your people, not just the first ones loaded.
• Add a group inline: Create a new group right from the Add Person screen without leaving the flow.
• Clearer family entries: A half-filled family member now asks you to finish or remove it instead of being dropped silently.
• Smoother loading: If groups or locations fail to load, you get a clear message with retry, and the screen stays safe to leave while saving.
</en-US>
<ar>
• البحث عن الأقارب: عند ربط قريب بشخص، أصبح البحث يشمل كل جهاتك وليس أول النتائج المحمّلة فقط.
• إضافة مجموعة فوراً: أنشئ مجموعة جديدة من شاشة إضافة شخص دون مغادرة الخطوات.
• إدخال عائلي أوضح: إذا كان فرد العائلة غير مكتمل، يُطلب منك إكماله أو حذفه بدل تجاهله بصمت.
• تحميل أسلس: عند فشل تحميل المجموعات أو المواقع تظهر رسالة واضحة مع إعادة المحاولة، ويمكن مغادرة الشاشة بأمان أثناء الحفظ.
</ar>
```

---

## Character counts

| Language | Count | Limit |
|----------|-------|-------|
| en-US    | 487 | 500 |
| ar       | 389 | 500 |

---

## What changed (context — not for the Play Console)

Single mobile commit today: `4f32588 feat: Enhance person wizard with server-side search and inline group addition`.

- Relationship person lookup in the Add/Edit Person flow now queries the server (debounced) instead of filtering a fixed 200-record snapshot.
- Group picker gains an inline "Add group" action (governorate already had one).
- Half-completed family-member rows are validated before advancing, with a clear message, instead of being silently discarded on save.
- Empty-state labels added for the group/governorate pickers.
- Reference-data load failures now show an error state with retry; leaving the screen mid-save no longer risks a bad state.

Other commits today are out of scope for mobile release notes: `7bf7445` (backend — Governorate unique index + seeder), `557c472` (chore — Dart launch/settings config).
