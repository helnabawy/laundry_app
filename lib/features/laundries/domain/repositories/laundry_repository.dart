import '../../../../core/result/result.dart';
import '../entities/laundry.dart';

abstract interface class LaundryRepository {
  /// Active laundries, oldest first.
  Future<Result<List<Laundry>>> getLaundries();

  /// The laundry chosen on this device, if any (works offline).
  Laundry? savedLaundry();

  Future<void> saveLaundry(Laundry? laundry);
}
