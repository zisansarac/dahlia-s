import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siparis_app/constants.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  _AddOrderPageState createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _productName = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _cargoCompany = TextEditingController();
  final TextEditingController _trackingNumber = TextEditingController();

  Future<void> submitOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse(ApiConstants.orders),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        "customer_name": _customerName.text,
        "product_name": _productName.text,
        "price": double.tryParse(_price.text) ?? 0,
        "address": _address.text,
        "cargo_company": _cargoCompany.text,
        "tracking_number": _trackingNumber.text,
        "date": date,
        "time": time,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sipariş eklendi')));
      Navigator.pop(context, true);
    } else {
      print(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hata oluştu')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sipariş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _customerName,
                decoration: const InputDecoration(labelText: 'Müşteri Adı'),
              ),
              TextFormField(
                controller: _productName,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
              ),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Adres'),
              ),
              TextFormField(
                controller: _cargoCompany,
                decoration: const InputDecoration(labelText: 'Kargo Firması'),
              ),
              TextFormField(
                controller: _trackingNumber,
                decoration: const InputDecoration(labelText: 'Takip No'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitOrder,
                child: const Text('Siparişi Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
