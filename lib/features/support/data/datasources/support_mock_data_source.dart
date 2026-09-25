import '../../../../core/mock/mock_database.dart';
import '../../domain/entities/assistant_reply.dart';
import '../../domain/entities/faq_entry.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_request.dart';
import 'support_remote_data_source.dart';

/// Stand-in for the support backend. The real assistant will answer from the
/// order and invoice it is given; this one matches keywords against the same
/// FAQ the customer has already seen, which is enough to demo the ladder
/// FAQ → assistant → person.
class SupportMockDataSource implements SupportRemoteDataSource {
  SupportMockDataSource(this._db);

  static const table = 'support_requests';

  final MockDatabase _db;
  var _requestSeq = 1040;

  static const _faqs = [
    (
      id: 'price-after-inspection',
      question: {
        'ar': 'لماذا لم يظهر السعر عند الحجز؟',
        'en': 'Why wasn\'t the price shown when I booked?',
      },
      answer: {
        'ar':
            'يُحدَّد السعر بعد أن تفحص المغسلة القطع وتعدّها، لذلك تعكس '
            'الفاتورة ما استُلم فعلًا وليس تقديرًا.',
        'en':
            'The price is set once the laundry has inspected and counted your '
            'items, so the invoice reflects what was actually received rather '
            'than an estimate.',
      },
      keywords: ['price', 'cost', 'expensive', 'much', 'سعر', 'غالي', 'تكلفة'],
    ),
    (
      id: 'item-count',
      question: {'ar': 'كيف تم عدّ القطع؟', 'en': 'How were my items counted?'},
      answer: {
        'ar':
            'تعدّ المغسلة كل قطعة وتفرزها عند وصولها، وتعرض الفاتورة نوع '
            'كل قطعة وعددها وسعر الوحدة.',
        'en':
            'The laundry counts and sorts every piece when it arrives. The '
            'invoice lists each item type with its quantity and unit price.',
      },
      keywords: ['count', 'number', 'missing', 'quantity', 'عدد', 'ناقص', 'كم'],
    ),
    (
      id: 'stains-damage',
      question: {
        'ar': 'لماذا تم إبلاغي ببقع أو تلف؟',
        'en': 'Why was I told about stains or damage?',
      },
      answer: {
        'ar':
            'بعد الفرز وقبل بدء التنظيف، تسجّل المغسلة أي بقع أو تلف موجود '
            'مسبقًا حتى تعرف حالة القطعة قبل معالجتها. تجد التفاصيل في تقرير '
            'الحالة على الفاتورة.',
        'en':
            'After sorting and before cleaning starts, the laundry records any '
            'stains or existing damage so you know an item\'s condition before '
            'it is treated. The details are in the condition report on your '
            'invoice.',
      },
      keywords: [
        'stain',
        'damage',
        'torn',
        'hole',
        'بقع',
        'بقعة',
        'تلف',
        'مقطوع',
      ],
    ),
    (
      id: 'payment-options',
      question: {'ar': 'كيف يمكنني الدفع؟', 'en': 'How can I pay?'},
      answer: {
        'ar': 'يمكنك الدفع بالبطاقة البنكية الآن، أو نقدًا للسائق عند التسليم.',
        'en': 'By bank card now, or in cash to the driver on delivery.',
      },
      keywords: ['pay', 'card', 'cash', 'دفع', 'بطاقة', 'كاش', 'نقد'],
    ),
  ];

  @override
  Future<List<FaqEntry>> getInvoiceFaqs() async {
    await _db.delay();
    _db.requireUserId();
    return [
      for (final faq in _faqs)
        FaqEntry(
          id: faq.id,
          question: _db.tr(faq.question),
          answer: _db.tr(faq.answer),
        ),
    ];
  }

  @override
  Future<AssistantReply> askAssistant(String orderId, String question) async {
    await _db.delay();
    _db.requireUserId();
    final text = question.toLowerCase();
    for (final faq in _faqs) {
      if (faq.keywords.any(text.contains)) {
        return AssistantReply(text: _db.tr(faq.answer), understood: true);
      }
    }
    return AssistantReply(
      text: _db.tr({
        'ar': 'لم أتمكن من فهم سؤالك بالكامل.',
        'en': 'I couldn\'t quite work out what you\'re asking.',
      }),
      understood: false,
    );
  }

  @override
  Future<SupportRequest> requestAgent(
    String orderId,
    List<SupportMessage> transcript,
  ) async {
    await _db.delay();
    final userId = _db.requireUserId();
    final number = ++_requestSeq;
    final row = {
      'id': 'sup-$number',
      'reference': 'S-$number',
      'userId': userId,
      'orderId': orderId,
      'topic': 'invoice',
      'transcript': transcript,
    };
    _db.table(table).add(row);
    return SupportRequest(
      id: row['id']! as String,
      reference: row['reference']! as String,
    );
  }
}
