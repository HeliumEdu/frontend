import 'package:web/web.dart' as web;

bool get hasTouchScreen => web.window.navigator.maxTouchPoints > 0;
