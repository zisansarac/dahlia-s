import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddOrderPage extends StatefulWidget {
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
    final response = await http.post(
      Uri.parse('http://localhost:3000/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "customer_name": _customerName.text,
        "product_name": _productName.text,
        "price": double.tryParse(_price.text) ?? 0,
        "address": _address.text,
        "cargo_company": _cargoCompany.text,
        "tracking_number": _trackingNumber.text,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sipariş eklendi')));
      Navigator.pop(context, true); // geri dön ve listeyi yenile
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata oluştu')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Sipariş')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _customerName,
                decoration: InputDecoration(labelText: 'Müşteri Adı'),
              ),
              TextFormField(
                controller: _productName,
                decoration: InputDecoration(labelText: 'Ürün Adı'),
              ),
              TextFormField(
                controller: _price,
                decoration: InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _address,
                decoration: InputDecoration(labelText: 'Adres'),
              ),
              TextFormField(
                controller: _cargoCompany,
                decoration: InputDecoration(labelText: 'Kargo Firması'),
              ),
              TextFormField(
                controller: _trackingNumber,
                decoration: InputDecoration(labelText: 'Takip No'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitOrder,
                child: Text('Siparişi Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
