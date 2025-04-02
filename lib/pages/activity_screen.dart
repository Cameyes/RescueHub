import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

class ActivityScreen extends StatefulWidget {
  final String userId;
  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {

  void _startDeletionTimer(Map<String, dynamic> activity, BuildContext context) {
  int secondsLeft = 7;
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (secondsLeft == 0) {
      timer.cancel();
      try {
        // Use a batch to delete both documents atomically
        final batch = FirebaseFirestore.instance.batch();
        
        // Delete activity
        batch.delete(
          FirebaseFirestore.instance
              .collection('userFoodActivities')
              .doc(widget.userId)
        );

        // Delete food item
        final foodQuery = await FirebaseFirestore.instance
            .collection('food')
            .where('foodId', isEqualTo: activity['foodId'])
            .get();
            
        if (foodQuery.docs.isNotEmpty) {
          batch.delete(foodQuery.docs.first.reference);
        }

        // Delete from adminFoodDetails
        final adminFoodQuery = await FirebaseFirestore.instance
            .collection('adminFoodDetails')
            .where('foodDetails.foodId', isEqualTo: activity['foodId'])
            .get();

        if (adminFoodQuery.docs.isNotEmpty) {
          batch.delete(adminFoodQuery.docs.first.reference);
        }

        await batch.commit();
      }
      catch (e) {
        print('Error deleting documents: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      secondsLeft--;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity will be deleted in $secondsLeft seconds'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  });
}



  Future<void> _showReviewDialog(String shelterId) async {
    // Check if user has already reviewed
    final existingReview = await FirebaseFirestore.instance
        .collection('shelter')
        .doc(shelterId)
        .collection('reviews')
        .where('userId', isEqualTo: widget.userId)
        .get();

    if (existingReview.docs.isNotEmpty) {
      if (context.mounted) {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('End Stay', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to end your stay?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final batch = FirebaseFirestore.instance.batch();
                    
                    // Update shelter status
                    batch.update(
                      FirebaseFirestore.instance.collection('shelter').doc(shelterId),
                      {'status': 'not booked'}
                    );
                    // Delete activity record
                    batch.delete(
                      FirebaseFirestore.instance.collection('userActivities').doc(widget.userId)
                    );

                     // Delete from adminShelterDetails - Fix: Get the correct document ID
                      final adminShelterDoc = await FirebaseFirestore.instance
                          .collection('adminShelterDetails')
                          .where('shelterDetails.shelterId', isEqualTo: shelterId)
                          .limit(1)
                          .get();
                          
                      if (adminShelterDoc.docs.isNotEmpty) {
                        batch.delete(adminShelterDoc.docs.first.reference);
                      }

                    // Commit the batch
                    await batch.commit();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stay ended successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error ending stay: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error ending stay: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('End Stay'),
              ),
            ],
          ),
        );
      }
      return;
    }

    int rating = 5;
    final reviewController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Rate Your Stay',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () => setState(() => rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      labelText: 'Write your review',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                      ),
                      hintText: 'Share your experience...',
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Use a batch to ensure atomic operations
                final batch = FirebaseFirestore.instance.batch();
                
                // Reference to the review document
                final reviewRef = FirebaseFirestore.instance
                    .collection('shelter')
                    .doc(shelterId)
                    .collection('reviews')
                    .doc();

                // Add review
                batch.set(reviewRef, {
                  'rating': rating,
                  'reviewText': reviewController.text,
                  'userId': widget.userId,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Update shelter status
                batch.update(
                  FirebaseFirestore.instance.collection('shelter').doc(shelterId),
                  {'status': 'not booked'}
                );

                // Delete activity record
                batch.delete(
                  FirebaseFirestore.instance.collection('userActivities').doc(widget.userId)
                );

                // Delete from adminShelterDetails - Fix: Get the correct document ID
                  final adminShelterDoc = await FirebaseFirestore.instance
                      .collection('adminShelterDetails')
                      .where('shelterDetails.shelterId', isEqualTo: shelterId)
                      .limit(1)
                      .get();
                      
                  if (adminShelterDoc.docs.isNotEmpty) {
                    batch.delete(adminShelterDoc.docs.first.reference);
                  }

                // Commit the batch
                await batch.commit();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your review!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                print('Error submitting review: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error submitting review: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }


  // Add this method alongside other methods in _ActivityScreenState
Future<void> _showFoodReviewDialog(String donorId) async {

  // Check for existing review
  final existingReview = await FirebaseFirestore.instance
      .collection('Profile')
      .doc(donorId)
      .collection('foodReviews')
      .where('userId', isEqualTo: widget.userId)
      .get();

      if (existingReview.docs.isNotEmpty) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Already Reviewed'),
          content: const Text(
            'You have already submitted a review for this donor. '
            'This activity will be automatically deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // Start deletion timer
      _startDeletionTimer({'donorId': donorId}, context);
    }
    return;
  }



  int rating = 5;
  final reviewController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Rate the Food',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How was the food quality?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setState(() => rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: reviewController,
                  decoration: InputDecoration(
                    labelText: 'Write your review',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    hintText: 'Share your experience with the food...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          );
        },
      ),
      actions: [
       TextButton(
          onPressed: () async {
            // Delete activity on skip
            await FirebaseFirestore.instance
                .collection('userFoodActivities')
                .doc(widget.userId)
                .delete();
                
            if (context.mounted) {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Activity skipped and deleted",
                backgroundColor: Colors.orange,
                textColor: Colors.white,
              );
            }
          },
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              // Use a batch to ensure atomic operations
              final batch = FirebaseFirestore.instance.batch();
              
              // Add review to Profile/foodReviews subcollection
              final reviewRef = FirebaseFirestore.instance
                  .collection('Profile')
                  .doc(donorId)
                  .collection('foodReviews')
                  .doc();

              // Add review
              batch.set(reviewRef, {
                'rating': rating,
                'reviewText': reviewController.text,
                'userId': widget.userId,
                'timestamp': FieldValue.serverTimestamp(),
                'donorId': donorId,
                
              });

              // Delete food activity record
              batch.delete(
                FirebaseFirestore.instance.collection('userFoodActivities').doc(widget.userId)
              );

              // Commit the batch
              await batch.commit();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your review!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              print('Error submitting food review: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error submitting review: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

void _startAmbulanceActivityDeletionTimer(BuildContext context) {
  int secondsLeft = 5;
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (secondsLeft == 0) {
      timer.cancel();
      try {
        // Get the first document from userAmbulanceActivities
        final querySnapshot = await FirebaseFirestore.instance
            .collection('userAmbulanceActivities')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final activityDoc = querySnapshot.docs.first;
          final activityData = activityDoc.data();

          // Use a batch write for atomic operations
          final batch = FirebaseFirestore.instance.batch();

          // Delete from userAmbulanceActivities
          batch.delete(activityDoc.reference);

          // Find and delete from adminAmbulanceDetails
          final adminQuerySnapshot = await FirebaseFirestore.instance
              .collection('adminAmbulanceDetails')
              .where('requesterDetails.userId', isEqualTo: widget.userId)
              .limit(1)
              .get();

          if (adminQuerySnapshot.docs.isNotEmpty) {
            batch.delete(adminQuerySnapshot.docs.first.reference);
          }

          // Commit the batch
          await batch.commit();
        }
      } catch (e) {
        print('Error deleting ambulance activity: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      secondsLeft--;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity will be deleted in $secondsLeft seconds'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  });
}

// Then update the _showDriverReviewDialog method
Future<void> _showDriverReviewDialog(String driverId) async {
  // Check for existing review
  final existingReview = await FirebaseFirestore.instance
      .collection('Profile')
      .doc(driverId)
      .collection('ambulanceReviews')
      .where('userId', isEqualTo: widget.userId)
      .get();

  if (existingReview.docs.isNotEmpty) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Already Reviewed'),
          content: const Text(
            'You have already submitted a review for this driver. '
            'This activity will be automatically deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _startAmbulanceActivityDeletionTimer(context);
    }
    return;
  }

  int rating = 5;
  final reviewController = TextEditingController();

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Rate Driver Service',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How was your experience with the driver?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setState(() => rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: reviewController,
                  decoration: InputDecoration(
                    labelText: 'Write your review',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    hintText: 'Share your experience with the driver...',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          );
        },
      ),
      // Update the actions section of _showDriverReviewDialog
actions: [
  TextButton(
    onPressed: () async {
      Navigator.pop(context);
      // Get and delete the first document
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userAmbulanceActivities')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
      
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: "Activity skipped and deleted",
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    },
    child: const Text('Skip'),
  ),
  ElevatedButton(
    onPressed: () async {
      try {
        // Get the first document reference
        final querySnapshot = await FirebaseFirestore.instance
            .collection('userAmbulanceActivities')
            .limit(1)
            .get();

        // Add review to Profile/ambulanceReviews subcollection
        await FirebaseFirestore.instance
            .collection('Profile')
            .doc(driverId)
            .collection('ambulanceReviews')
            .add({
              'rating': rating,
              'reviewText': reviewController.text,
              'userId': widget.userId,
              'timestamp': FieldValue.serverTimestamp(),
            });

        // Delete the first document if it exists
        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.delete();
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your review!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error submitting driver review: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting review: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: const Text('Submit'),
  ),
],
    ),
  );
}


Widget _buildAmbulanceActivityCard(Map<String, dynamic> activity, bool isDarkMode) {
  final primaryColor = isDarkMode ? Colors.teal : Colors.blue;
  
  return Column(
    children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AMBULANCE SERVICE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Driver: ${activity['driverName']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Service Completed",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              _buildDetailRow(
                context,
                icon: Icons.location_on_outlined,
                title: 'Hospital Address',
                value: activity['hospitalAddress'] ?? 'Hospital Location',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                icon: Icons.person_outline,
                title: 'Driver ID',
                value: activity['driverId'] ?? 'N/A',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showDriverReviewDialog(activity['driverId']),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 237, 237, 5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star),
                SizedBox(width: 8),
                Text(
                  'Rate Driver',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

  // Add this widget after the _buildDetailRow method
Widget _buildFoodActivityCard(Map<String, dynamic> activity, bool isDarkMode) {
  final primaryColor = isDarkMode ? Colors.teal : Colors.blue;
  
  return Column(
    children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fastfood_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                   const SizedBox(width: 8),
                  Text(
                    'FOOD DELIVERY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activity['foodName'] ?? 'Food Item',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
               const SizedBox(height: 16),
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children:[Text(
                  "Delivered",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.green, size: 18,)
                ],),
                 ),
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 24),
       Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              _buildDetailRow(
                context,
                icon: Icons.location_on_outlined,
                title: 'Delivery Address',
                value: activity['foodAddress'] ?? 'Delivery Location',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                icon: Icons.numbers,
                title: 'Food ID',
                value: activity['foodId'] ?? 'N/A',
                isDarkMode: isDarkMode,
                 ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      if (activity['photos'] != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Food Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
             const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: (activity['photos'] as List).length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          activity['photos'][index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                                 ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showFoodReviewDialog(activity['donorId']),
          style: ElevatedButton.styleFrom(
            backgroundColor:  Color.fromARGB(255, 237, 237, 5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star),
              SizedBox(width: 8),
              Text(
                'Rate Food',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


 @override
Widget build(BuildContext context) { 
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDarkMode = themeProvider.isDarkMode;
  final primaryColor = isDarkMode ? Colors.teal : Colors.blue;

  return Scaffold(
    backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
    appBar: AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        "Your Activity",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userActivities')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, shelterActivitySnapshot) {
        if (!shelterActivitySnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        final shelterActivity = shelterActivitySnapshot.data?.data() as Map<String, dynamic>?;

        // Nested StreamBuilder for food activities
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('userFoodActivities')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, foodActivitySnapshot) {
            if (!foodActivitySnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            final foodActivity = foodActivitySnapshot.data?.data() as Map<String, dynamic>?;

            // Nested StreamBuilder for ambulance activities
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('userAmbulanceActivities')
                  .limit(1)
                  .snapshots(),
              builder: (context, ambulanceActivitySnapshot) {
                if (!ambulanceActivitySnapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }

                 final ambulanceActivity = ambulanceActivitySnapshot.data?.docs.isNotEmpty == true
        ? ambulanceActivitySnapshot.data!.docs.first.data() as Map<String, dynamic>
        : null;

                // If no activities at all
                if (shelterActivity == null && foodActivity == null && ambulanceActivity == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No activity at Present!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Book a resource or request food to see your activity here',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Determine which activity to show based on priority
                // Priority: Ambulance > Food > Shelter
                Widget activityWidget;
                if (ambulanceActivity != null) {
                  activityWidget = _buildAmbulanceActivityCard(ambulanceActivity, isDarkMode);
                } else if (foodActivity != null) {
                  activityWidget = _buildFoodActivityCard(foodActivity, isDarkMode);
                } else {
                  activityWidget = _buildShelterActivityCard(shelterActivity!, isDarkMode);
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: activityWidget,
                  ),
                );
              },
            );
          },
        );
      },
    ),
  );
}

  Widget _buildShelterActivityCard(Map<String, dynamic> activity, bool isDarkMode) {
  final primaryColor = isDarkMode ? Colors.teal : Colors.blue;
  final endDate = (activity['expectedEndDate'] as Timestamp).toDate();
  final daysLeft = endDate.difference(DateTime.now()).inDays;
  final startDate = (activity['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
  final dateFormat = DateFormat('MMM dd, yyyy');
  final formattedStartDate = dateFormat.format(startDate);
  final formattedEndDate = dateFormat.format(endDate);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Status card with gradient background
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CURRENT STAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activity['shelterName'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$daysLeft days remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 24),
      
      // Shelter details section
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shelter Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              _buildDetailRow(
                context,
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: activity['shelterAddress'],
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                icon: Icons.calendar_today_outlined,
                title: 'Stay Period',
                value: '$formattedStartDate - $formattedEndDate',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 24),
      
      // Photos section
      if (activity['photos'] != null && (activity['photos'] as List).isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: (activity['photos'] as List).length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          activity['photos'][index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      
      const SizedBox(height: 32),
      
      // End Stay button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showReviewDialog(activity['shelterId']),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app),
              SizedBox(width: 8),
              Text(
                'End Stay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}