namespace Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data.Models;
public class TodoItem
{
    // In this model we store all tenants' data in the same table.
    // You should consider usage of separate tables/schemas/databases in a production multi-tenant system.
    // I'm keeping it simple for demo purposes.

    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid UserId { get; set; }
    public required string Text { get; set; }
    public bool IsDone { get; set; }
}
