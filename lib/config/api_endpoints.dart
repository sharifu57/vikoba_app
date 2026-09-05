import 'package:vikoba_app/config/app_config.dart';

class ApiEndpoints {
  static String get baseUrl => AppConfig.baseUrl;
  static String get lookup => "$baseUrl/lookup";
  static String get dashboardSummary => "$baseUrl/summary/dashboard";
  static String get medicineCategories => "$baseUrl/api/medicine/categories";
  static String get dosageForms => "$baseUrl/api/medicine/dosage-forms";
  static String get unitsOfMeasure => "$baseUrl/api/medicine/units";
  static String get createMedicine => "$baseUrl/api/medicine/create";
  static String get branchMedicines => "$baseUrl/api/medicine/branch";
  static String get deleteMedicine => "$baseUrl/api/medicine/delete";

  static String get suppliers => "$baseUrl/supplier/suppliers";
  static String get addSupplier => "$baseUrl/supplier/create";
  static String get supplierDashboard => "$baseUrl/supplier/supplier-dashboard";

  static String get lowStocks => "$baseUrl/stock/low-stock";
  static String get inventories => "$baseUrl/stock/branch";
  static String get addStock => "$baseUrl/stock/add";
  static String get makeSale => "$baseUrl/sale/create-sale";
  static String get salesOverview => "$baseUrl/sale/sales-overview";
  static String get recentSales => "$baseUrl/sale/recent-sales";

  static String get createPurchaseOrder => "$baseUrl/purchase/create";
  static String get purchaseOrders => "$baseUrl/purchase/orders";
  static String get organizationPurchaseOrders =>
      "$baseUrl/purchase/organization";
  static String get supplierApproveOrder => "$baseUrl/purchase/approve";
  static String get rejectPurchaseOrder => "$baseUrl/purchase/supplier-reject";
  static String get cancelPurchaseOrder => "$baseUrl/purchase/cancel";
  static String get purchaseOrderStatus => "$baseUrl/purchase/status";

  static String get expiringBatches => "$baseUrl/batch/expiring-soon";
}
