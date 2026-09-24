import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const { product_id, warehouse_id, shelf_label, quantity, notes } = await req.json();
    const qty = parseInt(quantity, 10);

    if (!product_id || isNaN(qty) || qty <= 0) {
      return new Response(JSON.stringify({ error: 'product_id and positive quantity are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 1. Verify product ownership
    const { data: product, error: pErr } = await supabase
      .from('sme_products')
      .select('id, name')
      .eq('id', product_id)
      .eq('seller_id', user.id)
      .single();

    if (pErr || !product) {
      throw new Error('Product not found or not owned by user');
    }

    // 2. Insert audit movement
    await supabase.from('inventory_movements').insert({
      product_id,
      seller_id: user.id,
      warehouse_id: warehouse_id ?? null,
      shelf_label: shelf_label ?? 'Default Shelf',
      movement_type: 'receive',
      quantity_delta: qty,
      reference_type: 'inbound',
      notes: notes ?? 'Received via inbound flow',
      created_by: user.id,
    });

    // 3. Upsert into sme_inventory
    const { data: existingInv } = await supabase
      .from('sme_inventory')
      .select('id, quantity')
      .eq('product_id', product_id)
      .eq('seller_id', user.id)
      .maybeSingle();

    let newQty = qty;
    if (existingInv) {
      newQty = existingInv.quantity + qty;
      const status = newQty > 10 ? 'in_stock' : 'low_stock';
      await supabase
        .from('sme_inventory')
        .update({ quantity: newQty, status })
        .eq('id', existingInv.id);
    } else {
      await supabase.from('sme_inventory').insert({
        seller_id: user.id,
        product_id,
        warehouse_id: warehouse_id ?? 'dxb',
        shelf_label: shelf_label ?? 'A-01-S1',
        quantity: newQty,
        status: newQty > 10 ? 'in_stock' : 'low_stock',
      });
    }

    // Update product quantity total
    await supabase
      .from('sme_products')
      .update({ quantity: newQty })
      .eq('id', product_id);

    return new Response(JSON.stringify({ success: true, new_quantity: newQty }), {
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
