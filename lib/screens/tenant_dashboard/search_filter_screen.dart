import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  double _distance = 5;
  double _price = 500000;
  bool wheelchair = false;
  bool noDisability = false;
  bool shuttle = false;
  bool noShuttle = false;
  bool studyRoom = false;
  bool gym = false;
  bool pool = false;
  bool ac = false;
  bool wifi = false;
  bool electrical = false;
  bool guestPolicy = false;
  bool petFriendly = false;
  String program = '';
  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
  // For filter chips
  List<String> get _activeFilters {
    final List<String> chips = [];
    if (_distance != 5) chips.add('≤ ${_distance.toStringAsFixed(0)} km');
    if (_price != 500000) chips.add('≤ ${_price.toStringAsFixed(0)} UGX');
    if (program.isNotEmpty) chips.add(program);
    if (wheelchair) chips.add('Wheelchair');
    if (noDisability) chips.add('No Disability');
    if (shuttle) chips.add('Shuttle');
    if (noShuttle) chips.add('No Shuttle');
    if (studyRoom) chips.add('Study Room');
    if (gym) chips.add('Gym');
    if (pool) chips.add('Pool');
    if (ac) chips.add('A/C');
    if (wifi) chips.add('Wi-Fi');
    if (electrical) chips.add('Electrical');
    if (guestPolicy) chips.add('Guest Policy');
    if (petFriendly) chips.add('Pet-Friendly');
    return chips;
  }

  // For filter presets (scaffold)
  final List<Map<String, dynamic>> _presets = [];

  void _clearFilters() {
    setState(() {
      _distance = 5;
      _price = 500000;
      wheelchair = false;
      noDisability = false;
      shuttle = false;
      noShuttle = false;
      studyRoom = false;
      gym = false;
      pool = false;
      ac = false;
      wifi = false;
      electrical = false;
      guestPolicy = false;
      petFriendly = false;
      program = '';
    });
    HapticFeedback.lightImpact();
  }

  void _savePreset() {
    setState(() {
      _presets.add({
        'distance': _distance,
        'price': _price,
        'wheelchair': wheelchair,
        'noDisability': noDisability,
        'shuttle': shuttle,
        'noShuttle': noShuttle,
        'studyRoom': studyRoom,
        'gym': gym,
        'pool': pool,
        'ac': ac,
        'wifi': wifi,
        'electrical': electrical,
        'guestPolicy': guestPolicy,
        'petFriendly': petFriendly,
        'program': program,
      });
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preset saved!')));
  }

  void _loadPreset(Map<String, dynamic> preset) {
    setState(() {
      _distance = preset['distance'];
      _price = preset['price'];
      wheelchair = preset['wheelchair'];
      noDisability = preset['noDisability'];
      shuttle = preset['shuttle'];
      noShuttle = preset['noShuttle'];
      studyRoom = preset['studyRoom'];
      gym = preset['gym'];
      pool = preset['pool'];
      ac = preset['ac'];
      wifi = preset['wifi'];
      electrical = preset['electrical'];
      guestPolicy = preset['guestPolicy'];
      petFriendly = preset['petFriendly'];
      program = preset['program'];
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String university = args != null && args['university'] != null
        ? args['university']
        : '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: const Text('Search & Filter'),
        leading: BackButton(color: coffeeBrown),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Filters',
            onPressed: _clearFilters,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Preset',
            onPressed: _savePreset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_presets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                children: _presets
                    .map(
                      (preset) => ActionChip(
                        label: Text('Preset'),
                        onPressed: () => _loadPreset(preset),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (_activeFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                children: _activeFilters
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
            ),
          if (university.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Distance from $university',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Distance'),
              Text('${_distance.toStringAsFixed(0)} km'),
            ],
          ),
          Slider(
            value: _distance,
            min: 1,
            max: 20,
            divisions: 19,
            label: '${_distance.toStringAsFixed(0)} km',
            onChanged: (v) => setState(() => _distance = v),
            activeColor: coffeeBrown,
            inactiveColor: lightCoffeeBrown,
            semanticFormatterCallback: (v) => '$v kilometers',
          ),
          const SizedBox(height: 16),
          const Text(
            'Price Range',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Price'), Text(_price.toStringAsFixed(0))],
          ),
          Slider(
            value: _price,
            min: 100000,
            max: 2000000,
            divisions: 19,
            label: _price.toStringAsFixed(0),
            onChanged: (v) => setState(() => _price = v),
            activeColor: coffeeBrown,
            inactiveColor: lightCoffeeBrown,
            semanticFormatterCallback: (v) => '$v Ugandan Shillings',
          ),
          const SizedBox(height: 16),
          const Text(
            'Academic Program',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter program',
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => program = v),
            textInputAction: TextInputAction.done,
            autocorrect: true,
            enableSuggestions: true,
            keyboardType: TextInputType.text,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'Disability Accommodations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CheckboxListTile(
            value: wheelchair,
            onChanged: (v) {
              if (v == true && noDisability) return; // Prevent conflict
              setState(() => wheelchair = v ?? false);
              HapticFeedback.selectionClick();
            },
            title: const Text('Wheelchair Accessible'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.accessible),
          ),
          CheckboxListTile(
            value: noDisability,
            onChanged: (v) {
              if (v == true && wheelchair) return; // Prevent conflict
              setState(() => noDisability = v ?? false);
              HapticFeedback.selectionClick();
            },
            title: const Text('No Disability Accommodations'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.not_accessible),
          ),
          const SizedBox(height: 8),
          const Text(
            'Transportation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CheckboxListTile(
            value: shuttle,
            onChanged: (v) {
              if (v == true && noShuttle) return;
              setState(() => shuttle = v ?? false);
              HapticFeedback.selectionClick();
            },
            title: const Text('Shuttle Service'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.directions_bus),
          ),
          CheckboxListTile(
            value: noShuttle,
            onChanged: (v) {
              if (v == true && shuttle) return;
              setState(() => noShuttle = v ?? false);
              HapticFeedback.selectionClick();
            },
            title: const Text('No Shuttle Service'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.block),
          ),
          const SizedBox(height: 8),
          const Text(
            'Facilities',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CheckboxListTile(
            value: studyRoom,
            onChanged: (v) => setState(() {
              studyRoom = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Study Room'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.menu_book),
          ),
          CheckboxListTile(
            value: gym,
            onChanged: (v) => setState(() {
              gym = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Gym'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.fitness_center),
          ),
          CheckboxListTile(
            value: pool,
            onChanged: (v) => setState(() {
              pool = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Pool'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.pool),
          ),
          CheckboxListTile(
            value: ac,
            onChanged: (v) => setState(() {
              ac = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('A/C'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.ac_unit),
          ),
          CheckboxListTile(
            value: wifi,
            onChanged: (v) => setState(() {
              wifi = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Wi-Fi'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.wifi),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rules & Policies',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          CheckboxListTile(
            value: electrical,
            onChanged: (v) => setState(() {
              electrical = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Electrical Appliances allowed'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.electrical_services),
          ),
          CheckboxListTile(
            value: guestPolicy,
            onChanged: (v) => setState(() {
              guestPolicy = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Guest Policy'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.group),
          ),
          CheckboxListTile(
            value: petFriendly,
            onChanged: (v) => setState(() {
              petFriendly = v ?? false;
              HapticFeedback.selectionClick();
            }),
            title: const Text('Pet-Friendly'),
            activeColor: coffeeBrown,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: const Icon(Icons.pets),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: coffeeBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              onPressed: () {
                // Pass all filters to the results screen
                Navigator.pushNamed(
                  context,
                  '/matching_hostels',
                  arguments: {
                    'distance': _distance,
                    'price': _price,
                    'wheelchair': wheelchair,
                    'noDisability': noDisability,
                    'shuttle': shuttle,
                    'noShuttle': noShuttle,
                    'studyRoom': studyRoom,
                    'gym': gym,
                    'pool': pool,
                    'ac': ac,
                    'wifi': wifi,
                    'electrical': electrical,
                    'guestPolicy': guestPolicy,
                    'petFriendly': petFriendly,
                    'program': program,
                  },
                );
                HapticFeedback.lightImpact();
              },
              child: const Text('Search', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? Colors.brown[900] : Colors.brown[100],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: coffeeBrown,
        unselectedItemColor: lightCoffeeBrown,
        currentIndex: 0,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.house_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
            icon: Icon(Icons.cases_rounded),
            label: "Documents",
          ),
        ],
      ),
    );
  }
}
