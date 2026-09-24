import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const body = await req.json();
    const { reference_type, reference_id, idempotency_key } = body;

    if (!reference_type || !reference_id) {
      return new Response(
        JSON.stringify({ error: 'reference_type and reference_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check idempotency if key provided
    if (idempotency_key) {
      const { data: existing } = await supabase
        .from('payments')
        .select('*')
        .eq('idempotency_key', idempotency_key)
        .maybeSingle();

      if (existing && existing.stripe_payment_intent_id) {
        const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;
        const piRes = await fetch(
          `https://api.stripe.com/v1/payment_intents/${existing.stripe_payment_intent_id}`,
          { headers: { Authorization: `Bearer ${stripeKey}` } }
        );
        const pi = await piRes.json();
        return new Response(
          JSON.stringify({
            clientSecret: pi.client_secret,
            paymentId: existing.id,
            breakdown: {
              subtotal: existing.subtotal_aed,
              platformFee: existing.platform_fee_aed,
              vat: existing.vat_aed,
              total: existing.amount_aed,
            },
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Fetch platform configuration (dynamic rates)
    const { data: settings } = await supabase.from('platform_settings').select('key, value');
    const settingsMap: Record<string, string> = {};
    for (const s of settings ?? []) settingsMap[s.key] = s.value;

    const vatRate = parseFloat(settingsMap['vat_rate'] ?? '0.05');
    const platformFeeRate = parseFloat(settingsMap['platform_fee_rate'] ?? '0.05');
    const shelfBasePrice = parseFloat(settingsMap['shelf_base_price_aed'] ?? '100');
    const workerFeeRate = parseFloat(settingsMap['worker_fee_per_unit_aed'] ?? '50');

    let subtotal = 0;

    if (reference_type === 'booking') {
      const { data: booking, error: bError } = await supabase
        .from('sme_subscriptions')
        .select('*')
        .eq('id', reference_id)
        .eq('seller_id', user.id)
        .single();
      if (bError || !booking) throw new Error('Booking subscription record not found');

      const storageType = booking.storage_type ?? 'ambient';
      const multiplier = storageType === 'cold_storage' ? 1.5 : storageType === 'chilled' ? 1.3 : 1.0;
      const months = booking.months ?? 1;
      const shelves = booking.shelves_count ?? 1;
      const workers = booking.add_workers ? (booking.worker_count ?? 0) : 0;
      subtotal = shelfBasePrice * shelves * months * multiplier + workers * workerFeeRate * months;
    } else if (reference_type === 'invoice') {
      const { data: invoice, error: iError } = await supabase
        .from('sme_invoices')
        .select('*')
        .eq('id', reference_id)
        .eq('seller_id', user.id)
        .single();
      if (iError || !invoice) throw new Error('Invoice record not found');
      subtotal = parseFloat(invoice.amount ?? '0');
    } else if (reference_type === 'marketplace_order' || reference_type === 'order') {
      const { data: order, error: oError } = await supabase
        .from('buyer_orders')
        .select('*')
        .eq('id', reference_id)
        .single();
      if (oError || !order) throw new Error('Marketplace order record not found');
      subtotal = parseFloat(order.total_amount ?? ((order.unit_price ?? 0) * (order.quantity ?? 1)).toString());
    } else {
      throw new Error(`Unsupported reference_type: ${reference_type}`);
    }

    const platformFeeAed = Math.round(subtotal * platformFeeRate * 100) / 100;
    const vatAed = Math.round((subtotal + platformFeeAed) * vatRate * 100) / 100;
    const totalAed = subtotal + platformFeeAed + vatAed;
    const amountFils = Math.round(totalAed * 100);

    // Call Stripe to create PaymentIntent
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;
    const stripeBody = new URLSearchParams({
      amount: amountFils.toString(),
      currency: 'aed',
      'metadata[reference_type]': reference_type,
      'metadata[reference_id]': reference_id,
      'metadata[user_id]': user.id,
    });
    if (idempotency_key) stripeBody.set('metadata[idempotency_key]', idempotency_key);

    const stripeRes = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        ...(idempotency_key ? { 'Idempotency-Key': idempotency_key } : {}),
      },
      body: stripeBody,
    });

    const pi = await stripeRes.json();
    if (!pi.client_secret) {
      throw new Error(`Stripe error: ${pi.error?.message ?? 'PaymentIntent creation failed'}`);
    }

    // Insert pending payment record
    const { data: payment, error: pError } = await supabase
      .from('payments')
      .insert({
        payer_id: user.id,
        reference_type,
        reference_id,
        stripe_payment_intent_id: pi.id,
        amount_aed: totalAed,
        subtotal_aed: subtotal,
        platform_fee_aed: platformFeeAed,
        vat_aed: vatAed,
        currency: 'AED',
        status: 'pending',
        idempotency_key: idempotency_key ?? null,
      })
      .select()
      .single();

    if (pError) throw new Error(`Database error saving payment: ${pError.message}`);

    return new Response(
      JSON.stringify({
        clientSecret: pi.client_secret,
        paymentId: payment.id,
        breakdown: {
          subtotal,
          platformFee: platformFeeAed,
          vat: vatAed,
          total: totalAed,
        },
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
