import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siparis_app/constants.dart';
import 'package:siparis_app/edit_order_page.dart';
import 'add_order.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  bool isFemaleEntrepreneur = false;

  List<dynamic> orders = [];
  String username = '';
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tab!
    checkLoginStatus();
    loadUsername();
    loadUserInfo();
    fetchOrders();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
      isFemaleEntrepreneur = prefs.getBool('is_female_entrepreneur') ?? false;
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  Future<void> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(ApiConstants.orders),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        orders = json.decode(response.body);
      });
    } else {
      print('Siparişleri alma başarısız: ${response.body}');
    }
  }

  Future<void> confirmDeleteOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi Sil'),
        content: const Text('Bu siparişi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteOrder(orderId);
    }
  }

  Future<void> deleteOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${ApiConstants.orders}/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sipariş silindi')));
      fetchOrders(); // Listeyi yenile
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: ${response.body}')));
    }
  }

  List<dynamic> get filteredOrders {
    final selectedTab = _tabController.index;
    final now = DateTime.now();

    return orders.where((order) {
      final createdAt = order['created_at'];
      final createdDate = DateTime.tryParse(createdAt ?? '');
      if (createdDate == null) return false;

      final difference = now.difference(createdDate).inDays;
      final isToday = difference < 2;
      final isOld = difference >= 2;

      final nameMatch = order['customer_name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery);

      if (selectedTab == 0) return isToday && nameMatch; // Bugün
      if (selectedTab == 1) return isOld && nameMatch; // Bekleyen
      return nameMatch; // Tümü (index 2)
    }).toList();
  }

  Color getStatusColor(String? status) {
    final lower = status?.toLowerCase() ?? '';
    switch (lower) {
      case 'hazırlanıyor':
        return Colors.orange;
      case 'kargoya verildi':
        return Colors.blue;
      case 'teslim edildi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget buildOrderCard(dynamic order) {
    final createdAt = order['created_at'] ?? '';
    final dateTime = DateTime.tryParse(createdAt);
    final formattedDate = dateTime != null
        ? '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}'
        : 'Tarih yok';
    final formattedTime = dateTime != null
        ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
        : 'Saat yok';

    final status = order['status'] ?? 'Durum yok';
    final statusColor = getStatusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: Ürün adı + Düzenle + Sil
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order['product_name'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Color.fromARGB(255, 243, 128, 33),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditOrderPage(order: order),
                      ),
                    );
                    if (result == true) fetchOrders();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDeleteOrder(order['id']),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Müşteri adı ve durum
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['customer_name'] ?? 'Müşteri bilgisi yok'),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tarih ve saat bilgisi
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(formattedDate),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text(formattedTime),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int get todayOrderCount {
    final now = DateTime.now();
    return orders.where((order) {
      final createdAt = order['created_at'];
      final createdDate = DateTime.tryParse(createdAt ?? '');
      if (createdDate == null) return false;
      return now.difference(createdDate).inDays < 2;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFB34700)),
              child: Text(
                'Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Siparişlerim'),
              onTap: () {
                Navigator.pop(context); // Menüyü kapat
              },
            ),
            if (isFemaleEntrepreneur)
              ListTile(
                leading: const Icon(Icons.woman),
                title: const Text('Kadın Girişimcilere Özel'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/women_in_science');
                },
              ),
            if (isFemaleEntrepreneur)
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Kadın Girişimci Haritası'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, 'api/women-map');
                },
              ),

            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Topluluk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, 'api/community');
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 28),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Image.asset("assets/images/logo.png", height: 65),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/avatar.jpg"),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Müşteri adına göre ara',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(', bugün $todayOrderCount siparişin var!'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Siparişlerim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Colors.black,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(text: 'Bugün'),
                Tab(text: 'Bekleyen'),
                Tab(text: 'Tümü'),
              ],
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 12),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) =>
                    buildOrderCard(filteredOrders[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddOrderPage()),
          );
          if (result == true) fetchOrders();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
