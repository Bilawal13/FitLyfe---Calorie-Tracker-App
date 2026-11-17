import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_provider.dart';
import '../services/sound_service.dart';
import '../services/language_provider.dart';

class FeedbackScreen extends StatefulWidget {
  final AppColors c;
  const FeedbackScreen({super.key, required this.c});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback(LanguageProvider lang) async {
    SoundService.playTap();
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isUrdu
              ? 'برائے مہربانی رائے جمع کرانے سے پہلے کچھ لکھیں۔'
              : (lang.isArabic
                  ? 'يرجى كتابة ملاحظاتك قبل الإرسال.'
                  : 'Please enter your feedback before submitting.')),
          backgroundColor: widget.c.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Insert feedback directly into Supabase table named 'feedback'
      await Supabase.instance.client.from('feedback').insert({
        'message': text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isUrdu
              ? 'شکریہ! آپ کی رائے موصول ہو گئی ہے۔'
              : (lang.isArabic
                  ? 'شكراً لك! تم استلام ملاحظاتك بنجاح.'
                  : 'Thank you! Your feedback has been received.')),
          backgroundColor: widget.c.accent,
        ),
      );
      _feedbackController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isUrdu
              ? 'رائے نہیں بھیجی جا سکی۔ برائے مہربانی انٹرنیٹ چیک کریں۔'
              : (lang.isArabic
                  ? 'تعذر إرسال الملاحظات. يرجى التحقق من اتصالك والمحاولة مجدداً.'
                  : 'Couldn\'t send feedback. Please check your connection and try again.')),
          backgroundColor: widget.c.danger,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final lang = context.watch<LanguageProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(lang.t('feedback_title'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.accent.withValues(alpha: 0.15),
                  c.accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_rounded, size: 48, color: c.accent),
                const SizedBox(height: 12),
                Text(
                  lang.t('feedback_subtitle'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.isUrdu
                      ? 'کوئی مسئلہ ملا یا کوئی تجویز ہے؟ ہم آپ کی رائے کا خیرمقدم کرتے ہیں۔'
                      : (lang.isArabic
                          ? 'هل واجهت مشكلة أو لديك اقتراح؟ يسعدنا دائماً الاستماع إليك.'
                          : 'Found a bug or have a suggestion? We would love to hear from you.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _feedbackController,
            maxLines: 6,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: lang.t('feedback_hint'),
              hintStyle: TextStyle(color: c.textMuted),
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitFeedback(lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(lang.t('submit_feedback'),
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
