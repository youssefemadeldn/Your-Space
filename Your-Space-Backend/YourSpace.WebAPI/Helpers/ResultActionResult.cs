using Microsoft.AspNetCore.Mvc;
using YourSpace.Services.Helper;

namespace YourSpace.WebAPI.Helpers;

public class ResultActionResult<T> : ObjectResult
{
    public ResultActionResult(ServiceResult<T> result) : base(result)
    {
        StatusCode = result.StatusCode;
    }
}

public class ResultActionResult : ObjectResult
{
    public ResultActionResult(ServiceResult result) : base(result)
    {
        StatusCode = result.StatusCode;
    }
}
