import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../services/screens/services_screen.dart';
import '../../admin/screens/admin_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/screens/home_screen.dart';
import '../../professionals/screens/pro_list_screen.dart';
import '../../search_and_booking/screens/booking_screens.dart';
import '../../reviews_and_history/screens/reclamation_screens.dart';
import '../../profile/screens/profile_screen.dart';
import '../../messaging/screens/conversations_list_screen.dart';
import '../../../services/homefix_data.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final data = context.watch<HomeFixData>();
    final unreadMessages =
        data.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    if (user?.isAdmin == true) return const AdminScreen();
    final screens = <Widget>[
      const HomeScreen(),
      user?.isProfessional == true
          ? const ServicesScreen()
          : const ProListScreen(),
      const BookingListScreen(),
      const HistoryAndReclamationsScreen(),
      const ConversationsListScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 4) {
              context.read<HomeFixData>().refresh();
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.engineering_outlined),
              activeIcon: const Icon(Icons.engineering_rounded),
              label: user?.isProfessional == true ? 'Prestations' : 'Artisans',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Réservations',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadMessages > 0,
                label: Text('$unreadMessages'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              activeIcon: Badge(
                isLabelVisible: unreadMessages > 0,
                label: Text('$unreadMessages'),
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
