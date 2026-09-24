import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const { action_type, payload = {} } = await req.json();

    if (!action_type) {
      return new Response(JSON.stringify({ error: 'action_type is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Explicit whitelist of actions that AI can trigger after user confirmation
    switch (action_type) {
      case 'create_booking_quote': {
        const warehouseId = payload.warehouse_id ?? 'dxb';
        const shelves = parseInt(payload.shelves ?? '5', 10);
        const months = parseInt(payload.months ?? '1', 10);
        const storageType = payload.storage_type ?? 'ambient';

        const { data: settings } = await supabase.from('platform_settings').select('key, value');
        const settingsMap: Record<string, string> = {};
        for (const s of settings ?? []) settingsMap[s.key] = s.value;

        const basePrice = parseFloat(settingsMap['shelf_base_price_aed'] ?? '100');
        const vatRate = parseFloat(settingsMap['vat_rate'] ?? '0.05');
        const feeRate = parseFloat(settingsMap['platform_fee_rate'] ?? '0.05');

        const mult = storageType === 'cold_storage' ? 1.5 : storageType === 'chilled' ? 1.3 : 1.0;
        const subtotal = basePrice * shelves * months * mult;
        const platformFee = Math.round(subtotal * feeRate * 100) / 100;
        const vat = Math.round((subtotal + platformFee) * vatRate * 100) / 100;
        const total = subtotal + platformFee + vat;

        return new Response(
          JSON.stringify({
            action: 'quote_ready',
            warehouse_id: warehouseId,
            shelves,
            months,
            storage_type: storageType,
            breakdown: { subtotal, platformFee, vat, total },
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      case 'open_booking':
      case 'create_shipment':
      case 'add_product':
      case 'edit_price':
      case 'view_orders':
      case 'track_order':
      case 'view_inventory':
      case 'open_kyc':
      case 'open_wallet':
      case 'start_uae_pass':
        return new Response(
          JSON.stringify({
            action: 'navigate',
            target: action_type,
            user_id: user.id,
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

      default:
        return new Response(
          JSON.stringify({ error: `Unsupported or non-whitelisted AI action: ${action_type}` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
    }
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
