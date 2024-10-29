using Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data;
using Joonasw.SeriouslySecuringAzurePaas.TodoApp.Data.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Web;

namespace Joonasw.SeriouslySecuringAzurePaas.TodoApp.Web.Pages;
public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    private readonly TodoContext _context;

    public IndexModel(
        ILogger<IndexModel> logger,
        TodoContext context)
    {
        _logger = logger;
        _context = context;
    }

    public List<TodoItem> TodoItems { get; set; } = new();

    public async Task OnGetAsync()
    {
        var (tenantId, userId) = GetTenantAndUserId();

        TodoItems = await _context.TodoItems
            .AsNoTracking()
            .Where(t => t.TenantId == tenantId && t.UserId == userId)
            .ToListAsync();
    }

    public async Task<IActionResult> OnPostAddTodoAsync(string? newTodoText)
    {
        if (string.IsNullOrWhiteSpace(newTodoText))
        {
            return RedirectToPage();
        }

        var (tenantId, userId) = GetTenantAndUserId();

        var newTodo = new TodoItem
        {
            TenantId = tenantId,
            UserId = userId,
            Text = newTodoText.Trim(),
            IsDone = false
        };

        _context.TodoItems.Add(newTodo);
        await _context.SaveChangesAsync();

        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostCompleteTodoAsync(Guid id)
    {
        var (tenantId, userId) = GetTenantAndUserId();

        var todo = await _context.TodoItems
            .Where(t => t.TenantId == tenantId && t.UserId == userId && t.Id == id)
            .SingleOrDefaultAsync();

        if (todo == null)
        {
            return NotFound();
        }

        todo.IsDone = true;
        await _context.SaveChangesAsync();

        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostDeleteTodoAsync(Guid id)
    {
        var (tenantId, userId) = GetTenantAndUserId();

        var todo = await _context.TodoItems
            .Where(t => t.TenantId == tenantId && t.UserId == userId && t.Id == id)
            .SingleOrDefaultAsync();

        if (todo == null)
        {
            return NotFound();
        }

        _context.TodoItems.Remove(todo);
        await _context.SaveChangesAsync();

        return RedirectToPage();
    }

    private (Guid tenantId, Guid userId) GetTenantAndUserId()
    {
        var tenantId = Guid.Parse(User.GetTenantId()!);
        var userId = Guid.Parse(User.GetObjectId()!);
        return (tenantId, userId);
    }
}
