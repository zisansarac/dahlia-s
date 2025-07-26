import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:siparis_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditOrderPage extends StatefulWidget {
  final dynamic order;

  const EditOrderPage({super.key, required this.order});

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _customerNameController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _cargoController;
  late TextEditingController _trackingController;
  late String _status;

  final List<String> _statusOptions = [
    'Hazırlanıyor',
    'Kargoya Verildi',
    'Teslim Edildi',
  ];

  @override
  void initState() {
    super.initState();

    // Debug çıktısı
    print("Edit sayfası açıldı. Order içeriği: ${widget.order}");

    _productNameController = TextEditingController(
      text: widget.order['product_name']?.toString() ?? '',
    );

    _customerNameController = TextEditingController(
      text: widget.order['customer_name']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.order['price']?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.order['address']?.toString() ?? '',
    );
    _cargoController = TextEditingController(
      text: widget.order['cargo_company']?.toString() ?? '',
    );
    _trackingController = TextEditingController(
      text: widget.order['tracking_number']?.toString() ?? '',
    );

    final gelenDurum = widget.order['status']?.toString().toLowerCase() ?? '';
    final durumlarMap = {
      'hazırlanıyor': 'Hazırlanıyor',
      'kargoya verildi': 'Kargoya Verildi',
      'teslim edildi': 'Teslim Edildi',
    };

    _status = durumlarMap.containsKey(gelenDurum)
        ? durumlarMap[gelenDurum]!
        : _statusOptions.first;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _customerNameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cargoController.dispose();
    _trackingController.dispose();

    super.dispose();
  }

  Future<void> updateOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('${ApiConstants.orders}/update/${widget.order['id']}'),

      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_name': _productNameController.text.trim(),
        'customer_name': _customerNameController.text.trim(),

        'price': _priceController.text.trim(),
        'address': _addressController.text.trim(),
        'cargo_company': _cargoController.text.trim(),
        'tracking_number': _trackingController.text.trim(),
        'status': _status.trim(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş başarıyla güncellendi')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncelleme hatası: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Siparişi Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bu alan zorunlu'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Müşteri Adı'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bu alan zorunlu'
                    : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adres'),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(labelText: 'Kargo Firması'),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _trackingController,
                decoration: const InputDecoration(labelText: 'Takip Numarası'),
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Durum'),
                items: _statusOptions.map((durum) {
                  return DropdownMenuItem<String>(
                    value: durum,
                    child: Text(durum),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Durum seçmelisiniz'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    updateOrder();
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
