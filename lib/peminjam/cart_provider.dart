import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_model.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  static const String _cartKey = 'shopping_cart';

  List<CartItem> get items => _items;
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  int get uniqueItemCount => _items.length;

  // Initialize cart from storage
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    if (cartJson != null) {
      final List<dynamic> decoded = json.decode(cartJson);
      _items = decoded.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  // Save cart to storage
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
  }

  // Add item to cart
  Future<bool> addToCart(CartItem item) async {
    // Check if item already exists
    final existingIndex = _items.indexWhere((i) => i.alatId == item.alatId);
    
    if (existingIndex >= 0) {
      // Item exists, increase quantity (if stock allows)
      if (_items[existingIndex].quantity < item.stok) {
        _items[existingIndex].quantity++;
      } else {
        return false; // Stock limit reached
      }
    } else {
      // New item
      _items.add(item);
    }
    
    await _saveCart();
    notifyListeners();
    return true;
  }

  // Remove item from cart
  Future<void> removeFromCart(String alatId) async {
    _items.removeWhere((item) => item.alatId == alatId);
    await _saveCart();
    notifyListeners();
  }

  // Update quantity
  Future<bool> updateQuantity(String alatId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.alatId == alatId);
    
    if (index >= 0) {
      if (newQuantity <= 0) {
        await removeFromCart(alatId);
        return true;
      }
      
      if (newQuantity <= _items[index].stok) {
        _items[index].quantity = newQuantity;
        await _saveCart();
        notifyListeners();
        return true;
      }
      return false; // Exceeds stock
    }
    return false;
  }

  // Clear cart
  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  // Check if item is in cart
  bool isInCart(String alatId) {
    return _items.any((item) => item.alatId == alatId);
  }

  // Get item quantity in cart
  int getItemQuantity(String alatId) {
    final item = _items.firstWhere(
      (item) => item.alatId == alatId,
      orElse: () => CartItem(
        alatId: '',
        nama: '',
        kategori: '',
        stok: 0,
        denda: 0,
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}
