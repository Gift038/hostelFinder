import 'package:flutter/material.dart';
import '../home/tenants_dashboard.dart';
import '../home/managers_dashboard.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class RegisterAccountScreen extends StatefulWidget {
  const RegisterAccountScreen({super.key});

  @override
  State<RegisterAccountScreen> createState() => _RegisterAccountScreenState();
}

class _RegisterAccountScreenState extends State<RegisterAccountScreen> {
  final Color coffeeBrown = const Color(0xFF4B2E05);
  final Color lightCoffeeBrown = const Color(0xFF9C7A5F);
  final Color tan = const Color(0xFFD7BFA6);

  int _step = 0;
  String _role = 'Tenant';
  String _name = '';
  String _gender = '';
  String _contact = '';
  String _school = '';
  String _programme = '';
  String _yearOfStudy = '';
  String _hostelManaged = '';

  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_formKey.currentState?.validate() ?? false) {
      // Submit or proceed
    }
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F2),
        foregroundColor: coffeeBrown,
        title: const Text('Register Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: coffeeBrown.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _step == 0 ? _roleStep() : _detailsStep(),
          ),
        ),
      ),
    );
  }

  Widget _roleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.account_circle, color: coffeeBrown, size: 48),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Register as:',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown),
          ),
        ),
        const SizedBox(height: 32),
        _RoleButton(
          label: 'Tenant',
          selected: _role == 'Tenant',
          onTap: () => setState(() {
            _role = 'Tenant';
            _step = 1;
          }),
          coffeeBrown: coffeeBrown,
          lightCoffeeBrown: lightCoffeeBrown,
        ),
        const SizedBox(height: 16),
        _RoleButton(
          label: 'Hostel Manager',
          selected: _role == 'Hostel Manager',
          onTap: () => setState(() {
            _role = 'Hostel Manager';
            _step = 1;
          }),
          coffeeBrown: coffeeBrown,
          lightCoffeeBrown: lightCoffeeBrown,
        ),
      ],
    );
  }

  Widget _detailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.person_add_alt_1, color: coffeeBrown, size: 48),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Enter your details',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: coffeeBrown),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: Icon(Icons.person, color: lightCoffeeBrown),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: coffeeBrown, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
            onChanged: (v) => _name = v,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: Icon(Icons.wc, color: lightCoffeeBrown),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: coffeeBrown, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) => _gender = v ?? '',
            validator: (v) => v == null || v.isEmpty ? 'Select gender' : null,
            dropdownColor: Colors.white,
            iconEnabledColor: coffeeBrown,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Contact (Email or Phone)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: Icon(Icons.contact_mail, color: lightCoffeeBrown),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: coffeeBrown, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter contact info' : null,
            onChanged: (v) => _contact = v,
          ),
          if (_role == 'Tenant') ...[
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'School',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.school, color: lightCoffeeBrown),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter your school' : null,
              onChanged: (v) => _school = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Programme of Study',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.menu_book, color: lightCoffeeBrown),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter your programme' : null,
              onChanged: (v) => _programme = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Year of Study',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.calendar_today, color: lightCoffeeBrown),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter your year of study' : null,
              onChanged: (v) => _yearOfStudy = v,
            ),
          ],
          if (_role == 'Hostel Manager') ...[
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Name of Hostel Managed',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.home_work, color: lightCoffeeBrown),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: coffeeBrown, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter name of hostel managed' : null,
              onChanged: (v) => _hostelManaged = v,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _prevStep,
                style: TextButton.styleFrom(foregroundColor: coffeeBrown),
                child: const Text('Back'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: coffeeBrown,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Provider.of<UserProvider>(context, listen: false).setUser(
                      name: _name,
                      contact: _contact,
                      gender: _gender,
                      email: _contact, // or use a separate email field if available
                      school: _role == 'Tenant' ? _school : '',
                      programme: _role == 'Tenant' ? _programme : '',
                      yearOfStudy: _role == 'Tenant' ? _yearOfStudy : '',
                    );
                    if (_role == 'Tenant') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => TenantsDashboardScreen()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ManagerDashboard()),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color coffeeBrown;
  final Color lightCoffeeBrown;

  const _RoleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.coffeeBrown,
    required this.lightCoffeeBrown,
  });

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.selected ? widget.coffeeBrown : widget.lightCoffeeBrown;
    final Color hoverColor = widget.coffeeBrown;
    final Color textColor = widget.selected || _isHovering ? Colors.white : widget.coffeeBrown;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovering ? hoverColor : baseColor,
            foregroundColor: textColor,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: widget.selected ? 4 : 1,
          ),
          onPressed: widget.onTap,
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
} 