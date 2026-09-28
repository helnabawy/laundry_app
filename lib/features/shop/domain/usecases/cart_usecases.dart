import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class LoadCart implements UseCase<Cart, NoParams> {
  const LoadCart(this._repo);
  final CartRepository _repo;

  @override
  Future<Result<Cart>> call([NoParams params = const NoParams()]) =>
      _repo.load();
}

class SaveCart implements UseCase<void, Cart> {
  const SaveCart(this._repo);
  final CartRepository _repo;

  @override
  Future<Result<void>> call(Cart params) => _repo.save(params);
}

class ClearCart implements UseCase<void, NoParams> {
  const ClearCart(this._repo);
  final CartRepository _repo;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repo.clear();
}
