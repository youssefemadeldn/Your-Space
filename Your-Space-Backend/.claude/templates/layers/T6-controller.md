---
name: T6-controller
governed-by: CLAUDE.md "Response envelope" · dotnet_feature_prompt.md Rule 6 & §6 (API layer checklist)
---

# T6 — API Controller

Thin by construction: parse input, call one service method, wrap the result. No business logic, no branching on `result.Success`.

---

## `<Solution>.WebAPI/Controllers/<Feature>Controller.cs`

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using <Solution>.Repository.Specifications.Paginated;
using <Solution>.Services.Services.<Feature>Service;
using <Solution>.Services.Services.<Feature>Service.Dtos;
using <Solution>.WebAPI.Helpers;

namespace <Solution>.WebAPI.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/<feature-plural>")]
public class <Feature>Controller : ControllerBase
{
    private readonly I<Feature>Service _service;

    public <Feature>Controller(I<Feature>Service service) => _service = service;

    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll([FromQuery] string? search, [FromQuery] PaginationSpecification pagination)
    {
        var result = await _service.GetAllAsync(pagination, search);
        return new ResultActionResult<PaginatedResultDto<<Entity>ProfileDto>>(result);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDetails(int id)
    {
        var result = await _service.GetDetailsAsync(id);
        return new ResultActionResult<<Entity>DetailsDto>(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Create([FromBody] Create<Entity>Dto dto)
    {
        var result = await _service.CreateAsync(dto);
        return new ResultActionResult<<Entity>DetailsDto>(result);
    }

    [HttpPut]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update([FromBody] Update<Entity>Dto dto)
    {
        var result = await _service.UpdateAsync(dto);
        return new ResultActionResult<<Entity>DetailsDto>(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var result = await _service.DeleteAsync(id);
        return new ResultActionResult(result);
    }
}
```

## Extracting the caller's identity from the JWT (when an action needs "the current user")

```csharp
var userIdClaim = User.FindFirst("uid")?.Value;
if (string.IsNullOrWhiteSpace(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
    return new ResultActionResult<SomeDto>(ServiceResult<SomeDto>.Unauthorized("Invalid user ID"));
```

---

## Notes

- **`[ApiVersion]` + `[Route("api/v{version:apiVersion}/...")]` on every controller**, not just the ones that have shipped a v2 — versioning is free to add on day one and expensive to retrofit onto live clients later.
- **Every action that mutates state has `[Authorize]`** with the narrowest role/policy that's actually correct — never leave it commented out while iterating locally; use a test-environment-satisfiable role instead (`dotnet_feature_prompt.md` Rule 6).
- **`ProducesResponseType` attributes should match what `ExceptionMiddleware` and the service can actually return** for that action — documenting a 409 the endpoint can never produce is as misleading as omitting one it does produce.
- **No `try/catch` in a controller action, ever** — that's exactly the job `ExceptionMiddleware` and the service layer already do (CLAUDE.md "Error handling").
- If an endpoint is genuinely public (no `[Authorize]`), say so with a one-line comment stating why — silence reads as "someone forgot," not "this is intentional."
