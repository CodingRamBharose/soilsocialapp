import 'package:flutter/material.dart';

class RefreshProvider extends ChangeNotifier {
  int _postsVersion = 0;
  int _eventsVersion = 0;
  int _productsVersion = 0;
  int _connectionsVersion = 0;

  int get postsVersion => _postsVersion;
  int get eventsVersion => _eventsVersion;
  int get productsVersion => _productsVersion;
  int get connectionsVersion => _connectionsVersion;

  void refreshPosts() {
    _postsVersion++;
    notifyListeners();
  }

  void refreshEvents() {
    _eventsVersion++;
    notifyListeners();
  }

  void refreshProducts() {
    _productsVersion++;
    notifyListeners();
  }

  void refreshConnections() {
    _connectionsVersion++;
    notifyListeners();
  }
}
