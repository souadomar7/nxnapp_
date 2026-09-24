import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const { product_id, quantity, order_id, notes } = await req.json();
    const qty = parseInt(quantity, 10);

    if (!product_id || isNaN(qty) || qty <= 0) {
      return new Response(JSON.stringify({ error: 'product_id and positive quantity are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 1. Check current stock to prevent negative quantities (authoritative validation)
    const { data: inv, error: iErr } = await supabase
      .from('sme_inventory')
      .select('*')
      .eq('product_id', product_id)
      .eq('seller_id', user.id)
      .single();

    if (iErr || !inv) {
      throw new Error('No inventory record found for this product');
    }

    if (inv.quantity < qty) {
      throw new Error(
        `Insufficient inventory: available ${inv.quantity} units, requested ${qty} units`
      );
    }

    const newQty = inv.quantity - qty;
    const newStatus = newQty === 0 ? 'out_of_stock' : newQty < 10 ? 'low_stock' : 'in_stock';

    // 2. Insert audit movement (negative delta)
    await supabase.from('inventory_movements').insert({
      product_id,
      seller_id: user.id,
      warehouse_id: inv.warehouse_id,
      shelf_label: inv.shelf_label,
      movement_type: 'dispatch',
      quantity_delta: -qty,
      reference_type: 'order',
      reference_id: order_id ?? null,
      notes: notes ?? 'Dispatched for outbound shipment',
      created_by: user.id,
    });

    // 3. Update inventory
    await supabase
      .from('sme_inventory')
      .update({ quantity: newQty, status: newStatus })
      .eq('id', inv.id);

    await supabase
      .from('sme_products')
      .update({ quantity: newQty })
      .eq('id', product_id);

    return new Response(JSON.stringify({ success: true, remaining_quantity: newQty }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
