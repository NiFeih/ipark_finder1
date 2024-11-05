import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'add_car_plate_page.dart';

class CarPlateNumberPage extends StatefulWidget {
  @override
  _CarPlateNumberPageState createState() => _CarPlateNumberPageState();
}

class _CarPlateNumberPageState extends State<CarPlateNumberPage> {
  final CollectionReference carPlateCollection =
  FirebaseFirestore.instance.collection('CarPlateNumbers');

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  void _deleteCarPlate(String docId, String carPlateNumber) async {
    // Check if user has more than one car plate number
    QuerySnapshot userCarPlates = await carPlateCollection
        .where('userId', isEqualTo: userId)
        .get();

    if (userCarPlates.docs.length <= 1) {
      // Show warning dialog if this is the only car plate number
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Cannot Delete"),
            content: Text("You must have at least one car plate number."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show confirmation dialog to delete car plate number
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Car Plate Number?"),
          content: Text("Are you sure you want to delete $carPlateNumber?"), // Update content
          actions: [
            TextButton(
              onPressed: () {
                carPlateCollection.doc(docId).delete().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Car Plate Number Deleted")),
                  );
                  Navigator.of(context).pop();
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete car plate number: $error")),
                  );
                });
              },
              child: Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }



  void _editCarPlate(String docId, String currentPlateNumber) {
    TextEditingController _controller = TextEditingController(text: currentPlateNumber);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Car Plate Number"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: "Car Plate Number"),
            onChanged: (value) {
              String formattedValue = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
              _controller.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(offset: formattedValue.length),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newPlateNumber = _controller.text.trim();

                if (newPlateNumber.isNotEmpty) {
                  QuerySnapshot existingPlateNumbers = await carPlateCollection
                      .where('plateNumber', isEqualTo: newPlateNumber)
                      .get();

                  bool exists = existingPlateNumbers.docs.any((doc) => doc.id != docId);

                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("This car plate number already exists.")),
                    );
                  } else {
                    carPlateCollection.doc(docId).update({
                      'plateNumber': newPlateNumber,
                    }).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Car Plate Number Updated")),
                      );
                      Navigator.of(context).pop();
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to update: $error")),
                      );
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a valid car plate number")),
                  );
                }
              },
              child: Text("Confirm"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showClampedWarning() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Warning"),
          content: Text("Your car has been clamped. Please head to the AFM to unclamp your car."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("How to Use"),
          content: Text(
            "• To edit a car plate number, swipe the item left and select 'Edit'.\n"
                "• To delete a car plate number, swipe the item left and select 'Delete'.\n"
                "• If a car is clamped, the plate number will appear in red with 'Clamped' appended.",
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Car Plate Numbers"),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            userId == null
                ? Center(child: Text("No user logged in"))
                : Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: carPlateCollection.where('userId', isEqualTo: userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No car plate numbers found."));
                  }

                  final carPlateNumbers = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: carPlateNumbers.length,
                    itemBuilder: (context, index) {
                      final carPlateDoc = carPlateNumbers[index];
                      final carPlateNumber = carPlateDoc['plateNumber'];
                      final docId = carPlateDoc.id;
                      final bool isLocked = carPlateDoc['lock'] ?? false;
                      final displayPlateNumber =
                      isLocked ? "$carPlateNumber (Clamped)" : carPlateNumber;

                      return Slidable(
                        key: ValueKey(docId),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                if (isLocked) {
                                  _showClampedWarning();
                                } else {
                                  _editCarPlate(docId, carPlateNumber);
                                }
                              },
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                if (isLocked) {
                                  _showClampedWarning();
                                } else {
                                  _deleteCarPlate(docId, carPlateNumber); // Pass carPlateNumber here
                                }
                              },
                              icon: Icons.delete,
                              label: 'Delete',
                            ),

                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.all(8.0),
                          color: isLocked ? Colors.red : Colors.white,
                          child: ListTile(
                            title: Text(
                              displayPlateNumber,
                              style: TextStyle(
                                color: isLocked ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text("User ID: ${carPlateDoc['userId']}"),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCarPlateNumberPage()),
          ).then((_) {
            setState(() {});
          });
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
    );
  }
}
