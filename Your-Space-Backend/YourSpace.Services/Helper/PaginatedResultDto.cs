namespace YourSpace.Services.Helper;

public class PaginatedResultDto<T>
{
    public IReadOnlyList<T> Items { get; }
    public int PageIndex { get; }
    public int PageSize { get; }
    public int TotalItems { get; }
    public int TotalPages { get; }

    public PaginatedResultDto(IReadOnlyList<T> items, int pageIndex, int pageSize, int totalItems, int totalPages)
    {
        Items = items;
        PageIndex = pageIndex;
        PageSize = pageSize;
        TotalItems = totalItems;
        TotalPages = totalPages;
    }
}
