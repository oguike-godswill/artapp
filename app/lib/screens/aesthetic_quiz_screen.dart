import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets.dart';

class AestheticQuizScreen extends StatefulWidget {
  const AestheticQuizScreen({super.key});

  @override
  State<AestheticQuizScreen> createState() => _AestheticQuizScreenState();
}

class _AestheticQuizScreenState extends State<AestheticQuizScreen> {
  int _step = 0;
  final List<int> _answers = [];

  static const _questions = [
    (
      'What palette speaks to your space?',
      'Choose the tonal atmosphere that brings you peace.',
      [
        ('Warm Terracotta & Sun Ochre', 'Earthy, radiant, grounded with golden light.', Solis.sun),
        ('Deep Teal & Midnight Water', 'Serene, contemplative, calm like still water.', Solis.teal),
        ('Cobalt & Burnt Rust', 'Vibrant, dynamic, and full of historical rhythm.', Solis.rust),
      ]
    ),
    (
      'Which tactile medium draws you in?',
      'The texture you want to reach out and touch.',
      [
        ('Thick Oil Impasto', 'Heavy palette-knife textures and layered oil brushwork.', Solis.ink),
        ('Tactile Fiber & Woven Palm', 'Natural woven baskets and organic handcraft.', Solis.rust),
        ('Luminous Botanical Gouache', 'Velvety matte colors with smooth, intimate details.', Solis.teal),
      ]
    ),
    (
      'Where does your mind drift?',
      'The sanctuary you find yourself in.',
      [
        ('A solitary ferry on a warm river at dusk', 'Quiet reverie with giant fan palms.', Solis.sun),
        ('A quiet coastal courtyard with blooming hibiscus', 'Sea breezes and vibrant terracotta tiles.', Solis.teal),
        ('An intimate late-night whisper among friends', 'Patterned textiles and ancient secrets.', Solis.rust),
      ]
    ),
  ];

  static const _personas = [
    (
      'The Solar Earth & Folk Collector',
      'You are drawn to works of warmth, natural materials, and hand-spun narratives. Your presence grounds a room with terracotta, palm leaf, and sunlit ochre.',
      [Solis.sun, Solis.rust, Solis.paper],
      ['Fan Palm Crossing', 'Golden Hour Porch', 'Woven Crown']
    ),
    (
      'The Oceanic Contemplative',
      'You seek stillness, reflection, and quiet mastery. Your eye gravitates toward deep teals, lily pads, and the calm rhythm of moving water.',
      [Solis.teal, Color(0xFF1E3A8A), Solis.paper],
      ['Still Water, Koi', 'Blue Door Hibiscus', 'The Teal Garden']
    ),
    (
      'The Narrative & Textile Devotee',
      'You celebrate pattern, craft heritage, and shared human stories. Your world is rich with woven geometry, intimate portraiture, and bold contrast.',
      [Solis.rust, Solis.ink, Solis.sun],
      ['Whispers', 'Evening of Weaving', 'Baskets of Bolga']
    ),
  ];

  void _choose(int option) {
    HapticFeedback.lightImpact();
    _answers.add(option);
    if (_step < _questions.length - 1) {
      setState(() => _step++);
    } else {
      setState(() => _step = _questions.length); // Result state
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _step >= _questions.length;
    final persona = isDone ? _personas[_answers[0] % _personas.length] : null;

    return Scaffold(
      backgroundColor: Solis.paper,
      appBar: AppBar(
        backgroundColor: Solis.paper,
        elevation: 0,
        leading: CircleBtn(
          icon: Icons.close_rounded,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(isDone ? 'Your Aesthetic Match' : 'Aesthetic Quiz · ${_step + 1}/${_questions.length}',
            style: Solis.serif(18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
          child: isDone ? _buildResult(persona!) : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final (title, subtitle, options) = _questions[_step];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _questions.length,
            color: Solis.sun,
            backgroundColor: Solis.line,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 28),
        Text(title, style: Solis.serif(30)),
        const SizedBox(height: 6),
        Text(subtitle, style: Solis.sans(14, color: Solis.muted)),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final (label, desc, color) = options[i];
              return _QuizCard3D(
                label: label,
                desc: desc,
                accentColor: color,
                onTap: () => _choose(i),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResult((String, String, List<Color>, List<String>) persona) {
    final (name, bio, palette, works) = persona;

    return ListView(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: palette[0],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: palette[0].withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          textAlign: TextAlign.center,
          style: Solis.serif(32),
        ),
        const SizedBox(height: 12),
        Text(
          bio,
          textAlign: TextAlign.center,
          style: Solis.sans(14.5, color: Solis.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Solis.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Solis.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR SIGNATURE PALETTE', style: Solis.label()),
              const SizedBox(height: 12),
              Row(
                children: palette.map((c) {
                  return Expanded(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Solis.line),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('RECOMMENDED FOR YOUR EYE', style: Solis.label()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: works.map((w) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Solis.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Solis.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Solis.sun),
                  const SizedBox(width: 6),
                  Text(w, style: Solis.sans(13, weight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Apply to My Collection',
          onPressed: () {
            toast(context, '✓ Solis tailored to your aesthetic persona');
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _QuizCard3D extends StatefulWidget {
  const _QuizCard3D({required this.label, required this.desc, required this.accentColor, required this.onTap});
  final String label, desc;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_QuizCard3D> createState() => _QuizCard3DState();
}

class _QuizCard3DState extends State<_QuizCard3D> {
  double _tiltY = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: (d) => setState(() => _tiltY = (d.delta.dx * 0.005).clamp(-0.2, 0.2)),
      onPanEnd: (_) => setState(() => _tiltY = 0.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(_tiltY),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Solis.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Solis.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: Solis.serif(18)),
                    const SizedBox(height: 4),
                    Text(widget.desc, style: Solis.sans(12.5, color: Solis.muted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Solis.muted),
            ],
          ),
        ),
      ),
    );
  }
}
