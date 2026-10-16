import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RealTimeService {
  static Future<void> pushConfig(Map<String, dynamic> c) async {}
  static Future<void> pushShops(List shops) async {}
}
class AdminState {
  static List<Map<String, dynamic>> shops = [];
  static double feePerKm = 1000;
  static String flutterwaveLink = '';
  static String paymentApiLink = '';
}

void main() => runApp(const KagadiApp());

class KagadiApp extends StatelessWidget {
  const KagadiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAGADI MOBILE MARKET AND SERVICES CENTRE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> currentShops = [];
  List<Map<String, dynamic>> cart = [];
  void _add(Map<String, dynamic> shop) {
    setState(() => cart.add(shop));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${shop["name"]} added')));
  }
  void _openShop(Map<String, dynamic> shop) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage(shop: shop, onAdd: _add)));
  }
  @override
  void initState() { super.initState(); currentShops = AdminState.shops; }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KAGADI MOBILE MARKET AND SERVICES CENTRE', style: TextStyle(fontSize: 11)),
        backgroundColor: const Color(0xFF0A3D62),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(cart: cart))), icon: Badge(label: Text('${cart.length}'), child: const Icon(Icons.shopping_cart))),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanel())), icon: const Icon(Icons.admin_panel_settings)),
        ],
      ),
      body: currentShops.isEmpty
      ? SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
            _card('RETAILERS', 'Numbers - Tap ADMIN to add shops', () {}),
            _card('SERVICES', 'Pharmacy - Clinic - Saloon', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesPage()))),
            _card('BODA-BODA', 'OR TRANSPORT - Destination all Uganda', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BodaPage()))),
            const SizedBox(height: 20),
            const Text('ALL RIGHTS RESERVED © Design by mcrezil Ezra', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]))
        : ListView.builder(padding: const EdgeInsets.all(10), itemCount: currentShops.length, itemBuilder: (_, i) {
              final s = currentShops[i];
              return Card(child: ListTile(title: Text(s['name']?? ''), subtitle: Text(s['category']?? ''), trailing: Text('${s['phone']?? ''}'), onTap: () => _openShop(s)));
            }),
    );
  }
  Widget _card(String t, String sub, VoidCallback tap) {
    return InkWell(onTap: tap, child: Container(height: 120, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF0A3D62), Color(0xFF079992)])), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 11))])) );
  }
}

class ShopPage extends StatelessWidget {
  final Map<String, dynamic> shop;
  final Function(Map<String, dynamic>) onAdd;
  const ShopPage({super.key, required this.shop, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shop['name']?? 'Shop')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(shop['name']?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(shop['category']?? ''),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () { onAdd(shop); Navigator.pop(context); }, child: const Text('Add to Cart')),
        const SizedBox(height: 10),
        Text('Order UGX Total - ${shop['phone']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ])),
    );
  }
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  const CartPage({super.key, required this.cart});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    double total = widget.cart.fold(0, (sum, item) => sum + ((item['price'] as int?)?? 1000));
    return Scaffold(
      appBar: AppBar(title: Text('KAGADI MOBILE MARKET - Cart ${widget.cart.length}')),
      body: widget.cart.isEmpty? const Center(child: Text('Cart empty')) : ListView.builder(itemCount: widget.cart.length, itemBuilder: (_, i) {
        final it = widget.cart[i];
        return Card(child: ListTile(title: Text(it['name']?? ''), subtitle: Text('${it['price']?? ''} UGX'), trailing: IconButton(icon: const Icon(Icons.remove), onPressed: () { setState(() { if ((it['qty'] as int?)!= null && (it['qty'] as int) > 1) { it['qty'] = (it['qty'] as int) - 1; } else { widget.cart.removeAt(i); } }); })));
      }),
      bottomNavigationBar: Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Total: $total UGX - For QUICK DELIVERY, PAY NOW - From Cart', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async { final uri = Uri.parse(AdminState.flutterwaveLink.isEmpty? 'https://flutterwave.com' : AdminState.flutterwaveLink); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('PLACE ORDER NOW - WhatsApp?'), content: SelectableText('Payment API: ${AdminState.paymentApiLink}', style: const TextStyle(fontSize: 9, color: Colors.grey)))); }, child: const Text('FOR QUICK DELIVERY, PAY NOW - From Cart'))),
      ])),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('SERVICES')), body: const Center(child: Text('Pharmacy • Clinic • Saloon')));
}

class BodaPage extends StatelessWidget {
  const BodaPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('BODA-BODA')), body: const Center(child: Text('Transport all Uganda - OR TRANSPORT Destination all Uganda - USX')));
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final fee = TextEditingController(text: '1000');
  final flutter = TextEditingController();
  final api = TextEditingController();
  final shopName = TextEditingController();
  final shopCat = TextEditingController();
  final goodName = TextEditingController();
  final goodPrice = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADMIN - Real-time Push 3 sec')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text('CONFIG - Customers see in 3 sec', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: fee, decoration: const InputDecoration(labelText: 'Fee per Km UGX', prefixIcon: Icon(Icons.motorcycle))),
        TextField(controller: flutter, decoration: InputDecoration(labelText: 'Flutterwave Link', suffixIcon: IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: flutter.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); }))),
        TextField(controller: api, decoration: InputDecoration(labelText: 'Payment API Link COPYABLE', suffixIcon: IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: api.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API copied'))); }))),
        const Divider(), const Text('ADD SHOP', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: shopName, decoration: const InputDecoration(labelText: 'Shop Name')),
        TextField(controller: shopCat, decoration: const InputDecoration(labelText: 'Category: Pharmacy/Clinic/Saloon/General Trade/Electronics')),
        TextField(controller: goodName, decoration: const InputDecoration(labelText: 'Good Name')),
        TextField(controller: goodPrice, decoration: const InputDecoration(labelText: 'Price UGX', prefixText: 'UGX ')),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () async {
          var config = <String, dynamic>{'feePerKm': double.tryParse(fee.text)?? 1000, 'flutterwaveLink': flutter.text, 'paymentApiLink': api.text};
          await RealTimeService.pushConfig(config);
          AdminState.feePerKm = config['feePerKm'] as double;
          AdminState.flutterwaveLink = config['flutterwaveLink'] as String;
          AdminState.paymentApiLink = config['paymentApiLink'] as String;
          if (shopName.text.isNotEmpty) {
            var newShop = <String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': shopName.text, 'category': shopCat.text.isEmpty? 'General Trade' : shopCat.text, 'type': 'Retail', 'phone': '0784866719', 'whatsapp': '0784866719', 'logo': shopName.text.substring(0, 2).toUpperCase(), 'trusted': true, 'goods': goodName.text.isNotEmpty? [<String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': goodName.text, 'price': int.tryParse(goodPrice.text)?? 1000, 'unit': 'numbers', 'stock': 100}] : []};
            AdminState.shops.add(newShop);
            await RealTimeService.pushShops(AdminState.shops);
          }
          if(mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved! Customers see in 3 sec - Real-time Push'))); }
        }, child: const Text('Save - Push Real-time')),
      ])),
    );
  }
}
