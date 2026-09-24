import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAuthenticatedUser, getSupabaseServiceClient } from '../_shared/auth.ts';

Deno.serve(async (req: Request) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const user = await getAuthenticatedUser(req);
    const supabase = getSupabaseServiceClient();

    // Check KYC or super admin role
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    const isKycAdmin = ['super_admin', 'kyc_admin'].includes(profile?.role ?? '');
    if (!isKycAdmin) {
      return new Response(JSON.stringify({ error: 'Unauthorized: KYC Admin role required' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { submission_id, action, rejection_reason } = await req.json();

    if (!submission_id || !['approve', 'reject'].includes(action)) {
      return new Response(JSON.stringify({ error: 'Valid submission_id and action required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: submission, error: sErr } = await supabase
      .from('kyc_submissions')
      .select('*')
      .eq('id', submission_id)
      .single();

    if (sErr || !submission) throw new Error('KYC submission record not found');

    const newKycStatus = action === 'approve' ? 'verified' : 'rejected';

    // 1. Update kyc_submissions
    await supabase
      .from('kyc_submissions')
      .update({
        status: newKycStatus,
        reviewed_by: user.id,
        reviewed_at: new Date().toISOString(),
        rejection_reason: action === 'reject' ? rejection_reason : null,
      })
      .eq('id', submission_id);

    // 2. Update profiles & sme_sellers
    await supabase
      .from('profiles')
      .update({ kyc_status: newKycStatus })
      .eq('id', submission.user_id);

    if (action === 'approve') {
      await supabase
        .from('sme_sellers')
        .update({ is_verified: true })
        .eq('id', submission.user_id);
    }

    // 3. Log audit event
    await supabase.from('audit_logs').insert({
      actor_id: user.id,
      action: `kyc_${action}`,
      entity_type: 'kyc_submissions',
      entity_id: submission_id,
      old_value: { status: submission.status },
      new_value: { status: newKycStatus },
    });

    // 4. Notify user
    await supabase.from('notifications').insert({
      user_id: submission.user_id,
      title: action === 'approve' ? 'KYC Verified ✅' : 'KYC Verification Update',
      title_ar: action === 'approve' ? 'تم توثيق الهوية والترخيص ✅' : 'تحديث التحقق من الهوية',
      body: action === 'approve'
        ? 'Your business and identification documents have been verified successfully.'
        : `KYC could not be verified: ${rejection_reason ?? 'Please resubmit valid documents.'}`,
      body_ar: action === 'approve'
        ? 'تم التحقق من بيانات الهوية والترخيص التجاري بنجاح.'
        : `لم يتم قبول الوثائق: ${rejection_reason ?? 'يرجى إعادة إرسال وثائق سارية.'}`,
      type: 'system',
      reference_type: 'kyc',
      reference_id: submission_id,
      deep_link: '/profile/kyc',
    });

    return new Response(JSON.stringify({ success: true, kyc_status: newKycStatus }), {
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
