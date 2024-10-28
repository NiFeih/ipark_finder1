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
              // Format input: Allow only uppercase letters and numbers, remove symbols and spaces
              String formattedValue = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
              _controller.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(offset: formattedValue.length), // Keep cursor at the end
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newPlateNumber = _controller.text.trim();

                if (newPlateNumber.isNotEmpty) {
                  // Check if the new plate number already exists in Firestore, including the current user's entry
                  QuerySnapshot existingPlateNumbers = await carPlateCollection
                      .where('plateNumber', isEqualTo: newPlateNumber)
                      .get(); // Check for all users

                  // Check if the document ID matches the one being edited to allow the same number
                  bool exists = existingPlateNumbers.docs.any((doc) => doc.id != docId);

                  if (exists) {
                    // Show error if plate number already exists
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("This car plate number already exists.")),
                    );
                  } else {
                    // Update the car plate number
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 40), // Spacer to bring the title lower
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.purple),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  padding: EdgeInsets.only(left: 45.0), // Add padding to shift title slightly to the left
                  child: Text(
                    "Car Plate Numbers",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0), // Additional space below the title
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
                          color: isLocked ? Colors.red : Colors.white,
                          child: ListTile(
                            title: Text(
                              carPlateNumber,
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
