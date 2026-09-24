import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const { booking_id } = await req.json();
    if (!booking_id) {
      return new Response(JSON.stringify({ error: 'booking_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify booking belongs to user
    const { data: booking, error: bErr } = await supabase
      .from('sme_subscriptions')
      .select('*')
      .eq('id', booking_id)
      .eq('seller_id', user.id)
      .single();

    if (bErr || !booking) {
      throw new Error('Booking subscription not found');
    }

    // Activate subscription
    const { error: uErr } = await supabase
      .from('sme_subscriptions')
      .update({ is_active: true })
      .eq('id', booking_id);

    if (uErr) throw new Error(uErr.message);

    return new Response(JSON.stringify({ success: true, booking_id }), {
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
