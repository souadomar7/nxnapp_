import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getSupabaseServiceClient } from '../_shared/auth.ts';

async function verifyStripeSignature(
  payload: string,
  sigHeader: string,
  secret: string
): Promise<boolean> {
  try {
    const parts = sigHeader.split(',');
    const timestamp = parts.find((p) => p.startsWith('t='))?.split('=')[1];
    const signature = parts.find((p) => p.startsWith('v1='))?.split('=')[1];
    if (!timestamp || !signature) return false;

    const signedPayload = `${timestamp}.${payload}`;
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    const sig = await crypto.subtle.sign('HMAC', key, encoder.encode(signedPayload));
    const computed = Array.from(new Uint8Array(sig))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
    return computed === signature;
  } catch {
    return false;
  }
}

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const sigHeader = req.headers.get('stripe-signature');
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');

  const rawBody = await req.text();

  if (sigHeader && webhookSecret) {
    const isValid = await verifyStripeSignature(rawBody, sigHeader, webhookSecret);
    if (!isValid) {
      return new Response(JSON.stringify({ error: 'Invalid Stripe signature' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  }

  try {
    const event = JSON.parse(rawBody);
    const supabase = getSupabaseServiceClient();

    if (event.type === 'payment_intent.succeeded') {
      const pi = event.data.object;
      const paymentIntentId = pi.id;

      // 1. Update payments table
      const { data: payment, error: pErr } = await supabase
        .from('payments')
        .update({
          status: 'paid',
          paid_at: new Date().toISOString(),
          stripe_charge_id: pi.latest_charge ?? null,
        })
        .eq('stripe_payment_intent_id', paymentIntentId)
        .select()
        .single();

      if (!pErr && payment) {
        // 2. Handle reference-specific activation
        if (payment.reference_type === 'booking') {
          // Activate subscription
          await supabase
            .from('sme_subscriptions')
            .update({ is_active: true })
            .eq('id', payment.reference_id);

          // Create invoice record
          await supabase.from('sme_invoices').insert({
            id: `INV-${Date.now()}`,
            seller_id: payment.payer_id,
            invoice_number: `INV-${Date.now().toString().slice(-6)}`,
            warehouse_name: 'NXN Prime Warehouse',
            amount: payment.subtotal_aed,
            vat: payment.vat_aed,
            worker_fee: 0,
            paid: true,
            type: 'rental',
            stripe_payment_id: paymentIntentId,
          });

          // Insert dashboard activity
          await supabase.from('dashboard_activities').insert({
            id: `ACT-${Date.now()}`,
            seller_id: payment.payer_id,
            title: 'Shelf Rental Confirmed',
            subtitle: `Paid AED ${payment.amount_aed}`,
            type: 'rental',
          });

          // Create in-app notification
          await supabase.from('notifications').insert({
            user_id: payment.payer_id,
            title: 'Booking Confirmed',
            title_ar: 'تم تأكيد حجز الرفوف',
            body: `Your payment of AED ${payment.amount_aed} has been confirmed. Your shelf space is ready.`,
            body_ar: `تم استلام دفعتك بمبلغ ${payment.amount_aed} درهم بنجاح. مساحتك جاهزة.`,
            type: 'payment',
            reference_type: 'booking',
            reference_id: payment.reference_id,
            deep_link: '/profile/subscriptions',
          });
        } else if (payment.reference_type === 'wallet_topup') {
          // Credit wallet
          const { data: wallet } = await supabase
            .from('wallets')
            .select('id, balance_aed')
            .eq('user_id', payment.payer_id)
            .single();

          if (wallet) {
            await supabase.from('wallet_transactions').insert({
              wallet_id: wallet.id,
              type: 'top_up',
              amount_aed: payment.amount_aed,
              direction: 'credit',
              reference_type: 'payment',
              reference_id: payment.id,
              status: 'completed',
              notes: 'Stripe wallet top-up',
            });

            await supabase
              .from('wallets')
              .update({
                balance_aed: parseFloat(wallet.balance_aed.toString()) + payment.amount_aed,
                updated_at: new Date().toISOString(),
              })
              .eq('id', wallet.id);
          }
        }
      }
    } else if (event.type === 'payment_intent.payment_failed') {
      const pi = event.data.object;
      await supabase
        .from('payments')
        .update({ status: 'failed' })
        .eq('stripe_payment_intent_id', pi.id);
    }

    return new Response(JSON.stringify({ received: true }), {
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
