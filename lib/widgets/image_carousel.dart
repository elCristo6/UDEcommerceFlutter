import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'assets/7.png',
    'assets/6.png',
    'assets/2.png',
    'assets/3.png',
    'assets/4.png',
  ];

  @override
  void initState() {
    super.initState();
    // Configura el cambio automático de imágenes
    Future.delayed(const Duration(seconds: 10), _autoChange);
  }

  void _autoChange() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPage = (_currentPage + 1) % _images.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(seconds: 10), _autoChange);
    }
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPage = (_currentPage + 1) % _images.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPage = (_currentPage - 1 + _images.length) % _images.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.3, // Altura del carrusel
          width: screenWidth, // Ancho completo
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    _images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                },
              ),
              // Flechas de navegación
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _prevPage,
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: _nextPage,
                ),
              ),
              // Indicadores (dots)
              Positioned(
                bottom: 10, // Posiciona los puntos dentro de la imagen
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 12 : 8,
                      height: _currentPage == index ? 12 : 8,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index ? Colors.blue : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
