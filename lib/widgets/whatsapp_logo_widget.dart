import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLogoWidget extends StatefulWidget {
  const WhatsAppLogoWidget({Key? key}) : super(key: key);

  @override
  _WhatsAppLogoWidgetState createState() => _WhatsAppLogoWidgetState();
}

class _WhatsAppLogoWidgetState extends State<WhatsAppLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween<Offset>(
                  begin: const Offset(0, 0), end: const Offset(0.05, 0))
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
      TweenSequenceItem(
          tween: ConstantTween<Offset>(const Offset(0.05, 0)), weight: 2),
      TweenSequenceItem(
          tween: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: const Offset(0, 0))
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
      TweenSequenceItem(
          tween: ConstantTween<Offset>(const Offset(0, 0)), weight: 2),
    ]).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final String phoneNumber = "+573208576038";
    final String message =
        "Estoy en la pagina de UDElectronics.com y quiero hacerte una pregunta";
    final Uri url = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Posiciona el logo en la esquina superior derecha
    return Align(
      alignment: Alignment.bottomRight,
      child: SlideTransition(
        position: _animation,
        child: GestureDetector(
          onTap: _launchWhatsApp,
          child: Image.asset(
            'assets/WhatsApp.png',
            width: 90,
            height: 90,
          ),
        ),
      ),
    );
  }
}
