using Microsoft.EntityFrameworkCore.Storage;

namespace YourSpace.Repository.Interfaces;

public interface IUnitOfWork : IAsyncDisposable
{
    IGenericRepository<TEntity, TKey> Repository<TEntity, TKey>() where TEntity : class;
    Task<int> SaveChangesAsync();
    Task<IDbContextTransaction> BeginTransactionAsync();
    Task CommitAsync(IDbContextTransaction transaction);
    Task RollbackAsync(IDbContextTransaction transaction);
}
