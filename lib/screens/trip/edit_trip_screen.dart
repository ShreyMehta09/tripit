import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';

class EditTripScreen extends StatefulWidget {
  final TripModel trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripService = TripService();
  
  late TextEditingController _destinationController;
  late TextEditingController _budgetController;
  late TextEditingController _daysController;
  late TextEditingController _specialReqController;
  late DateTime _selectedDate;
  late String _selectedCurrency;
  String? _selectedTravelStyle;
  List<String> _selectedInterests = [];
  
  bool _isSaving = false;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];
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
  final List<String> _interestsOptions = [
    'Food',
    'History',
    'Nature',
    'Shopping',
    'Photography',
    'Sports',
    'Art',
    'Music',
  ];

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(text: widget.trip.destination);
    _budgetController = TextEditingController(text: widget.trip.budget.toString());
    _daysController = TextEditingController(text: widget.trip.numberOfDays.toString());
    _specialReqController = TextEditingController(text: widget.trip.specialRequirements ?? '');
    _selectedDate = widget.trip.startDate;
    _selectedCurrency = widget.trip.budgetCurrency ?? 'INR';
    _selectedTravelStyle = widget.trip.travelStyle;
    _selectedInterests = widget.trip.interests ?? [];
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    _daysController.dispose();
    _specialReqController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updates = {
        'destination': _destinationController.text.trim(),
        'budget': double.parse(_budgetController.text),
        'budgetCurrency': _selectedCurrency,
        'numberOfDays': int.parse(_daysController.text),
        'startDate': _selectedDate,
        'travelStyle': _selectedTravelStyle,
        'interests': _selectedInterests,
        'specialRequirements': _specialReqController.text.trim().isEmpty 
            ? null 
            : _specialReqController.text.trim(),
      };

      await _tripService.updateTrip(widget.trip.id!, updates);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate changes were saved
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip updated successfully!'),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Edit Trip',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Basic Information'),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _destinationController,
                          label: 'Destination',
                          icon: Icons.location_on_rounded,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _daysController,
                                label: 'Days',
                                icon: Icons.calendar_today_rounded,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Required';
                                  final days = int.tryParse(value!);
                                  if (days == null || days < 1) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 730),
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() => _selectedDate = date);
                                  }
                                },
                                child: AbsorbPointer(
                                  child: _buildTextField(
                                    controller: TextEditingController(
                                      text: DateFormat('MMM d, yyyy')
                                          .format(_selectedDate),
                                    ),
                                    label: 'Start Date',
                                    icon: Icons.event_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _budgetController,
                                label: 'Budget',
                                icon: Icons.account_balance_wallet_rounded,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Required';
                                  final budget = double.tryParse(value!);
                                  if (budget == null || budget < 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedCurrency,
                                items: _currencies,
                                label: 'Currency',
                                onChanged: (value) =>
                                    setState(() => _selectedCurrency = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Travel Preferences'),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          value: _selectedTravelStyle,
                          items: _travelStyles,
                          label: 'Travel Style (Optional)',
                          onChanged: (value) =>
                              setState(() => _selectedTravelStyle = value),
                          allowNull: true,
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Interests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interestsOptions.map((interest) {
                            final isSelected = _selectedInterests.contains(interest);
                            return FilterChip(
                              label: Text(interest),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedInterests.add(interest);
                                  } else {
                                    _selectedInterests.remove(interest);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF6C63FF),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _specialReqController,
                          label: 'Special Requirements (Optional)',
                          icon: Icons.note_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // Note about itinerary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Note: The itinerary will remain unchanged. To generate a new itinerary, create a new trip.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
    bool allowNull = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        if (allowNull)
          const DropdownMenuItem(
            value: null,
            child: Text('None'),
          ),
        ...items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
