/*
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
*/


// whatsapp_logo_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

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
      duration: const Duration(seconds: 2),
    );
    _animation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween<Offset>(begin: Offset.zero, end: const Offset(0.04, 0)).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(0.04, 0)), weight: 2),
      TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
      TweenSequenceItem(tween: ConstantTween<Offset>(Offset.zero), weight: 2),
    ]).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();
    final String phoneNumber = "+573208576038";
    
    String message = "¡Hola UD Electronics! 👋 Estuve viendo su página web y me gustaría recibir más información sobre sus productos.";
    
    if (cartProvider.totalItems > 0 && cartProvider.cart != null) {
      final itemsBuffer = StringBuffer();
      itemsBuffer.writeln("¡Hola UD Electronics! Quisiera cotizar y coordinar el pago de los siguientes componentes en mi cesta:\n");
      
      for (var item in cartProvider.cart!.items) {
        itemsBuffer.writeln("• ${item.product.name} (Cant: ${item.quantity}) - P. Unit: \$${item.appliedPrice}");
      }
      
      itemsBuffer.writeln("\nTotal de Artículos: ${cartProvider.totalItems}");
      message = itemsBuffer.toString();
    }

    final Uri url = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir los canales de WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final hasItems = cartProvider.totalItems > 0;

    return Align(
      alignment: Alignment.bottomRight,
      child: SlideTransition(
        position: _animation,
        child: GestureDetector(
          onTap: () => _launchWhatsApp(context),
          child: Stack(
            clipBehavior: Clip.none, // ✅ CORREGIDO: Removido el carácter '幕'
            children: [
              Image.asset(
                'assets/WhatsApp.png',
                width: 82,
                height: 82,
                errorBuilder: (_, __, ___) => const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 30,
                  child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 30),
                ),
              ),
              if (hasItems)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      "${cartProvider.totalItems} Cotizar",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}