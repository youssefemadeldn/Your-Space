namespace YourSpace.WebAPI.Middleware;

public class NotFoundException(string message) : Exception(message)
{
}
