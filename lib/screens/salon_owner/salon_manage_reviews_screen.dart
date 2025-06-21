import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../user_provider.dart';

class SalonManageReviewsScreen extends StatefulWidget {
  const SalonManageReviewsScreen({super.key});

  @override
  State<SalonManageReviewsScreen> createState() =>
      _SalonManageReviewsScreenState();
}

class _SalonManageReviewsScreenState extends State<SalonManageReviewsScreen> {
  final supabase = Supabase.instance.client;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> _reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    setState(() => isLoading = true);

    try {
      final salonId = Provider.of<UserProvider>(context, listen: false).salonId;

      final response = await supabase
          .from('reviews')
          .select('*, users(full_name)')
          .eq('salon_id', salonId as Object)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetchedReviews = response.map<Map<String, dynamic>>((r) => {
        'id': r['id'],
        'customer': r['users']['full_name'] ?? 'Customer',
        'rating': r['rating'],
        'comment': r['comment'],
        'date': DateFormat('yyyy-MM-dd').format(
            DateTime.parse(r['created_at'] ?? DateTime.now().toString())),
        'reply': r['reply'] ?? '',
        'reply_at': r['reply_at'],
      }).toList();

      setState(() {
        _reviews = fetchedReviews;
      });
    } catch (e) {
      print("Failed to fetch reviews: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _addReply(int index) async {
    TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Reply to Review', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: replyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your Reply',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final replyText = replyController.text.trim();
                if (replyText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reply.')),
                  );
                  return;
                }

                try {
                  final reviewId = _reviews[index]['id'];
                  await supabase.from('reviews').update({
                    'reply': replyText,
                    'reply_at': DateTime.now().toIso8601String(),
                  }).eq('id', reviewId);

                  setState(() {
                    _reviews[index]['reply'] = replyText;
                    _reviews[index]['reply_at'] =
                        DateFormat('yyyy-MM-dd').format(DateTime.now());
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply added successfully.')),
                  );
                } catch (e) {
                  print("Failed to add reply: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add reply.')),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterReviews(int rating) {
    return _reviews.where((review) => review['rating'] == rating).toList();
  }

  Widget _buildReviewCard(Map<String, dynamic> review, int index) {
    final String customerName = review['customer'];
    final String initial = customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.blue.shade50,
                  label: Text(
                    '${review['rating']}/5',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review['comment'],
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              "Date: ${review['date']}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (review['reply'].isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.reply, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Salon replied: ${review['reply']}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.reply, color: Colors.blue),
                  label: const Text('Reply'),
                  onPressed: () => _addReply(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return const Center(
        child: Text(
          'No reviews yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchReviews,
      child: AnimatedList(
        key: _listKey,
        initialItemCount: reviews.length,
        itemBuilder: (context, index, animation) {
          return SizeTransition(
            sizeFactor: animation,
            child: _buildReviewCard(reviews[index], index),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Reviews'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'All'),
              Tab(text: '5 Stars'),
              Tab(text: '4 Stars'),
              Tab(text: '3 Stars'),
              Tab(text: '2 Stars'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReviewList(_reviews),
            _buildReviewList(_filterReviews(5)),
            _buildReviewList(_filterReviews(4)),
            _buildReviewList(_filterReviews(3)),
            _buildReviewList(_filterReviews(2)),
          ],
        ),
      ),
    );
  }
}
