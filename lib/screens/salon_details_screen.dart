import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalonDetailsScreen extends StatefulWidget {
  final String salonId;
  final String salonName;

  const SalonDetailsScreen({super.key, required this.salonId, required this.salonName});

  @override
  _SalonDetailsScreenState createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? _salonDetails;
  List<Map<String, dynamic>> _services = [];
  List<String> _imageUrls = [];
  bool _isLoading = true;
  int _waitingTime = 0;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;


  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchSalonDetails(),
      _fetchServices(),
      _fetchWaitingTime(),
      _fetchSalonImages(),
      _fetchReviews(),
    ]);
    setState(() => _isLoading = false);
  }
  Future<void> _fetchReviews() async {
    try {
      final response = await supabase
          .from('reviews')
          .select('rating, comment, created_at, user_id')
          .eq('salon_id', widget.salonId)
          .order('created_at', ascending: false);

      final reviews = List<Map<String, dynamic>>.from(response);
      double totalRating = 0;

      for (var review in reviews) {
        totalRating += (review['rating'] ?? 0).toDouble();
      }

      setState(() {
        _reviews = reviews;
        _averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
      });
    } catch (e) {
      _showSnackbar("Error fetching reviews: $e");
    }
  }

  Future<void> _fetchSalonDetails() async {
    try {
      final response = await supabase
          .from('salons')
          .select('salon_name, address, contact, opening_hours, closing_hours, description')
          .eq('id', widget.salonId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _salonDetails = response;
        });
      }
    } catch (e) {
      _showSnackbar("Error fetching salon details: $e");
    }
  }

  Future<void> _fetchServices() async {
    try {
      final servicesResponse = await supabase
          .from('services')
          .select('name, price')
          .eq('salon_id', widget.salonId);

      setState(() {
        _services = List<Map<String, dynamic>>.from(servicesResponse);
      });
    } catch (e) {
      _showSnackbar("Error fetching services: $e");
    }
  }

  Future<void> _fetchWaitingTime() async {
    try {
      setState(() => _isRefreshing = true);
      final response = await supabase
          .from('walk_in_queue')
          .select('total_queue_duration')
          .eq('salon_id', widget.salonId)
          .maybeSingle();

      if (response != null && response['total_queue_duration'] != null) {
        setState(() {
          _waitingTime = response['total_queue_duration'];
        });
      }
    } catch (e) {
      _showSnackbar("Error fetching waiting time: $e");
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _fetchSalonImages() async {
    try {
      final response = await supabase
          .from('salon_images')
          .select('image_url')
          .eq('salon_id', widget.salonId);

      setState(() {
        _imageUrls = List<Map<String, dynamic>>.from(response)
            .map((img) => img['image_url'] as String)
            .toList();
      });
    } catch (e) {
      _showSnackbar("Error fetching salon images: $e");
    }
  }

  String _formatWaitingTime(int minutes) {
    if (minutes < 60) return "$minutes min";
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return mins > 0 ? "$hours hr $mins min" : "$hours hr";
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.salonName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchAllData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSalonHeader(),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.location_on, "Address", _salonDetails?['address'] ?? 'Not available'),
              _buildInfoRow(Icons.phone, "Contact", _salonDetails?['contact'] ?? 'Not available'),
              _buildInfoRow(Icons.schedule, "Opening Hours", _salonDetails?['opening_hours'] ?? 'Not available'),
              _buildInfoRow(Icons.lock_clock, "Closing Hours", _salonDetails?['closing_hours'] ?? 'Not available'),
              const SizedBox(height: 20),
              _buildWaitingTimeBox(),
              const SizedBox(height: 8),
              _buildWaitingTimeInfoNote(),
              const SizedBox(height: 20),
              _buildSalonDescription(),
              const SizedBox(height: 20),
              _buildSalonServices(),


              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBookNowButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSalonHeader() {
    if (_imageUrls.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _imageUrls[index],
                  height: 200,
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 80, color: Colors.blueGrey),
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title: $value",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingTimeBox() {
    Color bgColor;
    Color textColor;
    Icon icon;

    if (_waitingTime <= 15) {
      bgColor = Colors.greenAccent.withOpacity(0.2);
      textColor = Colors.green.shade800;
      icon = const Icon(Icons.check_circle, color: Colors.green);
    } else if (_waitingTime <= 45) {
      bgColor = Colors.orangeAccent.withOpacity(0.2);
      textColor = Colors.orange.shade800;
      icon = const Icon(Icons.access_time, color: Colors.orange);
    } else {
      bgColor = Colors.redAccent.withOpacity(0.2);
      textColor = Colors.red.shade800;
      icon = const Icon(Icons.warning_amber, color: Colors.red);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: textColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Current Waiting Time: ${_formatWaitingTime(_waitingTime)}",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.refresh, color: textColor),
            onPressed: _isRefreshing ? null : _fetchWaitingTime,
          ),
        ],
      ),
    );
  }


  Widget _buildWaitingTimeInfoNote() {
    String message;
    Color color;

    if (_waitingTime <= 15) {
      message = "💜 No or minimal wait — walk in freely!";
      color = Colors.deepPurple.shade600;
    } else if (_waitingTime <= 45) {
      message = "⏳ Moderate wait — you may want to book ahead.";
      color =Colors.deepPurple.shade400;
    } else {
      message = "⚠️ High wait time — consider booking an appointment.";
      color =  Colors.red.shade700;
    }

    return Text(
      message,
      style: GoogleFonts.poppins(fontSize: 17, color: color),
    );
  }


  Widget _buildSalonDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("About the Salon", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          _salonDetails?['description'] ?? 'No description available.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildSalonServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("💆 Services Offered", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        if (_services.isNotEmpty)
          ..._services.map(
                (service) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(service['name'], style: GoogleFonts.poppins(fontSize: 16)),
                  Text("₹${service['price']}", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        else
          const Text("No services available.", style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }
  Widget _buildRatingAndReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text("⭐ Average Rating", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 6),
            Text(
              _averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text("(${_reviews.length} reviews)", style: GoogleFonts.poppins(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 20),
        Text("📝 Customer Reviews", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        if (_reviews.isNotEmpty)
          ..._reviews.map(
                (review) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                          (index) => Icon(
                        index < review['rating'] ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['comment'] ?? 'No comment',
                    style: GoogleFonts.poppins(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTime.parse(review['created_at']).toLocal().toString().substring(0, 16),
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          const Text("No reviews yet.", style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }


  Widget _buildBookNowButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/booking',
          arguments: {
            'salonName': widget.salonName,
            'salonId': widget.salonId,
          },
        );
      },
      icon: const Icon(Icons.calendar_today,color: Colors.white),
      label: Text(
        "Book Now",
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold,color:Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }


}
