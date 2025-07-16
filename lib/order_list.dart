import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderListPage extends StatefulWidget {
  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<dynamic> orders = [];
  String username = '';
  String _searchQuery = '';
  String _selectedStatus = 'Tümü';

  final List<String> validStatuses = [
    'hazırlanıyor',
    'kargoda',
    'teslim edildi',
  ];

  @override
  void initState() {
    super.initState();
    loadUsername();
    fetchOrders();
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  Future<void> fetchOrders() async {
    final response = await http.get(Uri.parse('http://localhost:3000/orders'));
    if (response.statusCode == 200) {
      setState(() {
        orders = json.decode(response.body);
      });
    } else {
      print('Siparişler alınamadı');
    }
  }

  Future<void> updateStatus(int id, String newStatus) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/orders/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': newStatus}),
    );
    if (response.statusCode == 200) {
      fetchOrders();
    } else {
      print('Durum güncellenemedi');
    }
  }

  Future<void> deleteOrder(int id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/orders/$id'),
    );
    if (response.statusCode == 200) {
      fetchOrders();
    } else {
      print('Sipariş silinemedi');
    }
  }

  List<dynamic> get filteredOrders {
    return orders.where((order) {
      final nameMatch = order['customer_name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery);
      final statusMatch =
          _selectedStatus == 'Tümü' ||
          order['status'].toString().toLowerCase() == _selectedStatus;
      return nameMatch && statusMatch;
    }).toList();
  }

  Widget buildOrderTile(dynamic order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(order['product_name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order['customer_name']}'),
            Text('Adres: ${order['address']}'),
            Row(
              children: [
                Text('Durum: '),
                DropdownButton<String>(
                  value:
                      validStatuses.contains(
                        order['status']?.toString().toLowerCase(),
                      )
                      ? order['status'].toString().toLowerCase()
                      : 'hazırlanıyor',
                  items: validStatuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      updateStatus(order['id'], newStatus);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${order['price']}₺'),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Emin misiniz?'),
                    content: Text('Bu siparişi silmek istiyor musunuz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteOrder(order['id']);
                        },
                        child: Text('Sil'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Siparişler - Hoşgeldin $username'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Kullanıcı bilgilerini temizle
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Müşteri adına göre ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              items: ['Tümü', ...validStatuses]
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return buildOrderTile(order);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddOrderPage()),
          );
          if (result == true) {
            fetchOrders();
          }
        },
      ),
    );
  }
}
