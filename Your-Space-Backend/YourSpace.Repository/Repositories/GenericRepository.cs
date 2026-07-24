using Microsoft.EntityFrameworkCore;
using YourSpace.Data.Contexts;
using YourSpace.Repository.Interfaces;
using YourSpace.Repository.Specifications;

namespace YourSpace.Repository.Repositories;

public class GenericRepository<TEntity, TKey>(YourSpaceDbContext context) : IGenericRepository<TEntity, TKey>
    where TEntity : class
{
    public async Task<TEntity?> GetByIdAsync(TKey id)
        => await context.Set<TEntity>().FindAsync(id);

    public async Task<TEntity?> GetByIdWithSpecAsync(ISpecification<TEntity> spec)
        => await ApplySpecification(spec).AsNoTracking().FirstOrDefaultAsync();

    public async Task<IReadOnlyList<TEntity>> ListAllAsync()
        => await context.Set<TEntity>().AsNoTracking().ToListAsync();

    public async Task<IReadOnlyList<TEntity>> ListAllWithSpecAsync(ISpecification<TEntity> spec)
        => await ApplySpecification(spec).AsNoTracking().ToListAsync();

    public async Task<TEntity> AddAsync(TEntity entity)
    {
        await context.Set<TEntity>().AddAsync(entity);
        return entity;
    }

    public async Task<List<TEntity>> AddRangeAsync(List<TEntity> entities)
    {
        await context.Set<TEntity>().AddRangeAsync(entities);
        return entities;
    }

    public void Update(TEntity entity)
        => context.Set<TEntity>().Update(entity);

    public void Delete(TEntity entity)
        => context.Set<TEntity>().Remove(entity);

    public async Task<int> CountAsync()
        => await context.Set<TEntity>().AsNoTracking().CountAsync();

    public async Task<int> CountWithSpecAsync(ISpecification<TEntity> spec)
        => await ApplySpecification(spec).AsNoTracking().CountAsync();

    public async Task<bool> ExistsAsync(TKey id)
        => await context.Set<TEntity>().FindAsync(id) is not null;

    private IQueryable<TEntity> ApplySpecification(ISpecification<TEntity> spec)
        => SpecificationEvaluator.GetQuery(context.Set<TEntity>().AsQueryable(), spec);
}
