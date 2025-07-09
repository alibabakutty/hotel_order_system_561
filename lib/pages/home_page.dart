import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _foodItems = [
    {
      'name': 'Burger',
      'price': 179.00,
      'image': 'assets/burger.jpg',
      'rating': 4.5,
    },
    {
      'name': 'Pizza',
      'price': 239.00,
      'image': 'assets/pizza.jpg',
      'rating': 4.8,
    },
    {
      'name': 'Pasta',
      'price': 89.00,
      'image': 'assets/pasta.jpg',
      'rating': 4.3,
    },
    {
      'name': 'Salad',
      'price': 79.00,
      'image': 'assets/salad.jpg',
      'rating': 4.0,
    },
    {
      'name': 'Sushi',
      'price': 99.00,
      'image': 'assets/sushi.jpg',
      'rating': 4.7,
    },
    {
      'name': 'Steak',
      'price': 149.00,
      'image': 'assets/steak.jpg',
      'rating': 4.9,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Ordering System'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategories(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Popular Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFoodItems(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final List<String> categories = [
      'All',
      'Burgers',
      'Pizza',
      'Pasta',
      'Salads',
      'Desserts',
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(categories[index]),
              backgroundColor: index == 0 ? Colors.blue : Colors.grey[200],
              labelStyle: TextStyle(
                color: index == 0 ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodItems() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _foodItems.length,
      itemBuilder: (context, index) {
        final item = _foodItems[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.asset(
                    item['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${item['rating']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '₹${item['price']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
