import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase web skipped: $e");
  }
  runApp(const KagadiMarketApp());
}

class KagadiMarketApp extends StatelessWidget {
  const KagadiMarketApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KAGADI MOBILE MARKET',
      theme: ThemeData(useMaterial3: true, primaryColor: Color(0xFF0A3D62), colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0A3D62))),
      home: const MainLayout(),
    );
  }
}

// MODELS
class Product {
  final String name, price, image, category;
  Product(this.name, this.price, this.image, this.category);
}

List<Product> allProducts = [
  Product("Tecno Spark 20", "450,000 UGX", "📱", "Phones"),
  Product("Infinix Hot 40", "520,000 UGX", "📱", "Phones"),
  Product("Samsung A15", "680,000 UGX", "📱", "Phones"),
  Product("Itel Power Bank", "45,000 UGX", "🔋", "Accessories"),
  Product("Bluetooth Speaker", "85,000 UGX", "🔊", "Accessories"),
  Product("Phone Cover", "15,000 UGX", "📲", "Accessories"),
  Product("Charger Type-C", "25,000 UGX", "🔌", "Accessories"),
  Product("MTN Airtime", "All amounts", "💳", "Airtime"),
];

List<Product> cart = [];

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;
  final pages = [const HomePage(), const ShopPage(), const ServicesPage(), const CartPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.store), label: "Shop"),
          NavigationDestination(icon: Icon(Icons.build), label: "Services"),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A3D62),
      appBar: AppBar(backgroundColor: Color(0xFF0A3D62), foregroundColor: Colors.white, title: Text("KAGADI MOBILE MARKET", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            Icon(Icons.storefront, size: 90, color: Colors.white),
            SizedBox(height: 10),
            Text("Welcome to Kagadi Mobile Market", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text("Kagadi Town, Opposite Centenary Bank", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _stat("1000+", "Products"),
                    _stat("24/7", "Support"),
                    _stat("Free", "Delivery in Town"),
                  ]),
                  SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: Text("SHOP NOW - Call 077XXXXXXX"))),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text("Popular Categories", style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 10),
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), children: [
              _catCard("📱 Phones", "Tecno, Infinix, Samsung"),
              _catCard("🔌 Accessories", "Chargers, Covers, Power banks"),
              _catCard("💳 Airtime & Data", "MTN, Airtel"),
              _catCard("🔧 Repair Services", "Screen, Battery, Software"),
            ]),
            SizedBox(height: 20),
            Text("All Rights Reserved © Design by morezil Ezra", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String t1, String t2) => Column(children: [Text(t1, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(t2, style: TextStyle(fontSize: 12))]);
  Widget _catCard(String title, String sub) => Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 5), Text(sub, style: TextStyle(fontSize: 11), textAlign: TextAlign.center)])));
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String filter = "All";
  @override
  Widget build(BuildContext context) {
    List<Product> filtered = filter == "All" ? allProducts : allProducts.where((p) => p.category == filter).toList();
    return Scaffold(
      appBar: AppBar(title: Text("Shop")),
      body: Column(
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: EdgeInsets.all(8), child: Row(children: ["All", "Phones", "Accessories", "Airtime"].map((c) => Padding(padding: EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c), selected: filter == c, onSelected: (v) => setState(() => filter = c)))).toList())),
          Expanded(child: GridView.builder(padding: EdgeInsets.all(10), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8), itemCount: filtered.length, itemBuilder: (context, i) {
            var p = filtered[i];
            return Card(child: Padding(padding: EdgeInsets.all(10), child: Column(children: [Text(p.image, style: TextStyle(fontSize: 40)), SizedBox(height: 8), Text(p.name, style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), Text(p.price, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Spacer(), ElevatedButton(onPressed: () { setState(() => cart.add(p)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p.name} added to cart"))); }, child: Text("Add to Cart"))])));
          })),
        ],
      ),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Services")),
      body: ListView(padding: EdgeInsets.all(16), children: [
        ListTile(leading: Icon(Icons.phone_iphone), title: Text("Phone Repair"), subtitle: Text("Screens, Batteries, Charging ports - All phones")),
        ListTile(leading: Icon(Icons.sd_card), title: Text("Software Services"), subtitle: Text("Flashing, FRP, Pattern unlock")),
        ListTile(leading: Icon(Icons.sim_card), title: Text("SIM Services"), subtitle: Text("SIM replacement, Registration, Airtime, Mobile Money")),
        ListTile(leading: Icon(Icons.computer), title: Text("Accessories Wholesale"), subtitle: Text("Retail & wholesale prices in Kagadi")),
        SizedBox(height: 20),
        Card(color: Color(0xFF0A3D62), child: Padding(padding: EdgeInsets.all(16), child: Column(children: [Text("Visit Us", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text("Kagadi Mobile Market & Services Centre\nKagadi Town\nCall: 077x xxx xxx / 075x xxx xxx\nWhatsApp Available", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)]))),
      ]),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cart (${cart.length})")),
      body: cart.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 80), Text("Your cart is empty"), SizedBox(height: 10), Text("Add products from Shop")]))
          : Column(children: [
              Expanded(child: ListView.builder(itemCount: cart.length, itemBuilder: (context, i) => ListTile(leading: Text(cart[i].image), title: Text(cart[i].name), subtitle: Text(cart[i].price), trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => setState(() => cart.removeAt(i)))))),
              Padding(padding: EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () { setState(() => cart.clear()); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order sent! We will call you."))); }, child: Text("Order via WhatsApp", style: TextStyle(color: Colors.white))))),
            ]),
    );
  }
}
