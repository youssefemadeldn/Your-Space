namespace YourSpace.WebAPI.Middleware;

public class ValidationException(Dictionary<string, string[]> errors, string message = "Validation failed")
    : Exception(message)
{
    public Dictionary<string, string[]> Errors { get; } = errors;
}
