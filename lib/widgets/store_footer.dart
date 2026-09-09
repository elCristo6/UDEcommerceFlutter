import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreFooter extends StatelessWidget {
  const StoreFooter({Key? key}) : super(key: key);

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: const Color(0xFF02060D),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: isDesktop ? 56 : 36,
      ),
      child: MaxWidthContainer(
        maxWidth: 1280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Marca y Ubicación Pulsante
                  Expanded(flex: 5, child: _buildBrandAndLocation()),
                  const SizedBox(width: 48),
                  // 2. Contacto Directo
                  Expanded(flex: 4, child: _buildContactInfo()),
                  const SizedBox(width: 48),
                  // 3. Redes y Medios de Pago
                  Expanded(flex: 4, child: _buildSocialAndPayments()),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandAndLocation(),
                  const SizedBox(height: 36),
                  _buildContactInfo(),
                  const SizedBox(height: 36),
                  _buildSocialAndPayments(),
                ],
              ),
            const SizedBox(height: 48),
            const Divider(color: Color(0xFF162235), height: 1),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '© 2026 UD Electronics. Bogotá, Colombia.',
                  style: TextStyle(
                    color: Color(0xFF6F7D91),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Robótica • Electrónica • Impresión 3D',
                  style: TextStyle(
                    color: const Color(0xFF168CFF).withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 1. MARCA Y UBICACIÓN CON EFECTO DE PULSO
  // ============================================================
  Widget _buildBrandAndLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58C2FF).withOpacity(.58),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/UDElectronics.com.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Colors.blue, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'UD ELECTRONICS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Tienda Especializada B2B y B2C',
                  style: TextStyle(
                    color: Color(0xFF168CFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Líderes en importación y distribución de componentes electrónicos, robótica e impresión 3D profesional.',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        PulseLinkButton(
          onTap: () => _launchURL('https://maps.google.com/?q=Carrera+9+%23+19-30+local+202+Bogota'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.location_on_outlined, color: Color(0xFF168CFF), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Carrera 9 # 19-30 Local 202',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Centro Comercial Parqueo Centro, Bogotá - Colombia',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new_rounded, color: Colors.white30, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 2. CONTACTO DIRECTO
  // ============================================================
  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ATENCIÓN Y VENTAS',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        HoverButton(
          onTap: () => _launchURL('https://wa.me/573208576038'),
          child: Row(
            children: [
              const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'WhatsApp Venta Directa',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '320 857 6038  •  321 321 3756',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        HoverButton(
          onTap: () => _launchURL('tel:6012105424'),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, color: Color(0xFF168CFF), size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Línea Fija Bogotá',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '(601) 210 5424',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFFCBD5E1), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Horario Presencial',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Lunes a Sábados: 9:00 AM - 5:30 PM',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 3. REDES SOCIALES Y MEDIOS DE PAGO
  // ============================================================
  Widget _buildSocialAndPayments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SÍGUENOS',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            _buildSleekSocialIcon('assets/facebook.png', 'https://www.facebook.com/udelectronics'),
            _buildSleekSocialIcon('assets/instagram.png', 'https://www.instagram.com/udelectronics/'),
            _buildSleekSocialIcon('assets/youtube.png', 'http://www.youtube.com/@udelectronicsbogota'),
            _buildSleekSocialIcon('assets/tiktok.png', 'https://www.tiktok.com/@udelectronics'),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'MEDIOS DE PAGO',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            _buildCleanPaymentLogo('assets/nequi.png', 'Nequi'),
            _buildCleanPaymentLogo('assets/bancolombia.png', 'Bancolombia'),
            _buildCleanPaymentLogo('assets/daviplata.png', 'Daviplata'),
            _buildCleanPaymentLogo('assets/bre.png', 'Efectivo/PSE'),
          ],
        ),
      ],
    );
  }

  Widget _buildSleekSocialIcon(String assetName, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SocialHoverButton(
        onTap: () => _launchURL(url),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Image.asset(
            assetName,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.share, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanPaymentLogo(String assetName, String label) {
    return Container(
      width: 56,
      height: 36,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        assetName,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS Y ANIMACIONES
// ============================================================

class MaxWidthContainer extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthContainer({
    Key? key,
    required this.maxWidth,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HoverButton({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.85,
          duration: const Duration(milliseconds: 180),
          child: widget.child,
        ),
      ),
    );
  }
}

class PulseLinkButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PulseLinkButton({super.key, required this.child, required this.onTap});

  @override
  State<PulseLinkButton> createState() => _PulseLinkButtonState();
}

class _PulseLinkButtonState extends State<PulseLinkButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class SocialHoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const SocialHoverButton({super.key, required this.child, required this.onTap});

  @override
  State<SocialHoverButton> createState() => _SocialHoverButtonState();
}

class _SocialHoverButtonState extends State<SocialHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF091220) : const Color(0xFF02060D),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isHovered ? const Color(0xFF168CFF).withOpacity(0.5) : const Color(0xFF1E293B),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: const Color(0xFF168CFF).withOpacity(0.2), blurRadius: 10, spreadRadius: 1)]
                : [],
          ),
          child: AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
