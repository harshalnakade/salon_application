import 'package:flutter/material.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'John Doe',
      'rating': 5,
      'comment': 'Amazing service! Highly recommended.',
      'date': DateTime(2025, 4, 10),
      'helpful': 12
    },
    {
      'name': 'Jane Smith',
      'rating': 4,
      'comment': 'Great experience, but waiting time was a bit long.',
      'date': DateTime(2025, 3, 15),
      'helpful': 8
    },
    {
      'name': 'Mike Johnson',
      'rating': 3,
      'comment': 'Average service, expected more.',
      'date': DateTime(2025, 2, 28),
      'helpful': 3
    },
  ];

  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  // =========================
  // Calculate Average Rating
  // =========================
  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;

    final totalRating = _reviews.fold<double>(0.0, (sum, review) => sum + (review['rating'] as double));

    return totalRating / _reviews.length;
  }


  // =========================
  // Add New Review
  // =========================
  void _addReview() {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() {
      _reviews.insert(0, {
        'name': 'You',
        'rating': _selectedRating,
        'comment': _reviewController.text,
        'date': DateTime.now(),
        'helpful': 0,
      });
      _reviewController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your review has been added!")),
    );
  }

  // =========================
  // Sort by Highest Rated
  // =========================
  void _sortByHighestRated() {
    setState(() {
      _reviews.sort((a, b) => b['rating'].compareTo(a['rating']));
    });
  }

  // =========================
  // Sort by Newest
  // =========================
  void _sortByNewest() {
    setState(() {
      _reviews.sort((a, b) => b['date'].compareTo(a['date']));
    });
  }

  // =========================
  // Increase "Helpful" Count
  // =========================
  void _markHelpful(int index) {
    setState(() {
      _reviews[index]['helpful'] += 1;
    });
  }

  // =========================
  // UI Build
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _sortByHighestRated,
            tooltip: "Sort by Highest Rated",
          ),
          IconButton(
            icon: const Icon(Icons.new_releases),
            onPressed: _sortByNewest,
            tooltip: "Sort by Newest",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // =========================
            // Average Rating Display
            // =========================
            Column(
              children: [
                Text(
                  '⭐ ${_averageRating.toStringAsFixed(1)}/5',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('${_reviews.length} Reviews'),
              ],
            ),

            const Divider(height: 30),

            // =========================
            // Review Submission Form
            // =========================
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Write a Review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Rating: '),
                DropdownButton<int>(
                  value: _selectedRating,
                  items: List.generate(5, (index) => index + 1)
                      .map((rating) => DropdownMenuItem(
                    value: rating,
                    child: Text('$rating Stars'),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRating = value!;
                    });
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _addReview,
                  child: const Text('Submit'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =========================
            // Review List
            // =========================
            Expanded(
              child: ListView.builder(
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          review['rating'].toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(review['name']),
                      subtitle: Text(review['comment']),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.thumb_up),
                            onPressed: () => _markHelpful(index),
                            color: Colors.green,
                          ),
                          Text('${review['helpful']} helpful'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
