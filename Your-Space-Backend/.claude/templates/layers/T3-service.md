---
name: T3-service
governed-by: CLAUDE.md "Error handling" · CLAUDE.md "Logging" · CLAUDE.md "Dependency injection" · dotnet_feature_prompt.md Rules 1, 5, 7
di-lifetime: "Scoped"
---

# T3 — Service + Interface

---

## Interface — `<Solution>.Services/Services/<Feature>Service/I<Feature>Service.cs`

```csharp
using <Solution>.Services.Helper;
using <Solution>.Services.Services.<Feature>Service.Dtos;

namespace <Solution>.Services.Services.<Feature>Service;

public interface I<Feature>Service
{
    Task<ServiceResult<<Entity>DetailsDto>> GetDetailsAsync(int id);
    Task<ServiceResult<PaginatedResultDto<<Entity>ProfileDto>>> GetAllAsync(
        PaginationSpecification pagination, string? search);
    Task<ServiceResult<<Entity>DetailsDto>> CreateAsync(Create<Entity>Dto dto);
    Task<ServiceResult<<Entity>DetailsDto>> UpdateAsync(Update<Entity>Dto dto);
    Task<ServiceResult> DeleteAsync(int id);
}
```

## Implementation — `<Solution>.Services/Services/<Feature>Service/<Feature>Service.cs`

```csharp
using AutoMapper;
using Microsoft.Extensions.Logging;
using <Solution>.Data.Entities;
using <Solution>.Repository.Interfaces;
using <Solution>.Repository.Specifications.<Feature>Specifications;
using <Solution>.Services.Helper;
using <Solution>.Services.Services.<Feature>Service.Dtos;

namespace <Solution>.Services.Services.<Feature>Service;

public class <Feature>Service : I<Feature>Service
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly ILogger<<Feature>Service> _logger;

    public <Feature>Service(IUnitOfWork unitOfWork, IMapper mapper, ILogger<<Feature>Service> logger)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
        _logger = logger;
    }

    // Query — guard clause for the expected "not found" outcome, no try/catch (Rule 1).
    public async Task<ServiceResult<<Entity>DetailsDto>> GetDetailsAsync(int id)
    {
        _logger.LogInformation("Fetching {Entity} {Id}", nameof(<Entity>), id);

        var repo = _unitOfWork.Repository<<Entity>, int>();
        var entity = await repo.GetByIdWithSpecAsync(new <Entity>WithSpecs(id));

        if (entity is null)
        {
            _logger.LogWarning("{Entity} {Id} not found", nameof(<Entity>), id);
            return ServiceResult<<Entity>DetailsDto>.NotFound($"{nameof(<Entity>)} {id} not found");
        }

        return ServiceResult<<Entity>DetailsDto>.Ok(_mapper.Map<<Entity>DetailsDto>(entity));
    }

    // Mutation touching one table — no transaction needed, SaveChangesAsync is already atomic.
    public async Task<ServiceResult<<Entity>DetailsDto>> CreateAsync(Create<Entity>Dto dto)
    {
        _logger.LogInformation("Creating {Entity} {Name}", nameof(<Entity>), dto.Name);

        var repo = _unitOfWork.Repository<<Entity>, int>();
        var entity = _mapper.Map<<Entity>>(dto);
        entity.CreatedAt = DateTime.UtcNow;
        entity.UpdatedAt = DateTime.UtcNow;

        await repo.AddAsync(entity);
        await _unitOfWork.SaveChangesAsync();

        _logger.LogInformation("{Entity} {Id} created", nameof(<Entity>), entity.Id);
        return ServiceResult<<Entity>DetailsDto>.Created(_mapper.Map<<Entity>DetailsDto>(entity));
    }

    // Mutation touching more than one table — transaction-wrapped (Rule 5).
    public async Task<ServiceResult> ReplaceRelatedRowsAsync(int id, List<SomethingDto> items)
    {
        var repo = _unitOfWork.Repository<<Entity>, int>();
        var entity = await repo.GetByIdAsync(id);
        if (entity is null)
            return ServiceResult.NotFound($"{nameof(<Entity>)} {id} not found");

        await using var transaction = await _unitOfWork.BeginTransactionAsync();
        try
        {
            // ... delete old rows, add new rows, across one or more repositories ...
            await _unitOfWork.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("Related rows replaced for {Entity} {Id}", nameof(<Entity>), id);
            return ServiceResult.Ok();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw; // ExceptionMiddleware decides the response — this catch only protects the transaction
        }
    }
}
```

---

## Notes

- **Registration:** `services.AddScoped<I<Feature>Service, <Feature>Service>();` in `ServiceRegistration.AddApplicationServices()` — grouped with the rest of the feature's registrations, not scattered.
- **When to extract a helper/domain-service instead of growing the service class:** only when (a) the same multi-step orchestration is needed by two or more services, or (b) the operation has non-trivial domain logic beyond "map, save, return" that deserves its own unit tests in isolation. A single repo-call-and-map operation stays a plain method on the feature's own service — don't build a ceremony layer for something with one caller.
- **Never inject `I<Feature>Service` into another service's constructor if it creates a cycle** — if two features' services need each other, the shared logic belongs in a helper both can depend on, not a mutual reference.
- Query methods that return a list use `<Entity>ProfileDto` (the list-row shape), never `<Entity>DetailsDto` — see `T4-dto.md`.
