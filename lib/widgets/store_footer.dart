// store_footer.dart
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
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Container(
      color: const Color(0xFF02060D),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 22,
        vertical: isDesktop ? 42 : 32,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 34 : 22,
          vertical: isDesktop ? 34 : 26,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF07111F).withOpacity(.94),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF008CFF).withOpacity(.10),
              blurRadius: 28,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildCompanyBrandInfo()),
                  const SizedBox(width: 40),
                  Expanded(flex: 2, child: _buildCatalogLinks(context)),
                  Expanded(flex: 2, child: _buildHelpLinks(context)),
                  Expanded(flex: 3, child: _buildSocialArea()),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyBrandInfo(),
                  const _FooterDivider(),
                  _buildCatalogLinks(context),
                  const _FooterDivider(),
                  _buildHelpLinks(context),
                  const _FooterDivider(),
                  _buildSocialArea(),
                ],
              ),
            const SizedBox(height: 30),
            const Divider(color: Color(0xFF253449)),
            const SizedBox(height: 14),
            const Text(
              '© 2026 UD Electronics. Bogotá, Colombia.',
              style: TextStyle(
                color: Color(0xFF6F7D91),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyBrandInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 68,
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
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UD ELECTRONICS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Robótica, Electrónica e Impresión 3D profesional.',
                style: TextStyle(
                  color: Color(0xFFB8C2D4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              HoverButton(
                onTap: () => _launchURL('https://maps.app.goo.gl/P23tsnHtXa6WHwd68'),
                child: _footerTextRow(
                  Icons.location_on_outlined,
                  'Carrera 9 # 19-30 local 202, Bogotá',
                ),
              ),
_footerTextRow(Icons.access_time, 'Lunes - Sábados: 9:00 AM - 5:30 PM'),
_footerTextRow(Icons.phone_outlined, 'Teléfono: (601) 2105424'),
_footerTextRow(Icons.chat_outlined, 'WhatsApp: 321 321 3756 - 320 857 6038'),
_footerTextRow(Icons.mail_outline, 'udelectronicsbogota@gmail.com'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogLinks(BuildContext context) {
    return _footerColumn(
      title: 'CATÁLOGO',
      children: [
        _footerLink('Ofertas', () {}),
        _footerLink('Novedades', () {}),
        _footerLink('Robótica', () {}),
        _footerLink('Kits educativos', () {}),
        _footerLink('Impresión 3D', () {}),
      ],
    );
  }

  Widget _buildHelpLinks(BuildContext context) {
    return _footerColumn(
      title: 'AYUDA',
      children: [
        _footerLink('Sobre nosotros', () {}),
        _footerLink('Garantías', () {}),
        _footerLink('Envíos', () {}),
        _footerLink('Políticas', () {}),
        _footerLink('Contacto', () {}),
      ],
    );
  }

  Widget _buildSocialArea() {
    return _footerColumn(
      title: 'CONÉCTATE',
      children: [
        Row(
          children: [
            HoverButton(
              child: _socialIcon('assets/facebook.png'),
              onTap: () => _launchURL('https://www.facebook.com/udelectronics'),
            ),
            HoverButton(
              child: _socialIcon('assets/instagram.png'),
              onTap: () => _launchURL('https://www.instagram.com/udelectronics/'),
            ),
            HoverButton(
              child: _socialIcon('assets/youtube.png'),
              onTap: () => _launchURL('http://www.youtube.com/@udelectronicsbogota'),
            ),
            HoverButton(
              child: _socialIcon('assets/tiktok.png'),
              onTap: () => _launchURL('https://www.tiktok.com/@udelectronics'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'MEDIOS DE PAGO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _paymentIcon('assets/nequi.png'),
            _paymentIcon('assets/bancolombia.png'),
            _paymentIcon('assets/daviplata.png'),
            _paymentIcon('assets/bre.png'),
          ],
        ),
      ],
    );
  }

  Widget _footerColumn({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }

  Widget _footerTextRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF168CFF), size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB8C2D4),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: HoverButton(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFB8C2D4),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(String assetName) {
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1B3248),
          width: 1,
        ),
      ),
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: Image.asset(assetName, fit: BoxFit.contain),
      ),
    );
  }

  Widget _paymentIcon(String assetName) {
    return Container(
      width: 48,
      height: 30,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF050A13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1B3248),
          width: 1,
        ),
      ),
      child: Image.asset(assetName, fit: BoxFit.contain),
    );
  }
}

class _FooterDivider extends StatelessWidget {
  const _FooterDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFF253449),
      height: 36,
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
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.06 : 1,
          duration: const Duration(milliseconds: 160),
          child: AnimatedOpacity(
            opacity: _isHovered ? 1 : .88,
            duration: const Duration(milliseconds: 160),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}