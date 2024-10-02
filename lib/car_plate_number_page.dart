import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter_slidable/flutter_slidable.dart'; // Import Slidable package
import 'add_car_plate_page.dart'; // Import the separated add car plate page

class CarPlateNumberPage extends StatefulWidget {
  @override
  _CarPlateNumberPageState createState() => _CarPlateNumberPageState();
}

class _CarPlateNumberPageState extends State<CarPlateNumberPage> {
  // Reference to the Firestore collection
  final CollectionReference carPlateCollection =
  FirebaseFirestore.instance.collection('CarPlateNumbers');

  // Get the current logged-in user's uid
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  void _deleteCarPlate(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Car Plate Number?"),
          content: Text("Are you sure you want to delete this car plate number?"),
          actions: [
            TextButton(
              onPressed: () {
                carPlateCollection.doc(docId).delete().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Car Plate Number Deleted")),
                  );
                  Navigator.of(context).pop(); // Close the dialog
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
                Navigator.of(context).pop(); // Close the dialog without deleting
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                String newPlateNumber = _controller.text.trim();
                if (newPlateNumber.isNotEmpty) {
                  carPlateCollection.doc(docId).update({
                    'plateNumber': newPlateNumber,
                  }).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Car Plate Number Updated")),
                    );
                    Navigator.of(context).pop(); // Close the dialog
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update: $error")),
                    );
                  });
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
                Navigator.of(context).pop(); // Close the dialog without saving
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
                Navigator.of(context).pop(); // Close the dialog
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
        backgroundColor: Colors.purple,
      ),
      body: userId == null
          ? Center(child: Text("No user logged in"))
          : StreamBuilder<QuerySnapshot>(
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
              final bool isLocked = carPlateDoc['lock'] ?? false; // Check lock field

              return Slidable(
                key: ValueKey(docId),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        if (isLocked) {
                          _showClampedWarning(); // Show warning if locked
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
                          _showClampedWarning(); // Show warning if locked
                        } else {
                          _deleteCarPlate(docId);
                        }
                      },
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  color: isLocked ? Colors.red : Colors.white, // Set background color based on lock field
                  child: ListTile(
                    title: Text(
                      carPlateNumber,
                      style: TextStyle(
                        color: isLocked ? Colors.white : Colors.black, // Set text color based on lock field
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
