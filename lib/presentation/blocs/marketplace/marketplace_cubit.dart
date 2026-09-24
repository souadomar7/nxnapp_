import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/marketplace_repository.dart';
import '../../../models/marketplace_models.dart';

// States
abstract class MarketplaceState {
  const MarketplaceState();
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

class MarketplaceLoaded extends MarketplaceState {
  final List<SmeProduct> publicProducts;
  final List<SmeProduct> myProducts;

  const MarketplaceLoaded({
    required this.publicProducts,
    required this.myProducts,
  });
}

class MarketplaceError extends MarketplaceState {
  final String message;
  const MarketplaceError(this.message);
}

// Cubit
class MarketplaceCubit extends Cubit<MarketplaceState> {
  final MarketplaceRepository _repository;

  MarketplaceCubit({MarketplaceRepository? repository})
      : _repository = repository ?? MarketplaceRepository(),
        super(const MarketplaceInitial());

  Future<void> load() async {
    emit(const MarketplaceLoading());
    try {
      final publicProds = await _repository.getPublicProducts();
      final myProds = await _repository.getMyProducts();
      emit(MarketplaceLoaded(
        publicProducts: publicProds,
        myProducts: myProds,
      ));
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }
}
