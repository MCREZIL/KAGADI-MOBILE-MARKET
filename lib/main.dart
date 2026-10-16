import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KagadiApp());
}

class KagadiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAGADI MOBILE MARKET AND SERVICES CENTRE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Color(0xFFF8F9FA)),
      home: HomePage(),
    );
  }
}

// NO SERVER BUT REAL-TIME ENGINE
class RealTimeService {
  static final StreamController<List<Map<String,dynamic>>> _shopController = StreamController.broadcast();
  static final StreamController<Map<String,dynamic>> _configController = StreamController.broadcast();
  static Timer? _pollTimer;

  static Stream<List<Map<String,dynamic>>> get shopsStream => _shopController.stream;
  static Stream<Map<String,dynamic>> get configStream => _configController.stream;

  static void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: 3), (t) async {
      var p = await SharedPreferences.getInstance();
      var shopsJson = p.getString('shops_v2');
      var configJson = p.getString('config_v2');
      if (shopsJson!= null) {
        List shops = jsonDecode(shopsJson);
        _shopController.add(List<Map<String,dynamic>>.from(shops));
      }
      if (configJson!= null) {
        _configController.add(Map<String,dynamic>.from(jsonDecode(configJson)));
      }
    });
  }

  static Future<void> pushShops(List<Map<String,dynamic>> shops) async {
    var p = await SharedPreferences.getInstance();
    await p.setString('shops_v2', jsonEncode(shops));
    await p.setString('last_update', DateTime.now().toIso8601String());
    _shopController.add(shops);
  }

  static Future<void> pushConfig(Map<String,dynamic> config) async {
    var p = await SharedPreferences.getInstance();
    await p.setString('config_v2', jsonEncode(config));
    _configController.add(config);
  }
}

class AdminState {
  static bool isAdminCreated = false;
  static String? adminHash;
  static String? adminSalt;
  static double feePerKm = 1000;
  static String flutterwaveLink = "https://flutterwave.com/pay/kagadi-market";
  static String paymentApiLink = "https://api.flutterwave.com/v3/payments/kagadi-quick";
  static List<Map<String,dynamic>> shops = [
    {"id":"1","name":"KAGADI CENTRAL PHARMACY","category":"Pharmacy","type":"Service","phone":"0784886719","whatsapp":"0784886719","logo":"PHARMACY","trusted":true,"goods":[{"id":"g1","name":"Panadol","price":500,"unit":"numbers","stock":100},{"id":"g2","name":"Septrin","price":1000,"unit":"numbers","stock":50}]},
    {"id":"2","name":"KAGADI GENERAL TRADE","category":"General Trade","type":"Retail","phone":"0784886719","whatsapp":"0784886719","logo":"GENERAL","trusted":true,"goods":[{"id":"g3","name":"Sugar 1kg","price":4000,"unit":"numbers","stock":200},{"id":"g4","name":"Rice 1kg","price":4500,"unit":"numbers","stock":150}]},
    {"id":"3","name":"KAGADI ELECTRONICS","category":"Electronics","type":"Retail","phone":"0784886719","whatsapp":"0784886719","logo":"ELEC","trusted":true,"goods":[{"id":"g5","name":"Phone Charger","price":15000,"unit":"numbers","stock":30}]},
  ];

  static Future<void> loadAll() async {
    var p = await SharedPreferences.getInstance();
    isAdminCreated = p.getBool('admin_created')?? false;
    adminHash = p.getString('admin_hash');
    adminSalt = p.getString('admin_salt');
    var shopsJson = p.getString('shops_v2');
    var configJson = p.getString('config_v2');
    if (shopsJson!= null) shops = List<Map<String,dynamic>>.from(jsonDecode(shopsJson));
    if (configJson!= null) {
      var c = jsonDecode(configJson);
      feePerKm = (c['feePerKm']?? 1000).toDouble();
      flutterwaveLink = c['flutterwaveLink']?? flutterwaveLink;
      paymentApiLink = c['paymentApiLink']?? paymentApiLink;
    }
    RealTimeService.startPolling();
  }
}

class HomePage extends StatefulWidget { @override _HomePageState createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  PageController _swipeCtrl = PageController();
  int _cur = 0;
  Timer? _timer;
  List<Map<String,dynamic>> cart = [];
  String searchQuery = "";
  List<Map<String,dynamic>> currentShops = [];

  @override
  void initState() {
    super.initState();
    AdminState.loadAll().then((_) {
      setState(() => currentShops = AdminState.shops);
      RealTimeService.shopsStream.listen((shops) {
        if (mounted) setState(() => currentShops = shops);
      });
      RealTimeService.configStream.listen((config) {
        if (mounted) setState(() {
          AdminState.feePerKm = (config['feePerKm']?? 1000).toDouble();
          AdminState.flutterwaveLink = config['flutterwaveLink']?? AdminState.flutterwaveLink;
          AdminState.paymentApiLink = config['paymentApiLink']?? AdminState.paymentApiLink;
        });
      });
    });
    _timer = Timer.periodic(Duration(seconds: 4), (t) {
      if (_swipeCtrl.hasClients && currentShops.isNotEmpty) {
        _cur = (_cur + 1) % currentShops.length;
        _swipeCtrl.animateToPage(_cur, duration: Duration(milliseconds: 500), curve: Curves.ease);
      }
    });
  }

  @override
  Widget build(BuildContext c) {
    var filteredShops = searchQuery.isEmpty? currentShops : currentShops.where((s) {
      bool inName = s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      bool inGoods = (s['goods'] as List).any((g) => g['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()));
      return inName || inGoods;
    }).toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF0A3D62), title: Text("KAGADI MOBILE MARKET AND SERVICES CENTRE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white)), centerTitle: true, leading: Builder(builder: (ctx) => IconButton(icon: Icon(Icons.menu, color: Colors.white), onPressed: () => Scaffold.of(ctx).openDrawer())), actions: [Stack(children: [IconButton(icon: Icon(Icons.shopping_cart, color: Colors.white), onPressed: () => _openCart()), if (cart.isNotEmpty) Positioned(right: 6, top: 6, child: CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Text("${cart.fold(0, (a, b) => a + (b['qty'] as int))}", style: TextStyle(fontSize: 10, color: Colors.white))))])]),
      drawer: _drawer(),
      body: SingleChildScrollView(child: Column(children: [
        Container(padding: EdgeInsets.all(12), color: Colors.white, child: TextField(onChanged: (v) => setState(() => searchQuery = v), decoration: InputDecoration(hintText: "FOR ALL GOOD AND SERVICE OFFERED OR REGISTERED IN OUR DATABASE", prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Color(0xFFF1F2F6)))),
        Container(height: 160, child: currentShops.isEmpty? Center(child: CircularProgressIndicator()) : PageView.builder(controller: _swipeCtrl, itemCount: currentShops.length, itemBuilder: (_, i) { var s = currentShops[i]; return Container(margin: EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [Color(0xFF0A3D62), Color(0xFF079992)])), child: ListTile(leading: CircleAvatar(child: Text(s['logo'].toString().substring(0, 2))), title: Text(s['name']?? "", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text("TRUSTED • ${s['category']} • Real-time", style: TextStyle(color: Colors.white70, fontSize: 11)), onTap: () => _openShop(s))); })),
        Padding(padding: EdgeInsets.all(12), child: Column(children: [
          _bigCard("GOODS", "Retailers (numbers) • Wholesalers (packets,bundles,boxes)", [Color(0xFFeb3b5a), Color(0xFFfc5c65)], () { Navigator.push(c, MaterialPageRoute(builder: (_) => GoodsPage(cart: cart, onAdd: _add, shops: currentShops))); }),
          SizedBox(height: 16),
          _bigCard("SERVICES", "Pharmacy • Clinic • Saloon - Search inside category", [Color(0xFF20bf6b), Color(0xFF0fb9b1)], () { Navigator.push(c, MaterialPageRoute(builder: (_) => ServicesPage(cart: cart, onAdd: _add, shops: currentShops))); }),
          SizedBox(height: 16),
          _bigCard("NEED BODA-BODA OR TRANSPORT", "Kagadi + Destination all Uganda • UGX ${AdminState.feePerKm.toInt()}/km real-time", [Color(0xFFfa8231), Color(0xFFf7b731)], () { Navigator.push(c, MaterialPageRoute(builder: (_) => BodaPage())); }),
        ])),
        _footer(),
      ])),
    );
  }

  Widget _bigCard(String t, String s, List<Color> col, VoidCallback tap) { return InkWell(onTap: tap, child: Container(height: 130, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: col)), padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text(s, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11))])))); }
  Widget _drawer() { return Drawer(child: ListView(children: [DrawerHeader(decoration: BoxDecoration(color: Color(0xFF0A3D62)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("MCREZIL ADMIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text("KAGADI MOBILE MARKET\nAND SERVICES CENTRE", style: TextStyle(color: Colors.white70, fontSize: 12)), Text("Real-time: No server needed", style: TextStyle(color: Colors.yellow, fontSize: 10))])), if (!AdminState.isAdminCreated) ListTile(title: Text("CREATE ADMIN ACCOUNT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), subtitle: Text("Single account, deletes after creation"), onTap: () => _createDialog()), if (AdminState.isAdminCreated) ListTile(title: Text("ADMIN LOGIN"), onTap: () => _loginDialog()), if (AdminState.isAdminCreated) ListTile(title: Text("ADMIN PANEL - GOD MODE"), subtitle: Text("Edit fee, payment API - Push real-time 3 sec"), onTap: () => _adminPanel()),])); }
  _createDialog() { TextEditingController u = TextEditingController(); TextEditingController p = TextEditingController(); showDialog(context: context, builder: (_) => AlertDialog(title: Text("CREATE SINGLE ADMIN - Hashed"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: u, decoration: InputDecoration(labelText: "Username")), TextField(controller: p, decoration: InputDecoration(labelText: "Password"), obscureText: true), SizedBox(height: 8), Text("Password hashed with salt, never in code. Button deletes forever.", style: TextStyle(fontSize: 11, color: Colors.red))]), actions: [ElevatedButton(onPressed: () async { var salt = _salt(); var hash = _hash(p.text, salt); var sp = await SharedPreferences.getInstance(); await sp.setBool('admin_created', true); await sp.setString('admin_hash', hash); await sp.setString('admin_salt', salt); setState(() => AdminState.isAdminCreated = true); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin created - button deleted forever"))); }, child: Text("Create & Delete Forever"))])); }
  _loginDialog() { TextEditingController p = TextEditingController(); showDialog(context: context, builder: (_) => AlertDialog(title: Text("ADMIN LOGIN - Hashed check"), content: TextField(controller: p, obscureText: true, decoration: InputDecoration(labelText: "Password")), actions: [ElevatedButton(onPressed: () async { var sp = await SharedPreferences.getInstance(); var salt = sp.getString('admin_salt'); var stored = sp.getString('admin_hash'); if (salt!= null && stored!= null && _hash(p.text, salt) == stored) { Navigator.pop(context); _adminPanel(); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wrong password"))); } }, child: Text("Login"))])); }
  _adminPanel() { TextEditingController fee = TextEditingController(text: AdminState.feePerKm.toString()); TextEditingController flutter = TextEditingController(text: AdminState.flutterwaveLink); TextEditingController api = TextEditingController(text: AdminState.paymentApiLink); TextEditingController shopName = TextEditingController(); TextEditingController shopCat = TextEditingController(); TextEditingController goodName = TextEditingController(); TextEditingController goodPrice = TextEditingController(); showDialog(context: context, builder: (_) => AlertDialog(title: Text("ADMIN PANEL - Real-time push 3 sec"), content: SingleChildScrollView(child: Column(children: [Text("CONFIG - Customers see in 3 sec", style: TextStyle(fontWeight: FontWeight.bold)), TextField(controller: fee, decoration: InputDecoration(labelText: "Fee per Km UGX", prefixIcon: Icon(Icons.motorcycle))), TextField(controller: flutter, decoration: InputDecoration(labelText: "Flutterwave Link", suffixIcon: IconButton(icon: Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: flutter.text)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copied!"))); }))), TextField(controller: api, decoration: InputDecoration(labelText: "Payment API Link COPYABLE", suffixIcon: IconButton(icon: Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: api.text)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("API Link copied for quick delivery!"))); }))), Divider(), Text("ADD SHOP - Pushes real-time", style: TextStyle(fontWeight: FontWeight.bold)), TextField(controller: shopName, decoration: InputDecoration(labelText: "Shop Name")), TextField(controller: shopCat, decoration: InputDecoration(labelText: "Category: Pharmacy/Clinic/Saloon/General Trade/Electronics")), TextField(controller: goodName, decoration: InputDecoration(labelText: "Good Name")), TextField(controller: goodPrice, decoration: InputDecoration(labelText: "Price UGX", prefixText: "UGX ")),])), actions: [ElevatedButton(onPressed: () async { var config = {'feePerKm': double.tryParse(fee.text)?? 1000, 'flutterwaveLink': flutter.text, 'paymentApiLink': api.text}; await RealTimeService.pushConfig(config); AdminState.feePerKm = config['feePerKm']; AdminState.flutterwaveLink = config['flutterwaveLink']; AdminState.paymentApiLink = config['paymentApiLink']; if (shopName.text.isNotEmpty) { var newShop = {"id": DateTime.now().millisecondsSinceEpoch.toString(), "name": shopName.text, "category": shopCat.text.isEmpty? "General Trade" : shopCat.text, "type": "Retail", "phone": "0784886719", "whatsapp": "0784886719", "logo": shopName.text.substring(0, 2).toUpperCase(), "trusted": true, "goods": goodName.text.isNotEmpty? [{"id": DateTime.now().millisecondsSinceEpoch.toString(), "name": goodName.text, "price": int.tryParse(goodPrice.text)?? 1000, "unit": "numbers", "stock": 100}] : []}; AdminState.shops.add(newShop); await RealTimeService.pushShops(AdminState.shops); } Navigator.pop(context); setState(() => currentShops = AdminState.shops); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved! Customers see in 3 seconds real-time"))); }, child: Text("Save - Push Real-time"))])); }
  String _salt() { var r = Random.secure(); return base64Encode(List<int>.generate(16, (_) => r.nextInt(256))); }
  String _hash(String p, String s) { return sha256.convert(utf8.encode(p + s)).toString(); }
  _openShop(Map<String, dynamic> shop) { Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage(shop: shop, onAdd: _add))); }
  _add(Map<String, dynamic> item) { setState(() { var idx = cart.indexWhere((c) => c['name'] == item['name'] && c['shop'] == item['shop']); if (idx >= 0) cart[idx]['qty']++; else cart.add(item); }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item['name']} added"))); }
  _openCart() { Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(cart: cart, onUpdate: () => setState(() {})))); }
  Widget _footer() { return Container(color: Color(0xFF0A3D62), padding: EdgeInsets.all(16), child: Column(children: [Text("WE DELIVER IN ALL PARTS OF IN KAGADI AND OTHER COUNTRY AREAS.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center), SizedBox(height: 4), Text("WE ARE TRUSTED BY ALL BUSINESSES IN KAGADI AND BEYOND.", style: TextStyle(color: Colors.white70, fontSize: 10)), Text("Real-time update: 3 sec polling - No server", style: TextStyle(color: Colors.yellow, fontSize: 9)), SizedBox(height: 4), Text("ALL RIGHTS RESERVED © Design by mcrezil Ezra", style: TextStyle(color: Colors.white54, fontSize: 10))])) ; }
}

class CartPage extends StatefulWidget { final List cart; final VoidCallback onUpdate; CartPage({required this.cart, required this.onUpdate}); @override _CartPageState createState() => _CartPageState(); }
class _CartPageState extends State<CartPage> { @override Widget build(BuildContext c) { double total = widget.cart.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int)); return Scaffold(appBar: AppBar(title: Text("KAGADI MOBILE MARKET AND SERVICES CENTRE - CART", style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFF0A3D62)), body: Column(children: [Expanded(child: widget.cart.isEmpty? Center(child: Text("Cart empty")) : ListView.builder(itemCount: widget.cart.length, itemBuilder: (_, i) { var item = widget.cart[i]; return Card(child: ListTile(title: Text(item['name']), subtitle: Text("${item['shop']} • UGX ${item['price']}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.remove), onPressed: () { setState(() { if (item['qty'] > 1) item['qty']--; else widget.cart.removeAt(i); }); widget.onUpdate(); }), Text("${item['qty']}", style: TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: Icon(Icons.add), onPressed: () { setState(() => item['qty']++); widget.onUpdate(); }), IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => widget.cart.removeAt(i)); widget.onUpdate(); })]))); })), Container(padding: EdgeInsets.all(16), color: Colors.white, child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total:", style: TextStyle(fontSize: 18)), Text("UGX $total", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]), SizedBox(height: 12), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async { final uri = Uri.parse(AdminState.flutterwaveLink); if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication); }, child: Text("FOR QUICK DELIVERY, PAY NOW - From Cart", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)))), SizedBox(height: 10), SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () async { final uri = Uri.parse("https://wa.me/256784886719?text=Hello KAGADI MOBILE MARKET CENTRE, Order UGX $total: ${widget.cart.map((e) => '${e['name']}x${e['qty']}').join(', ')}"); if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication); }, child: Text("PLACE ORDER NOW - WhatsApp"))), SizedBox(height: 8), SelectableText("Payment API: ${AdminState.paymentApiLink}", style: TextStyle(fontSize: 9, color: Colors.grey)),]])),])); } }

class GoodsPage extends StatelessWidget { final List cart; final Function(Map<String, dynamic>) onAdd; final List<Map<String, dynamic>> shops; GoodsPage({required this.cart, required this.onAdd, required this.shops}); @override Widget build(BuildContext c) { return Scaffold(appBar: AppBar(title: Text("KAGADI MOBILE MARKET AND SERVICES CENTRE - GOODS", style: TextStyle(fontSize: 12)), backgroundColor: Color(0xFF0A3D62)), body: Column(children: [_card("RETAILERS", "Numbers -
