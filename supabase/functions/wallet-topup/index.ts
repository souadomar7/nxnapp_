import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const { amount_aed, idempotency_key } = await req.json();
    const amount = parseFloat(amount_aed);

    if (isNaN(amount) || amount <= 0) {
      return new Response(JSON.stringify({ error: 'Valid amount_aed is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check withdrawal / topup settings
    const { data: settings } = await supabase
      .from('platform_settings')
      .select('key, value')
      .eq('key', 'max_wallet_withdrawal_aed')
      .single();

    const maxThreshold = parseFloat(settings?.value ?? '50000');
    if (amount > maxThreshold) {
      throw new Error(`Amount exceeds maximum threshold of AED ${maxThreshold}`);
    }

    // Ensure wallet exists
    let { data: wallet } = await supabase
      .from('wallets')
      .select('*')
      .eq('user_id', user.id)
      .maybeSingle();

    if (!wallet) {
      const { data: newWallet, error: wErr } = await supabase
        .from('wallets')
        .insert({ user_id: user.id, currency: 'AED', balance_aed: 0.0 })
        .select()
        .single();
      if (wErr) throw new Error(wErr.message);
      wallet = newWallet;
    }

    // Create Stripe PaymentIntent for wallet top-up
    const amountFils = Math.round(amount * 100);
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;
    const stripeBody = new URLSearchParams({
      amount: amountFils.toString(),
      currency: 'aed',
      'metadata[reference_type]': 'wallet_topup',
      'metadata[reference_id]': wallet.id,
      'metadata[user_id]': user.id,
    });
    if (idempotency_key) stripeBody.set('metadata[idempotency_key]', idempotency_key);

    const stripeRes = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: stripeBody,
    });

    const pi = await stripeRes.json();
    if (!pi.client_secret) {
      throw new Error(`Stripe error: ${pi.error?.message ?? 'Failed to initiate wallet topup'}`);
    }

    // Create pending payment record
    await supabase.from('payments').insert({
      payer_id: user.id,
      reference_type: 'wallet_topup',
      reference_id: wallet.id,
      stripe_payment_intent_id: pi.id,
      amount_aed: amount,
      subtotal_aed: amount,
      platform_fee_aed: 0,
      vat_aed: 0,
      currency: 'AED',
      status: 'pending',
      idempotency_key: idempotency_key ?? null,
    });

    return new Response(
      JSON.stringify({
        clientSecret: pi.client_secret,
        walletId: wallet.id,
        amount_aed: amount,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
