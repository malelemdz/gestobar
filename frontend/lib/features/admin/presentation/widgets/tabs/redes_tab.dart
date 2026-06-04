import 'package:flutter/material.dart';
import '../config_bento_card.dart';
import '../config_text_field.dart';

class RedesTab extends StatelessWidget {
  final TextEditingController facebookCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController tiktokCtrl;

  const RedesTab({
    super.key,
    required this.facebookCtrl,
    required this.instagramCtrl,
    required this.tiktokCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ConfigBentoCard(
            title: 'Redes Sociales',
            description: 'Añade los enlaces de tus redes para compartirlos con tus clientes.',
            icon: Icons.link_rounded,
            child: Column(
              children: [
                ConfigTextField(
                  label: 'Facebook',
                  controller: facebookCtrl,
                  hintText: 'https://facebook.com/lounge...',
                  prefixIcon: Icons.facebook,
                ),
                const SizedBox(height: 12),
                ConfigTextField(
                  label: 'Instagram',
                  controller: instagramCtrl,
                  hintText: 'https://instagram.com/lounge...',
                  prefixIcon: Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 12),
                ConfigTextField(
                  label: 'TikTok',
                  controller: tiktokCtrl,
                  hintText: 'https://tiktok.com/@lounge...',
                  prefixIcon: Icons.music_note,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
