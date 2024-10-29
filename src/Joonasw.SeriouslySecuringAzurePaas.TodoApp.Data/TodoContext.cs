using Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data;

public class TodoContext : DbContext
{
    public TodoContext(DbContextOptions<TodoContext> options)
        : base(options)
    {   
    }

    public DbSet<TodoItem> TodoItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TodoItem>()
            .HasKey(t => t.Id);

        modelBuilder.Entity<TodoItem>()
            .Property(t => t.Id)
            .HasDefaultValueSql("NEWID()");

        modelBuilder.Entity<TodoItem>()
            .Property(t => t.Text)
            .IsRequired()
            .HasMaxLength(200);

        modelBuilder.Entity<TodoItem>()
            .Property(t => t.IsDone)
            .HasDefaultValue(false);

        modelBuilder.Entity<TodoItem>()
            .HasIndex(t => new { t.TenantId, t.UserId });
    }
}
