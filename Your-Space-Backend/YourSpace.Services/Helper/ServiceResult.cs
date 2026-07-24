namespace YourSpace.Services.Helper;

public class ServiceResult<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public int StatusCode { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public Dictionary<string, string[]>? Errors { get; set; }

    public static ServiceResult<T> Ok(T data, string message = "Success")
        => new() { Success = true, Data = data, Message = message, StatusCode = 200 };

    public static ServiceResult<T> Created(T data, string message = "Created successfully")
        => new() { Success = true, Data = data, Message = message, StatusCode = 201 };

    public static ServiceResult<T> Fail(string message, int statusCode = 400, Dictionary<string, string[]>? errors = null)
        => new() { Success = false, Message = message, StatusCode = statusCode, Errors = errors };

    public static ServiceResult<T> NotFound(string message = "Resource not found")
        => new() { Success = false, Message = message, StatusCode = 404 };

    public static ServiceResult<T> Unauthorized(string message = "Unauthorized access")
        => new() { Success = false, Message = message, StatusCode = 401 };

    public static ServiceResult<T> Forbidden(string message = "Access forbidden")
        => new() { Success = false, Message = message, StatusCode = 403 };

    public static ServiceResult<T> ValidationError(Dictionary<string, string[]> errors, string message = "Validation failed")
        => new() { Success = false, Message = message, StatusCode = 422, Errors = errors };

    public static ServiceResult<T> ServerError(string message = "Internal server error")
        => new() { Success = false, Message = message, StatusCode = 500 };

    public static ServiceResult<T> Conflict(string message = "Conflict occurred")
        => new() { Success = false, Message = message, StatusCode = 409 };
}

public class ServiceResult
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public int StatusCode { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public Dictionary<string, string[]>? Errors { get; set; }

    public static ServiceResult Ok(string message = "Success")
        => new() { Success = true, Message = message, StatusCode = 200 };

    public static ServiceResult Created(string message = "Created successfully")
        => new() { Success = true, Message = message, StatusCode = 201 };

    public static ServiceResult Fail(string message, int statusCode = 400, Dictionary<string, string[]>? errors = null)
        => new() { Success = false, Message = message, StatusCode = statusCode, Errors = errors };

    public static ServiceResult NotFound(string message = "Resource not found")
        => new() { Success = false, Message = message, StatusCode = 404 };

    public static ServiceResult Unauthorized(string message = "Unauthorized access")
        => new() { Success = false, Message = message, StatusCode = 401 };

    public static ServiceResult Forbidden(string message = "Access forbidden")
        => new() { Success = false, Message = message, StatusCode = 403 };

    public static ServiceResult ValidationError(Dictionary<string, string[]> errors, string message = "Validation failed")
        => new() { Success = false, Message = message, StatusCode = 422, Errors = errors };

    public static ServiceResult ServerError(string message = "Internal server error")
        => new() { Success = false, Message = message, StatusCode = 500 };

    public static ServiceResult Conflict(string message = "Conflict occurred")
        => new() { Success = false, Message = message, StatusCode = 409 };
}
