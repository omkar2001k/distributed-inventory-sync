/// Generic Response Model for Inventory operations without requiring Dartz.
class InventoryResponseModel<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final String? errorMessage;

  const InventoryResponseModel({
    required this.isSuccess,
    this.data,
    this.message,
    this.errorMessage,
  });

  factory InventoryResponseModel.success({T? data, String? message}) {
    return InventoryResponseModel(
      isSuccess: true,
      data: data,
      message: message,
    );
  }

  factory InventoryResponseModel.failure({required String errorMessage}) {
    return InventoryResponseModel(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
