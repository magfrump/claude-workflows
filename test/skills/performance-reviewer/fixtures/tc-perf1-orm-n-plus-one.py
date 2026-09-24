from django.core.paginator import Paginator
from django.http import JsonResponse
from django.views.decorators.http import require_GET

from shop.models import Order


@require_GET
def recent_orders(request):
    """List the store's recent orders for the admin dashboard."""
    page_number = int(request.GET.get("page", 1))
    orders = Order.objects.filter(store=request.user.store).order_by("-created_at")
    page = Paginator(orders, 50).get_page(page_number)

    rows = []
    for order in page.object_list:
        rows.append(
            {
                "id": order.id,
                "created_at": order.created_at.isoformat(),
                "total": str(order.total),
                "customer": order.customer.full_name,
                "customer_email": order.customer.email,
                "item_count": order.items.count(),
                "shipping_method": order.shipping_method.label,
            }
        )

    return JsonResponse(
        {
            "page": page.number,
            "num_pages": page.paginator.num_pages,
            "orders": rows,
        }
    )
