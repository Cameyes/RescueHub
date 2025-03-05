import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   // ========================== USER PROFILE ==========================

  // Fetch User Profile by userId
  Future<DocumentSnapshot?> getUserProfile(String userId) async {
  try {
    // Fetch user document from Firestore
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
    
    if (userDoc.exists) {
      // Get the document data as a Map
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData != null && userData.containsKey('email') && userData.containsKey('name') && userData.containsKey('role')) {
        print("User profile found: $userData"); // Log the data for debugging
        return userDoc;
      } else {
        print("User profile is missing required fields.");
        return null;
      }
    } else {
      print("User profile not found for ID: $userId");
      return null;
    }
  } catch (e) {
    print("Error fetching user profile: $e");
    return null;
  }
}

 // For Main Review page
 Future addToMainReviews(String reviewerId, String resourceId, String resourceType, Map<String, dynamic> reviewData) async {
  try {
    await _firestore.collection("Reviews").add({
      ...reviewData,
      'reviewerId': reviewerId,
      'resourceId': resourceId, 
      'resourceType': resourceType, // 'shelter', 'food', or 'cloth'
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print("Error adding to main reviews: $e");
    rethrow;
  }
}
  //FOR PROFILE

  //Create Method
  Future addprofileDetails(Map<String, dynamic> profileInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("profile")
        .doc(id)
        .set(profileInfoMap);
  }
  //Read Method
  Future<Stream<QuerySnapshot>> getprofileDetails({String? searchQuery}) async {
    Query query = FirebaseFirestore.instance.collection("profile");
    
    // If search query is provided, add a search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      //searchQuery=searchQuery.toLowerCase();//converting to lowercase so that case sensitivity won't hinder the search operation
      query = query.where('Name', isGreaterThanOrEqualTo: searchQuery)
                   .where('Name', isLessThan: '${searchQuery}z');
    }
    
    return query.snapshots();
  }

  // Update Method
  Future updateprofileDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("profile")
        .doc(id)
        .update(updateInfo);
  }




  Future<Map<String, dynamic>> getUserAggregateReviews(String userId) async {
    try {
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection("Reviews")
          .where('reviewerId', isEqualTo: userId)
          .get();

      Map<String, List<int>> ratings = {
        'shelter': [],
        'food': [],
        'cloth': []
      };

      for (var doc in reviewsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String type = data['resourceType'];
        int rating = data['rating'] ?? 0;
        
        if (ratings.containsKey(type)) {
          ratings[type]!.add(rating);
        }
      }

      // Calculate averages
      Map<String, double> averages = {};
      ratings.forEach((key, values) {
        if (values.isEmpty) {
          averages[key] = 0.0;
        } else {
          double avg = values.reduce((a, b) => a + b) / values.length;
          averages[key] = double.parse(avg.toStringAsFixed(1));
        }
      });

      return {
        'averageRatings': averages,
        'totalReviews': reviewsSnapshot.docs.length,
      };
    } catch (e) {
      print("Error getting user aggregate reviews: $e");
      return {
        'averageRatings': {'shelter': 0.0, 'food': 0.0, 'cloth': 0.0},
        'totalReviews': 0,
      };
    }
  }

  //FOR SHELTERS

  // Create Method
  Future addshelterDetails(Map<String, dynamic> shelterInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("shelter")
        .doc(id)
        .set(shelterInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getshelterDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("shelter")
      .where("Location", isEqualTo: location)
      //.orderBy('distance', descending: false) // Sort by distance
      .snapshots();
}

  // Update Method
  Future updateshelterDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("shelter")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deleteshelterDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("shelter")
        .doc(id)
        .delete();
  }
  // Sorting method
  Future<Stream<QuerySnapshot>> getSortedshelterDetails(String sortBy) async{
    Query query = FirebaseFirestore.instance.collection("shelter");
       //add Sorting method on the selected field
       query=query.orderBy(sortBy,descending: false);
       return query.snapshots();
  }
  
  //For Shelter Reviews

  // Add a review to the "reviews" subcollection of a specific shelter
Future addReview(String shelterId, Map<String, dynamic> reviewData) async {
  try {
    await _firestore
        .collection("shelter")
        .doc(shelterId)
        .collection("reviews")
        .add(reviewData);

        // Add to main Reviews collection
    await addToMainReviews(
      reviewData['userId'],
      shelterId,
      'shelter',
      reviewData
    );
    print("Review added successfully!");
  } catch (e) {
    print("Error adding review: $e");
    rethrow;
  }
}

// Get all reviews for a specific shelter
Future<Stream<QuerySnapshot>> getReviews(String shelterId) async {
  try {
    return _firestore
        .collection("shelter")
        .doc(shelterId)
        .collection("reviews")
        .orderBy('timestamp', descending: true)
        .snapshots();
  } catch (e) {
    print("Error fetching reviews: $e");
    rethrow;
  }
}

// Delete a specific review by its ID
Future deleteReview(String shelterId, String reviewId) async {
  try {
    await _firestore
        .collection("shelter")
        .doc(shelterId)
        .collection("reviews")
        .doc(reviewId)
        .delete();
    print("Review deleted successfully!");
  } catch (e) {
    print("Error deleting review: $e");
    rethrow;
  }
}


   //FOR Food

  
  // Create Method
  Future addfoodDetails(Map<String, dynamic> foodInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("food")
        .doc(id)
        .set(foodInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getfoodDetails({String? location, String? searchQuery}) async {
  Query query = FirebaseFirestore.instance.collection("food");
  
  // Apply location filter if provided
  if (location != null && location.isNotEmpty) {
    query = query.where("Location", isEqualTo: location);
  }
  
   if (searchQuery != null && searchQuery.isNotEmpty) {
      //searchQuery=searchQuery.toLowerCase();//converting to lowercase so that case sensitivity won't hinder the search operation
      query = query.where('FoodName', isGreaterThanOrEqualTo: searchQuery.toLowerCase())
             .where('FoodName', isLessThan: '${searchQuery.toLowerCase()}z');
    }
  
  return query.snapshots();
}

  // Update Method
  Future updatefoodDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("food")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deletefoodDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("food")
        .doc(id)
        .delete();
  }

  //method to check and delete expired food items
  Future<void> checkAndDeleteExpiredFood() async {
    try {
      final DateTime currentDate = DateTime.now();
      
      // Query for expired food items
      QuerySnapshot foodSnapshot = await FirebaseFirestore.instance
          .collection('food')
          .get();
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      bool hasExpiredItems = false;
      List<String> deletedFoodNames = [];
      
      for (DocumentSnapshot doc in foodSnapshot.docs) {
        // Convert stored timestamp to DateTime
        DateTime expiryDate = (doc['Expirty-Date'] as Timestamp).toDate();
        
        if (currentDate.isAfter(expiryDate)) {
          batch.delete(doc.reference);
          hasExpiredItems = true;
          deletedFoodNames.add(doc['FoodName'] ?? 'Unknown Food Item');
        }
      }
      
      if (hasExpiredItems) {
        await batch.commit();
        print('Deleted expired food items: ${deletedFoodNames.join(", ")}');
      }
      
      return;
    } catch (e) {
      print('Error deleting expired food: $e');
      rethrow;
    }
  }

  //For Food Reviews

  // Add a review to the "reviews" subcollection of a specific shelter
Future addfoodReview(String shelterId, Map<String, dynamic> reviewData) async {
  try {
    await _firestore
        .collection("food")
        .doc(shelterId)
        .collection("reviews")
        .add(reviewData);

        // Add to main Reviews collection
    await addToMainReviews(
      reviewData['userId'],
      shelterId,
      'food',
      reviewData
    );

    print("Review added successfully!");
  } catch (e) {
    print("Error adding review: $e");
    rethrow;
  }
}

// Get all reviews for a specific shelter
Future<Stream<QuerySnapshot>> getfoodReviews(String shelterId) async {
  try {
    return _firestore
        .collection("food")
        .doc(shelterId)
        .collection("reviews")
        .orderBy('timestamp', descending: true)
        .snapshots();
  } catch (e) {
    print("Error fetching reviews: $e");
    rethrow;
  }
}

// Delete a specific review by its ID
Future deletefoodReview(String shelterId, String reviewId) async {
  try {
    await _firestore
        .collection("food")
        .doc(shelterId)
        .collection("reviews")
        .doc(reviewId)
        .delete();
    print("Review deleted successfully!");
  } catch (e) {
    print("Error deleting review: $e");
    rethrow;
  }
}

  //FOR Cloth

  
  // Create Method
  Future addclothDetails(Map<String, dynamic> clothInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("cloth")
        .doc(id)
        .set(clothInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getclothDetails({String? location, String? searchQuery}) async {
  Query query = FirebaseFirestore.instance.collection("cloth");
  
  // Apply location filter if provided
  if (location != null && location.isNotEmpty) {
    query = query.where("Location", isEqualTo: location);
  }
  
  // Apply search filter if provided
  if (searchQuery != null && searchQuery.isNotEmpty) {
    // Convert to lowercase for case-insensitive search
    String searchLower = searchQuery.toLowerCase();
    
    // Search in name field (assuming you have a 'Name' field)
    query = query.where('ClothName', isGreaterThanOrEqualTo: searchLower)
                 .where('ClothName', isLessThan: '${searchLower}z');
  }
  
  return query.snapshots();
}

  // Update Method
  Future updateclothDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("cloth")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deleteclothDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("cloth")
        .doc(id)
        .delete();
  }

  //For cloth Reviews

  // Add a review to the "reviews" subcollection of a specific shelter
Future addclothReview(String shelterId, Map<String, dynamic> reviewData) async {
  try {
    await _firestore
        .collection("cloth")
        .doc(shelterId)
        .collection("reviews")
        .add(reviewData);

        // Add to main Reviews collection
    await addToMainReviews(
      reviewData['userId'],
      shelterId,
      'cloth',
      reviewData
    );

    print("Review added successfully!");
  } catch (e) {
    print("Error adding review: $e");
    rethrow;
  }
}

// Get all reviews for a specific shelter
Future<Stream<QuerySnapshot>> getclothReviews(String shelterId) async {
  try {
    return _firestore
        .collection("cloth")
        .doc(shelterId)
        .collection("reviews")
        .orderBy('timestamp', descending: true)
        .snapshots();
  } catch (e) {
    print("Error fetching reviews: $e");
    rethrow;
  }
}

// Delete a specific review by its ID
Future deleteclothReview(String shelterId, String reviewId) async {
  try {
    await _firestore
        .collection("cloth")
        .doc(shelterId)
        .collection("reviews")
        .doc(reviewId)
        .delete();
    print("Review deleted successfully!");
  } catch (e) {
    print("Error deleting review: $e");
    rethrow;
  }
}
//For Notifications

//Adding a notification

Future<void> addNotification(String userId, Map<String, dynamic> notificationData) async {
  try {
    await FirebaseFirestore.instance.collection("notifications").add({
      ...notificationData,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(), // Automatically set the time
    });
    debugPrint("Notification added successfully!");
  } catch (e) {
    debugPrint("Error adding notification: $e");
    rethrow;
  }
}

//For getting notifications(Reading)

Stream<QuerySnapshot> getUserNotifications(String userId) {
  try {
    return FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .orderBy("timestamp", descending: true)
        .snapshots();
  } catch (e) {
    debugPrint("Error fetching notifications: $e");
    rethrow;
  }
}

//For Deleting notifications

Future<void> deleteNotification(String notificationId) async {
  try {
    await FirebaseFirestore.instance.collection("notifications").doc(notificationId).delete();
    debugPrint("Notification deleted successfully!");
  } catch (e) {
    debugPrint("Error deleting notification: $e");
    rethrow;
  }

}
//FOR VOLUNTEERS

// Create Method
  Future setvolunteerDetails(Map<String, dynamic> volunteerInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("volunteer")
        .doc(id)
        .set(volunteerInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getvolunteerDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("volunteer")
      .where("Location", isEqualTo: location)
      //.orderBy('distance', descending: false) // Sort by distance
      .snapshots();
}

  // Update Method
  Future updatevolunteerDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("volunteer")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deletevolunteerDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("volunteer")
        .doc(id)
        .delete();
  }
  // Sorting method
  Future<Stream<QuerySnapshot>> getSortedvolunteerDetails(String sortBy) async{
    Query query = FirebaseFirestore.instance.collection("volunteer");
       //add Sorting method on the selected field
       query=query.orderBy(sortBy,descending: false);
       return query.snapshots();
  }
  
  //For Shelter Reviews

  // Add a review to the "reviews" subcollection of a specific volunteer
Future addvolunteerReview(String volunteerId, Map<String, dynamic> reviewData) async {
  try {
    await _firestore
        .collection("volunteer")
        .doc(volunteerId)
        .collection("reviews")
        .add(reviewData);

        // Add to main Reviews collection
    await addToMainReviews(
      reviewData['userId'],
      volunteerId,
      'volunteer',
      reviewData
    );
    print("Review added successfully!");
  } catch (e) {
    print("Error adding review: $e");
    rethrow;
  }
}

// Get all reviews for a specific volunteers
Future<Stream<QuerySnapshot>> getvolunteerReviews(String volunteerId) async {
  try {
    return _firestore
        .collection("volunteer")
        .doc(volunteerId)
        .collection("reviews")
        .orderBy('timestamp', descending: true)
        .snapshots();
  } catch (e) {
    print("Error fetching reviews: $e");
    rethrow;
  }
}

// Delete a specific review by its ID
Future deletevolunteerReview(String volunteerId, String reviewId) async {
  try {
    await _firestore
        .collection("volunteer")
        .doc(volunteerId)
        .collection("reviews")
        .doc(reviewId)
        .delete();
    print("Review deleted successfully!");
  } catch (e) {
    print("Error deleting review: $e");
    rethrow;
  }
}


//FOR AMBULANCE DRIVERS

// Create Method
  Future setambulanceDetails(Map<String, dynamic> ambulanceInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("ambulance")
        .doc(id)
        .set(ambulanceInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getambulanceDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("ambulance")
      .where("Location", isEqualTo: location)
      //.orderBy('distance', descending: false) // Sort by distance
      .snapshots();
}

  // Update Method
  Future updateambulanceDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("ambulance")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deleteambulanceDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("ambulance")
        .doc(id)
        .delete();
  }
  // Sorting method
  Future<Stream<QuerySnapshot>> getSortedambulanceDetails(String sortBy) async{
    Query query = FirebaseFirestore.instance.collection("ambulance");
       //add Sorting method on the selected field
       query=query.orderBy(sortBy,descending: false);
       return query.snapshots();
  }
  
  //For Shelter Reviews

  // Add a review to the "reviews" subcollection of a specific volunteer
Future addambulanceReview(String ambulanceId, Map<String, dynamic> reviewData) async {
  try {
    await _firestore
        .collection("ambulance")
        .doc(ambulanceId)
        .collection("reviews")
        .add(reviewData);

        // Add to main Reviews collection
    await addToMainReviews(
      reviewData['userId'],
      ambulanceId,
      'ambulance',
      reviewData
    );
    print("Review added successfully!");
  } catch (e) {
    print("Error adding review: $e");
    rethrow;
  }
}

// Get all reviews for a specific ambulance driver
Future<Stream<QuerySnapshot>> getambulanceReviews(String volunteerId) async {
  try {
    return _firestore
        .collection("ambulance")
        .doc(volunteerId)
        .collection("reviews")
        .orderBy('timestamp', descending: true)
        .snapshots();
  } catch (e) {
    print("Error fetching reviews: $e");
    rethrow;
  }
}

// Delete a specific review by its ID
Future deleteambulanceReview(String ambulanceId, String reviewId) async {
  try {
    await _firestore
        .collection("volunteer")
        .doc(ambulanceId)
        .collection("reviews")
        .doc(reviewId)
        .delete();
    print("Review deleted successfully!");
  } catch (e) {
    print("Error deleting review: $e");
    rethrow;
  }
}

//FOR MEDICAL ASSISTANCE

// Create Method
  Future setmedicalDetails(Map<String, dynamic> medicalInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("medical")
        .doc(id)
        .set(medicalInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getmedicalDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("medical")
      .where("Location", isEqualTo: location)
      //.orderBy('distance', descending: false) // Sort by distance
      .snapshots();
}

  // Update Method
  Future updatemedicalDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("medical")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deletemedicalDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("medical")
        .doc(id)
        .delete();
  }
  // Sorting method
  Future<Stream<QuerySnapshot>> getSortedmedicalDetails(String sortBy) async{
    Query query = FirebaseFirestore.instance.collection("medical");
       //add Sorting method on the selected field
       query=query.orderBy(sortBy,descending: false);
       return query.snapshots();
  }
  
  //For Shelter Reviews

  // Add a review to the "reviews" subcollection of a specific volunteer
Future addmedicalReview(String medicalId, Map<String, dynamic> reviewData) async {
  try {
    await _firestore
        .collection("medical")
        .doc(medicalId)
        .collection("reviews")
        .add(reviewData);

        // Add to main Reviews collection
    await addToMainReviews(
      reviewData['userId'],
      medicalId,
      'medical',
      reviewData
    );
    print("Review added successfully!");
  } catch (e) {
    print("Error adding review: $e");
    rethrow;
  }
}

// Get all reviews for a specific ambulance driver
Future<Stream<QuerySnapshot>> getmedicalReviews(String volunteerId) async {
  try {
    return _firestore
        .collection("medical")
        .doc(volunteerId)
        .collection("reviews")
        .orderBy('timestamp', descending: true)
        .snapshots();
  } catch (e) {
    print("Error fetching reviews: $e");
    rethrow;
  }
}

// Delete a specific review by its ID
Future deletemedicalReview(String ambulanceId, String reviewId) async {
  try {
    await _firestore
        .collection("medical")
        .doc(ambulanceId)
        .collection("reviews")
        .doc(reviewId)
        .delete();
    print("Review deleted successfully!");
  } catch (e) {
    print("Error deleting review: $e");
    rethrow;
  }
}

//FOR FIRE AND SAFETY


// Create Method
  Future setfireAndsafetyDetails(Map<String, dynamic> fireAndsafetyInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("fireAndsafety")
        .doc(id)
        .set(fireAndsafetyInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getfireAndsafetyDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("fireAndsafety")
      .where("Location", isEqualTo: location)
      //.orderBy('distance', descending: false) // Sort by distance
      .snapshots();
}

  // Update Method
  Future updatefireAndsafetyDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("fireAndsafety")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deletefireAndsafetyDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("fireAndsafety")
        .doc(id)
        .delete();
  }


//FOR BLOOD DONORS


// Create Method
  Future setbloodDonorDetails(Map<String, dynamic> bloodDonorInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("bloodDonor")
        .doc(id)
        .set(bloodDonorInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getbloodDonorDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("bloodDonor")
      .where("Location", isEqualTo: location)
      //.orderBy('distance', descending: false) // Sort by distance
      .snapshots();
}

  // Update Method
  Future updatebloodDonorDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("bloodDonor")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deletebloodDonorDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("bloodDonor")
        .doc(id)
        .delete();
  }

  //For COORDINATORS


  // Create Method
  Future addadminDetails(Map<String, dynamic> adminInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("adminDetail")
        .doc(id)
        .set(adminInfoMap);
  }

  // Read Method with Optional Search
  Future<Stream<QuerySnapshot>> getadminDetails({required String location}) async {
  return FirebaseFirestore.instance
      .collection("adminDetail")
      .where("Location", isEqualTo: location)
      .snapshots();
}

  // Update Method
  Future updateadminDetail(String id, Map<String, dynamic> updateInfo) async {
    return await FirebaseFirestore.instance
        .collection("adminDetail")
        .doc(id)
        .update(updateInfo);
  }

  // Delete Method
  Future deleteadminDetail(String id) async {
    return await FirebaseFirestore.instance
        .collection("adminDetail")
        .doc(id)
        .delete();
  }
}

