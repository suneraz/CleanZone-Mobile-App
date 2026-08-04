import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _selectedService = 'Regular Cleaning';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _numberOfRooms = 1;
  int _numberOfBathrooms = 1;
  String _flooringType = 'Hardwood';
  List<String> _houseImagePaths = ['', '', ''];
  String _address = ''; // New field for address
  bool _isBooking = false;

  final List<String> _serviceTypes = ['Regular Cleaning', 'Deep Cleaning', 'Window Cleaning'];
  final List<String> _flooringTypes = ['Hardwood', 'Tile', 'Carpet'];
  final Map<String, int> _serviceBasePrices = {
    'Regular Cleaning': 800,
    'Deep Cleaning': 1500,
    'Window Cleaning': 1000,
  };
  final int _additionalRoomPrice = 500;
  final int _baseBathroomPrice = 500;
  final int _additionalBathroomPrice = 800;
  final Map<String, int> _flooringPrices = {
    'Hardwood': 600,
    'Tile': 500,
    'Carpet': 800,
  };

  int calculateTotalPrice() {
    int totalPrice = _serviceBasePrices[_selectedService]!;
    if (_numberOfRooms > 1) {
      totalPrice += (_numberOfRooms - 1) * _additionalRoomPrice;
    }
    totalPrice += _baseBathroomPrice;
    if (_numberOfBathrooms > 1) {
      totalPrice += (_numberOfBathrooms - 1) * _additionalBathroomPrice;
    }
    if (_selectedService != 'Window Cleaning') {
      totalPrice += _flooringPrices[_flooringType]!;
    }
    return totalPrice;
  }

  void _uploadImage(int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload House Image',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 40, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _houseImagePaths[index] = 'assets/house_image_${index + 1}.jpg';
                          });
                        },
                      ),
                      const Text('Camera', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library, size: 40, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _houseImagePaths[index] = 'assets/house_image_${index + 1}.jpg';
                          });
                        },
                      ),
                      const Text('Gallery', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookJob() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to book a job")),
      );
      return;
    }

    int uploadedImages = _houseImagePaths.where((path) => path.isNotEmpty).length;
    if (uploadedImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least one house image")),
      );
      return;
    }

    if (_selectedDate.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a future date for the job")),
      );
      return;
    }

    if (_address.trim().isEmpty) { // Validate address
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an address")),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      dev.log("Booking job for user: ${user.uid}");
      final jobData = {
        'customerId': user.uid,
        'jobType': _selectedService,
        'numberOfRooms': _numberOfRooms,
        'numberOfBathrooms': _numberOfBathrooms,
        'flooringType': _selectedService != 'Window Cleaning' ? _flooringType : null,
        'houseImages': _houseImagePaths,
        'date': _selectedDate.toIso8601String(),
        'time': "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
        'address': _address, // Add address to job data
        'totalPrice': calculateTotalPrice(),
        'status': 'available',
        'createdAt': Timestamp.now(),
        'cleanerId': null,
      };

      await _firestore.collection('jobs').add(jobData);
      dev.log("Job booked successfully");

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Booking Confirmed",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your $_selectedService has been scheduled for ${_selectedDate.toLocal()}".split(' ')[0] +
                    " at ${_selectedTime.format(context)}",
              ),
              Text("Address: $_address"), // Display address in confirmation
              const SizedBox(height: 10),
              const Text("House Details:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Rooms: $_numberOfRooms"),
              Text("Bathrooms: $_numberOfBathrooms"),
              if (_selectedService != 'Window Cleaning') Text("Flooring: $_flooringType"),
              Text("Pictures: $uploadedImages uploaded"),
              const SizedBox(height: 10),
              Text(
                "Total Price: ${calculateTotalPrice()} LKR",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      dev.log("Error booking job: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to book job: $e")),
      );
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = calculateTotalPrice();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          "Select Service Type",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedService,
                        underline: Container(),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        items: _serviceTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedService = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "House Details",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(child: Text("Number of Rooms", style: TextStyle(fontSize: 16))),
                          DropdownButton<int>(
                            value: _numberOfRooms,
                            underline: Container(),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            items: List.generate(10, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                            onChanged: (value) {
                              setState(() {
                                _numberOfRooms = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(child: Text("Number of Bathrooms", style: TextStyle(fontSize: 16))),
                          DropdownButton<int>(
                            value: _numberOfBathrooms,
                            underline: Container(),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            items: List.generate(5, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                            onChanged: (value) {
                              setState(() {
                                _numberOfBathrooms = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_selectedService != 'Window Cleaning')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(child: Text("Flooring Type", style: TextStyle(fontSize: 16))),
                            DropdownButton<String>(
                              value: _flooringType,
                              underline: Container(),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              items: _flooringTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _flooringType = value!;
                                });
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload House Pictures",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(3, (index) {
                          return GestureDetector(
                            onTap: () => _uploadImage(index),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange, width: 1.5),
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.orange[50],
                              ),
                              child: _houseImagePaths[index].isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.asset(_houseImagePaths[index], fit: BoxFit.cover),
                              )
                                  : Icon(Icons.add_a_photo, color: Colors.orange[400], size: 50),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Schedule",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Date:", style: TextStyle(fontSize: 16)),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: Text(
                              "${_selectedDate.toLocal()}".split(' ')[0],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Time:", style: TextStyle(fontSize: 16)),
                          TextButton(
                            onPressed: () => _selectTime(context),
                            child: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _address = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pricing Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Service Type:", style: TextStyle(fontSize: 16)),
                          Text(
                            "${_selectedService}: ${_serviceBasePrices[_selectedService]} LKR",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Rooms:", style: TextStyle(fontSize: 16)),
                          Text(
                            "$_numberOfRooms (${_numberOfRooms > 1 ? '1 + ${_numberOfRooms - 1} extra' : '1'}) : ${_numberOfRooms > 1 ? '0 + ${(_numberOfRooms - 1) * _additionalRoomPrice}' : '0'} LKR",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Bathrooms:", style: TextStyle(fontSize: 16)),
                          Text(
                            "$_numberOfBathrooms ($_baseBathroomPrice + ${_numberOfBathrooms > 1 ? '${(_numberOfBathrooms - 1) * _additionalBathroomPrice}' : '0'}) LKR",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_selectedService != 'Window Cleaning') ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Flooring:", style: TextStyle(fontSize: 16)),
                            Text(
                              "$_flooringType: ${_flooringPrices[_flooringType]} LKR",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const Divider(thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            "$totalPrice LKR",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 90),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  onPressed: _isBooking ? null : _bookJob,
                  child: _isBooking
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      : const Text(
                    "Book Cleaning Service",
                    style: TextStyle(fontSize: 17, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}