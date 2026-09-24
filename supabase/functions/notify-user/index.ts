import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    const {
      user_id,
      title_en,
      title_ar,
      body_en,
      body_ar,
      type = 'general',
      reference_type,
      reference_id,
      deep_link,
    } = await req.json();

    if (!user_id || !title_en || !body_en) {
      return new Response(JSON.stringify({ error: 'user_id, title_en, and body_en are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 1. Insert DB notification
    const { data: notif, error: nErr } = await supabase
      .from('notifications')
      .insert({
        user_id,
        title: title_en,
        title_ar: title_ar ?? title_en,
        body: body_en,
        body_ar: body_ar ?? body_en,
        type,
        reference_type,
        reference_id,
        deep_link,
        is_read: false,
      })
      .select()
      .single();

    if (nErr) throw new Error(nErr.message);

    // 2. Fetch active device tokens for push notification
    const { data: tokens } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', user_id);

    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');
    if (fcmServerKey && tokens && tokens.length > 0) {
      for (const t of tokens) {
        try {
          await fetch('https://fcm.googleapis.com/fcm/send', {
            method: 'POST',
            headers: {
              Authorization: `key=${fcmServerKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              to: t.token,
              notification: {
                title: title_en,
                body: body_en,
              },
              data: {
                reference_type: reference_type ?? '',
                reference_id: reference_id ?? '',
                deep_link: deep_link ?? '',
              },
            }),
          });
        } catch (e) {
          console.error('FCM dispatch error:', e);
        }
      }
    }

    return new Response(JSON.stringify({ success: true, notification_id: notif.id }), {
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
