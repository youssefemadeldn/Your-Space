using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using YourSpace.Data.Contexts;
using YourSpace.Repository.Interfaces;

namespace YourSpace.Repository.Repositories;

public class UnitOfWork(YourSpaceDbContext context) : IUnitOfWork
{
    private readonly ConcurrentDictionary<(Type Entity, Type Key), object> _repositories = new();

    public IGenericRepository<TEntity, TKey> Repository<TEntity, TKey>() where TEntity : class
    {
        var cacheKey = (typeof(TEntity), typeof(TKey));
        return (IGenericRepository<TEntity, TKey>)_repositories.GetOrAdd(
            cacheKey, _ => new GenericRepository<TEntity, TKey>(context));
    }

    public Task<int> SaveChangesAsync() => context.SaveChangesAsync();

    public Task<IDbContextTransaction> BeginTransactionAsync() => context.Database.BeginTransactionAsync();

    public async Task CommitAsync(IDbContextTransaction transaction)
    {
        try
        {
            await transaction.CommitAsync();
        }
        catch
        {
            await RollbackAsync(transaction);
            throw;
        }
    }

    public Task RollbackAsync(IDbContextTransaction transaction) => transaction.RollbackAsync();

    public ValueTask DisposeAsync() => context.DisposeAsync();
}
