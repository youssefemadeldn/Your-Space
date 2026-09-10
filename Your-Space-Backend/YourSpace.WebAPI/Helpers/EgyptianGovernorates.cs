namespace YourSpace.WebAPI.Helpers;

// The canonical list of Egypt's 27 governorates (English + Arabic), used as the shared/global
// reference rows (OwnerUserId null, IsLocked true) that every user sees. Single source of truth
// for both ReferenceDataSeeder (seeds them into every environment on boot) and MockDataSeeder
// (dev-only downstream sample data that assumes "Cairo"/"Giza" exist).
public static class EgyptianGovernorates
{
    public static readonly IReadOnlyList<(string En, string Ar)> All =
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
}
