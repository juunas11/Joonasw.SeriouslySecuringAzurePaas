namespace Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data.Models;
public class TodoItem
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid UserId { get; set; }
    public required string Text { get; set; }
    public bool IsDone { get; set; }
}
