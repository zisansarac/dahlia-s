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

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Montserrat'),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB34700)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFB34700)),
        title: const Text(
          'Yeni Sipariş',
          style: TextStyle(
            color: Color(0xFFB34700),
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _customerName,
                decoration: buildInputDecoration('Müşteri Adı'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productName,
                decoration: buildInputDecoration('Ürün Adı'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                decoration: buildInputDecoration('Fiyat'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: buildInputDecoration('Adres'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cargoCompany,
                decoration: buildInputDecoration('Kargo Firması'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trackingNumber,
                decoration: buildInputDecoration('Takip No'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB34700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Siparişi Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
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
