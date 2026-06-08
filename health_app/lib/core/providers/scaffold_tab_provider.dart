import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global tab index provider so any widget can switch the main scaffold tab.
/// 0=Home  1=Symptoms  2=Hydration  3=Reports  4=Sleep  5=Watch
final scaffoldTabProvider = StateProvider<int>((ref) => 0);
