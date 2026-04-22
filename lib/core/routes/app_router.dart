import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_model.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/otp_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/auth/screens/role_selection_screen.dart';
import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/agent/screens/agent_dashboard.dart';
import '../../presentation/agent/screens/communication_hub_screen.dart';
import '../../presentation/agent/screens/financial_reports_screen.dart';
import '../../presentation/agent/screens/maintenance_manager_screen.dart';
import '../../presentation/agent/screens/property_details_screen.dart';
import '../../presentation/homeowner/screens/approvals_screen.dart';
import '../../presentation/homeowner/screens/document_vault_screen.dart';
import '../../presentation/homeowner/screens/financial_dashboard_screen.dart';
import '../../presentation/homeowner/screens/homeowner_dashboard.dart';
import '../../presentation/homeowner/screens/investment_overview_screen.dart';
import '../../presentation/tenant/screens/documents_screen.dart';
import '../../presentation/tenant/screens/messages_screen.dart';
import '../../presentation/tenant/screens/rent_payment_screen.dart';
import '../../presentation/tenant/screens/report_issue_screen.dart';
import '../../presentation/tenant/screens/tenant_dashboard.dart';
import '../../providers/auth_provider.dart';

// Route name constants
class AppRoutes {
  static const splash = '/';
  static const roleSelection = '/role';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';

  // Tenant
  static const tenantDashboard = '/tenant';
  static const rentPayment = '/tenant/payment';
  static const reportIssue = '/tenant/maintenance/new';
  static const tenantMessages = '/tenant/messages';
  static const tenantDocuments = '/tenant/documents';

  // Agent
  static const agentDashboard = '/agent';
  static const propertyDetails = '/agent/property/:id';
  static const maintenanceManager = '/agent/maintenance';
  static const financialReports = '/agent/reports';
  static const communicationHub = '/agent/communication';

  // Homeowner
  static const homeownerDashboard = '/owner';
  static const investmentOverview = '/owner/investments';
  static const financialDashboard = '/owner/financials';
  static const approvals = '/owner/approvals';
  static const documentVault = '/owner/documents';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.roleSelection ||
          state.matchedLocation == AppRoutes.otp;

      if (user == null && !isOnAuthRoute) return AppRoutes.login;
      if (user != null && isOnAuthRoute && state.matchedLocation != AppRoutes.splash) {
        return _homeForRole(user.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.roleSelection, builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.otp, builder: (_, __) => const OtpScreen()),

      // Tenant routes
      GoRoute(path: AppRoutes.tenantDashboard, builder: (_, __) => const TenantDashboard()),
      GoRoute(path: AppRoutes.rentPayment, builder: (_, __) => const RentPaymentScreen()),
      GoRoute(path: AppRoutes.reportIssue, builder: (_, __) => const ReportIssueScreen()),
      GoRoute(path: AppRoutes.tenantMessages, builder: (_, __) => const MessagesScreen()),
      GoRoute(path: AppRoutes.tenantDocuments, builder: (_, __) => const TenantDocumentsScreen()),

      // Agent routes
      GoRoute(path: AppRoutes.agentDashboard, builder: (_, __) => const AgentDashboard()),
      GoRoute(
        path: AppRoutes.propertyDetails,
        builder: (_, state) => PropertyDetailsScreen(propertyId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.maintenanceManager, builder: (_, __) => const MaintenanceManagerScreen()),
      GoRoute(path: AppRoutes.financialReports, builder: (_, __) => const FinancialReportsScreen()),
      GoRoute(path: AppRoutes.communicationHub, builder: (_, __) => const CommunicationHubScreen()),

      // Homeowner routes
      GoRoute(path: AppRoutes.homeownerDashboard, builder: (_, __) => const HomeownerDashboard()),
      GoRoute(path: AppRoutes.investmentOverview, builder: (_, __) => const InvestmentOverviewScreen()),
      GoRoute(path: AppRoutes.financialDashboard, builder: (_, __) => const FinancialDashboardScreen()),
      GoRoute(path: AppRoutes.approvals, builder: (_, __) => const ApprovalsScreen()),
      GoRoute(path: AppRoutes.documentVault, builder: (_, __) => const DocumentVaultScreen()),
    ],
  );
});

String _homeForRole(UserRole role) => switch (role) {
      UserRole.tenant => AppRoutes.tenantDashboard,
      UserRole.agent => AppRoutes.agentDashboard,
      UserRole.homeowner => AppRoutes.homeownerDashboard,
    };
