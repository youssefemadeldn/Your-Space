using YourSpace.Repository.Specifications;

namespace YourSpace.Repository.Interfaces;

public interface IGenericRepository<TEntity, TKey> where TEntity : class
{
    Task<TEntity?> GetByIdAsync(TKey id);
    Task<TEntity?> GetByIdWithSpecAsync(ISpecification<TEntity> spec);
    Task<IReadOnlyList<TEntity>> ListAllAsync();
    Task<IReadOnlyList<TEntity>> ListAllWithSpecAsync(ISpecification<TEntity> spec);
    Task<TEntity> AddAsync(TEntity entity);
    Task<List<TEntity>> AddRangeAsync(List<TEntity> entities);
    void Update(TEntity entity);
    void Delete(TEntity entity);
    Task<int> CountAsync();
    Task<int> CountWithSpecAsync(ISpecification<TEntity> spec);
    Task<bool> ExistsAsync(TKey id);
}
