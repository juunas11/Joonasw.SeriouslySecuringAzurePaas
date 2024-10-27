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

    [BindProperty]
    public string? NewTodoText { get; set; }

    public async Task OnGet()
    {
        var tenantId = Guid.Parse(User.GetTenantId()!);
        var userId = Guid.Parse(User.GetObjectId()!);

        TodoItems = await _context.TodoItems
            .AsNoTracking()
            .Where(t => t.TenantId == tenantId && t.UserId == userId)
            .ToListAsync();
    }
}
