import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    // Check admin privilege
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    const isAdmin = ['super_admin', 'operations_admin'].includes(profile?.role ?? '');
    if (!isAdmin) {
      return new Response(JSON.stringify({ error: 'Unauthorized: Admin role required' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { application_id, action, rejection_reason } = await req.json();

    if (!application_id || !['approve', 'reject'].includes(action)) {
      return new Response(JSON.stringify({ error: 'Valid application_id and action required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: app, error: aErr } = await supabase
      .from('seller_applications')
      .select('*')
      .eq('id', application_id)
      .single();

    if (aErr || !app) throw new Error('Seller application not found');

    const newStatus = action === 'approve' ? 'approved' : 'rejected';

    // 1. Update application
    await supabase
      .from('seller_applications')
      .update({
        status: newStatus,
        reviewed_by: user.id,
        reviewed_at: new Date().toISOString(),
        rejection_reason: action === 'reject' ? rejection_reason : null,
      })
      .eq('id', application_id);

    // 2. If approved, approve the shop and verify the seller
    if (action === 'approve') {
      await supabase
        .from('marketplace_shops')
        .update({ is_approved: true })
        .eq('seller_id', app.user_id);

      await supabase
        .from('sme_sellers')
        .update({ is_verified: true })
        .eq('id', app.user_id);
    }

    // 3. Log audit event
    await supabase.from('audit_logs').insert({
      actor_id: user.id,
      action: `seller_application_${action}`,
      entity_type: 'seller_applications',
      entity_id: application_id,
      old_value: { status: app.status },
      new_value: { status: newStatus },
    });

    // 4. Notify merchant
    await supabase.from('notifications').insert({
      user_id: app.user_id,
      title: action === 'approve' ? 'Shop Approved! 🎉' : 'Shop Application Update',
      title_ar: action === 'approve' ? 'تمت الموافقة على متجرك! 🎉' : 'تحديث طلب المتجر',
      body: action === 'approve'
        ? 'Your seller application has been approved. You can now sell on NXN Marketplace.'
        : `Your application was not approved: ${rejection_reason ?? 'Please contact support.'}`,
      body_ar: action === 'approve'
        ? 'تمت الموافقة على متجرك. يمكنك الآن بيع منتجاتك عبر منصة NXN.'
        : `لم تتم الموافقة على طلبك: ${rejection_reason ?? 'يرجى التواصل مع الدعم.'}`,
      type: 'system',
      reference_type: 'seller_application',
      reference_id: application_id,
    });

    return new Response(JSON.stringify({ success: true, status: newStatus }), {
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
