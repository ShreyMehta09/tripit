import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';
import '../../services/trip_service.dart';
import 'trip_result_screen.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _specialRequirementsController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  int _numberOfDays = 3;
  String _selectedCurrency = 'INR';
  String? _selectedTravelStyle;
  final Set<String> _selectedInterests = {};
  bool _isGenerating = false;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP', 'AUD'];
  final List<String> _travelStyles = [
    'Budget',
    'Mid-Range',
    'Luxury',
    'Backpacking',
    'Adventure',
    'Relaxation',
    'Cultural',
    'Foodie',
  ];

  final List<Map<String, dynamic>> _interests = [
    {'name': 'History', 'icon': Icons.account_balance_rounded},
    {'name': 'Nature', 'icon': Icons.park_rounded},
    {'name': 'Adventure', 'icon': Icons.hiking_rounded},
    {'name': 'Food', 'icon': Icons.restaurant_rounded},
    {'name': 'Photography', 'icon': Icons.camera_alt_rounded},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Nightlife', 'icon': Icons.nightlife_rounded},
    {'name': 'Art', 'icon': Icons.palette_rounded},
    {'name': 'Beach', 'icon': Icons.beach_access_rounded},
    {'name': 'Mountains', 'icon': Icons.terrain_rounded},
    {'name': 'Wildlife', 'icon': Icons.pets_rounded},
    {'name': 'Spiritual', 'icon': Icons.temple_buddhist_rounded},
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    _specialRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _generateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final geminiService = GeminiService.instance;
      final authService = Provider.of<AuthService>(context, listen: false);
      final tripService = TripService();

      final request = TripRequest(
        destination: _destinationController.text.trim(),
        numberOfDays: _numberOfDays,
        startDate: _startDate,
        budget: double.parse(_budgetController.text),
        budgetCurrency: _selectedCurrency,
        travelStyle: _selectedTravelStyle,
        interests: _selectedInterests.isNotEmpty ? _selectedInterests.toList() : null,
        specialRequirements: _specialRequirementsController.text.trim().isNotEmpty 
            ? _specialRequirementsController.text.trim() 
            : null,
      );

      final itinerary = await geminiService.generateTripItinerary(request);

      final trip = TripModel(
        userId: authService.user!.uid,
        destination: request.destination,
        numberOfDays: request.numberOfDays,
        startDate: request.startDate,
        budget: request.budget,
        budgetCurrency: request.budgetCurrency,
        travelStyle: request.travelStyle,
        interests: request.interests,
        specialRequirements: request.specialRequirements,
        itinerary: itinerary,
      );

      // Save to Firestore
      final tripId = await tripService.saveTrip(trip);
      final savedTrip = trip.copyWith(id: tripId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripResultScreen(trip: savedTrip),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Plan Your Trip',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // AI Assistant Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI-Powered Planning',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Get a personalized itinerary created by Gemini AI',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Destination
                        _buildLabel('Where do you want to go?'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _destinationController,
                          decoration: InputDecoration(
                            hintText: 'Enter destination (e.g., Goa, India)',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a destination';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Start Date
                        _buildLabel('When do you want to start?'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded),
                                const SizedBox(width: 12),
                                Text(
                                  dateFormat.format(_startDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Number of Days
                        _buildLabel('How many days?'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDayButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (_numberOfDays > 1) {
                                    setState(() => _numberOfDays--);
                                  }
                                },
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$_numberOfDays',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _numberOfDays == 1 ? 'day' : 'days',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              _buildDayButton(
                                icon: Icons.add,
                                onTap: () {
                                  if (_numberOfDays < 30) {
                                    setState(() => _numberOfDays++);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Budget
                        _buildLabel("What's your budget?"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Currency Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCurrency,
                                  items: _currencies
                                      .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedCurrency = value!);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Budget Input
                            Expanded(
                              child: TextFormField(
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter amount',
                                  prefixIcon:
                                      const Icon(Icons.account_balance_wallet_outlined),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter budget';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Travel Style
                        _buildLabel('Travel Style (Optional)'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _travelStyles.map((style) {
                            final isSelected = _selectedTravelStyle == style;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTravelStyle =
                                      isSelected ? null : style;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6C63FF)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  style,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Interests
                        _buildLabel('What interests you? (Optional)'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interests.map((interest) {
                            final isSelected = _selectedInterests.contains(interest['name']);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedInterests.remove(interest['name']);
                                  } else {
                                    _selectedInterests.add(interest['name']);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF4ECDC4)
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4ECDC4)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      interest['icon'] as IconData,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      interest['name'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Special Requirements
                        _buildLabel('Any special requirements? (Optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _specialRequirementsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'E.g., Vegetarian food, wheelchair accessible, traveling with kids...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(Icons.note_alt_outlined),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Generate Button
                        ElevatedButton(
                          onPressed: _isGenerating ? null : _generateTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            shadowColor: const Color(0xFF6C63FF).withOpacity(0.5),
                          ),
                          child: _isGenerating
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Creating your itinerary...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome),
                                    SizedBox(width: 12),
                                    Text(
                                      'Generate AI Itinerary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDayButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6C63FF),
        ),
      ),
    );
  }
}
