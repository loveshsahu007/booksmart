import 'dart:developer';

import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
import 'package:get/get.dart';
import '../../../models/order_model.dart';
import '../../common/controllers/chat_controller.dart';
import 'package:booksmart/services/storage_service.dart';
import 'package:booksmart/supabase/buckets.dart';

import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/modules/user/controllers/tax_document_controller.dart';
import 'package:booksmart/widgets/snackbar.dart';

class OrderController extends GetxController {
  final isLoading = false.obs;

  // For order creation
  final titleController = TextEditingController();
  final cancellationController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final startDate = Rx<DateTime?>(null);
  final dueDate = Rx<DateTime?>(null);
  final selectedServices = <String>[].obs;

  // Active orders list (for user dashboard)
  final activeOrders = <OrderModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchActiveOrders();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }

  Future<bool> createOrder({
    required int userId,
    List<String>? deliverables,
  }) async {
    if (titleController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty) {
      Get.snackbar("Error", "Please fill in all required fields");
      return false;
    }

    try {
      isLoading.value = true;
      final cpaId = Get.find<AuthController>().person?.id;
      if (cpaId == null) {
        Get.snackbar("Error", "User not found");
        return false;
      }

      final data = {
        'cpa_id': cpaId,
        'user_id': userId,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'amount': double.tryParse(amountController.text.trim()) ?? 0.0,
        'status': OrderStatus.pending.name,
        'start_date': startDate.value?.toIso8601String(),
        'due_date': dueDate.value?.toIso8601String(),
        'services': selectedServices.toList(),
        if (deliverables != null) 'deliverables': deliverables,
        if (cancellationController.text.trim().isNotEmpty)
          'cancellation_policy': cancellationController.text.trim(),
      };

      final result = await SupabaseCrudService.insert(
        table: SupabaseTable.orders,
        data: data,
      );

      if (result != null) {
        // Send automated message
        try {
          if (Get.isRegistered<ChatController>()) {
            final chatController = Get.find<ChatController>();

            String orderIdStr = "";
            if (result is List && result.isNotEmpty) {
              orderIdStr = "Order #${result[0]['id']}";
            }

            final msg =
                "Order Request Sent $orderIdStr\nTitle: ${titleController.text.trim()}\nAmount: \$${amountController.text.trim()}\n\nPlease check your dashboard for details.";
            chatController.sendMessage(msg);
          }
        } catch (e) {
          log("Error sending auto-message: $e");
        }

        _clearForm();
        return true;
      } else {
        Get.snackbar("Error", "Failed to send order request");
        return false;
      }
    } catch (e) {
      log("Error creating order: $e");
      Get.snackbar("Error", "An error occurred: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    titleController.clear();
    descriptionController.clear();
    amountController.clear();
    startDate.value = null;
    dueDate.value = null;
    selectedServices.clear();
  }

  Future<void> fetchActiveOrders() async {
    try {
      isLoading.value = true;
      final person = Get.find<AuthController>().person;
      if (person == null) return;

      final isCpa = person.role == UserRole.cpa;
      final userId = person.id;

      // Ensure we select the related cpa/user data
      // If CPA, we want to see the User details (user:user_id(*))
      // If User, we want to see the CPA details (cpa:cpa_id(*))

      var query = supabase
          .from(SupabaseTable.orders)
          .select(isCpa ? '*, user:user_id(*)' : '*, cpa:cpa_id(*)')
          .neq('status', OrderStatus.cancelled.name)
          .neq('status', OrderStatus.completed.name);

      if (isCpa) {
        query = query.eq('cpa_id', userId);
      } else {
        query = query.eq('user_id', userId);
      }

      final result = await query.order('created_at', ascending: false);

      activeOrders.value = (result as List)
          .map((e) => OrderModel.fromJson(e))
          .toList();
    } catch (e) {
      log("Error fetching active orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    try {
      isLoading.value = true;
      await SupabaseCrudService.update(
        table: SupabaseTable.orders,
        data: {'status': status.name},
        filters: {'id': orderId},
      );
      // Refresh list
      await fetchActiveOrders();
      if (status == OrderStatus.accepted) {
        Get.snackbar("Success", "Order accepted!");
      } else if (status == OrderStatus.rejected) {
        Get.snackbar("Info", "Order declined.");
      }
    } catch (e) {
      log("Error updating order status: $e");
      Get.snackbar("Error", "Failed to update status");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deliverOrder({
    required int orderId,
    required String message,
    required List<XFile> files,
    List<String> existingFiles = const [],
    List<Map<String, dynamic>>? fileMetadata, // Optional metadata for each file
    int? clientUserId, // Client's user ID for proper categorization
  }) async {
    try {
      isLoading.value = true;
      List<String> uploadedUrls = [];

      final taxDocCtrl = Get.isRegistered<TaxDocumentController>()
          ? Get.find<TaxDocumentController>()
          : Get.put(TaxDocumentController());

      final cpaId = Get.find<AuthController>().person?.id;

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final metadata = (fileMetadata != null && i < fileMetadata.length)
            ? fileMetadata[i]
            : null;

        String? finalUrl;

        // 1. Try formal upload with metadata if available
        if (metadata != null && clientUserId != null) {
          finalUrl = await taxDocCtrl.uploadDocument(
            name: metadata['name'] ?? file.name,
            taxYear: metadata['year']?.toString(),
            category: metadata['category'],
            userId: clientUserId,
            orderId: orderId,
            cpaId: cpaId,
            manualFile: file,
          );
        }

        // 2. Fallback to direct upload if not already uploaded or if metadata was missing
        finalUrl ??= await uploadFileToSupabaseStorage(
          file: file,
          bucketName: SupabaseStorageBucket.documents,
        );

        if (finalUrl != null) {
          uploadedUrls.add(finalUrl);
        }
      }

      await SupabaseCrudService.update(
        table: SupabaseTable.orders,
        data: {
          'status': OrderStatus.delivered.name,
          'deliver_message': message,
          'deliver_at': DateTime.now().toIso8601String(),
          'delivery_files': [...existingFiles, ...uploadedUrls],
        },
        filters: {'id': orderId},
      );

      await fetchActiveOrders();

      // Close dialog first
      Get.back();

      // Show success message using the safer showSnackBar helper
      showSnackBar("Order delivered successfully!");
    } catch (e) {
      log("Error delivering order: $e");
      showSnackBar("Failed to deliver order", isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
