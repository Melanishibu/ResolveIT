/// Public API of the dashboard feature (RIT-US-21). Other features and the app import only this file.
library;

export 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';
export 'package:resolveit/features/dashboard/domain/repository/dashboard_repository.dart';
export 'package:resolveit/features/dashboard/presentation/router/dashboard_routes.dart';
export 'package:resolveit/features/dashboard/presentation/view/dashboard_view.dart';
export 'package:resolveit/features/dashboard/providers.dart'
    show dashboardHttpClientProvider, dashboardRepositoryProvider;
export 'package:resolveit/features/dashboard/widgets/count_card.dart'
    show IncidentCountCards;
