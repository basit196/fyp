import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Document does not exist');
    }
    
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    
    // Handle timestamp - serverTimestamp() might be null initially
    DateTime timestamp;
    try {
      if (data['timestamp'] != null) {
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is Map) {
          // Server timestamp not yet processed
          timestamp = DateTime.now();
        } else {
          timestamp = DateTime.now();
        }
      } else {
        // Timestamp is null (server hasn't processed it yet)
        timestamp = DateTime.now();
      }
    } catch (e) {
      timestamp = DateTime.now();
    }
    
    // Validate required fields
    String senderId = data['senderId']?.toString() ?? '';
    String senderName = data['senderName']?.toString() ?? '';
    String message = data['message']?.toString() ?? '';
    
    if (senderId.isEmpty || message.isEmpty) {
      throw Exception('Message missing required fields');
    }
    
    return ChatMessage(
      id: doc.id,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: timestamp,
      isRead: data['isRead'] == true,
    );
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Get or Create Chat Room ID
  String getChatRoomId(String userId1, String userId2) {
    // Create consistent chat room ID regardless of order
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Send Message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String message,
  }) async {
    try {
      // Add message to chat room
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat room metadata
      await _firestore.collection('chats').doc(chatRoomId).set({
        'participants': [senderId, recipientId],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'lastSenderName': senderName,
        'unreadCount_$recipientId': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Send notification to recipient
      await _notificationService.sendMessageNotification(
        recipientId: recipientId,
        senderName: senderName,
        message: message,
        chatId: chatRoomId,
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get Messages Stream
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    // Get messages without orderBy to avoid index requirement
    // Will sort client-side by timestamp
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .limit(100)
        .snapshots();
  }

  /// Mark Messages as Read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // Get unread messages
      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Update all to read
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count
      await _firestore.collection('chats').doc(chatRoomId).update({
        'unreadCount_$userId': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get User's Chat Rooms
  Stream<QuerySnapshot> getUserChats(String userId) {
    // Note: Removing orderBy to avoid index requirement
    // Will sort client-side instead
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  /// Get Unread Message Count
  Future<int> getUnreadMessageCount(String chatRoomId, String userId) async {
    try {
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatRoomId).get();

      if (chatDoc.exists) {
        return chatDoc.get('unreadCount_$userId') ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete Chat Room
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages
      QuerySnapshot messages = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete chat room
      await _firestore.collection('chats').doc(chatRoomId).delete();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  /// Check if Chat Exists
  Future<bool> chatExists(String chatRoomId) async {
    DocumentSnapshot doc =
        await _firestore.collection('chats').doc(chatRoomId).get();
    return doc.exists;
  }
}


