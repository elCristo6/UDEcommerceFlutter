import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../models/user_model.dart';
import 'loan_cart_screen.dart';

class ClientSelectionScreen extends StatefulWidget {
  const ClientSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ClientSelectionScreen> createState() => _ClientSelectionScreenState();
}

class _ClientSelectionScreenState extends State<ClientSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  void _searchClient() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    // Reutilizas tu fetchUserByPhone del InvoiceProvider
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final User? client = await invoiceProvider.fetchUserByPhone(query);
    setState(() => _isLoading = false);

    if (client != null && mounted) {
      // Pasamos el cliente seleccionado a la Cesta de Préstamo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoanCartScreen(selectedClient: client)),
      );
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente no encontrado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Préstamo a:')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Buscar por teléfono del Local/Store',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchClient,
                ),
              ),
              onSubmitted: (_) => _searchClient(),
            ),
            if (_isLoading) const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            )
          ],
        ),
      ),
    );
  }
}