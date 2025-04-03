import 'package:flutter/foundation.dart';
import '../../../models/memory_capsule.dart';
import '../../../repositories/memory_repository.dart';

class MemoryHistoryProvider with ChangeNotifier {
  final MemoryRepository _repository = MemoryRepository();
  
  // Stream of memories
  Stream<List<MemoryCapsule>> get memories => _repository.getMemories();
  
  // Update a memory
  Future<void> updateMemory(MemoryCapsule memory) async {
    await _repository.updateMemory(memory);
  }
  
  // Delete a memory
  Future<void> deleteMemory(MemoryCapsule memory) async {
    await _repository.deleteMemory(memory);
  }
} 