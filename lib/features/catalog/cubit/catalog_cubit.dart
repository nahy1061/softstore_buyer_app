import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../models/catalog_models.dart';
import '../repository/catalog_repository.dart';
import 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit() : super(const CatalogInitial());

  final CatalogRepository _repo = CatalogRepository.instance;

  Future<void> loadHomepage() async {
    emit(const CatalogLoading());
    try {
      final data = await _repo.getHomepage();
      emit(CatalogLoaded(homepageData: data));
    } on NetworkFailure catch (e) {
      emit(CatalogError(e.message));
    } catch (e) {
      developer.log('[CatalogCubit] loadHomepage error: $e', name: 'catalog');
      emit(const CatalogLoaded(homepageData: HomepageData()));
    }
  }

  Future<void> search(String query, {String? category}) async {
    if (query.trim().isEmpty && (category == null || category.trim().isEmpty || category.trim().toLowerCase() == 'all')) {
      loadHomepage();
      return;
    }
    emit(const CatalogLoading());
    try {
      final result = await _repo.searchProducts(query: query, category: category);
      emit(CatalogSearchResultsLoaded(searchResult: result, query: query));
    } on NetworkFailure catch (e) {
      emit(CatalogError(e.message));
    } catch (e) {
      developer.log('[CatalogCubit] search error: $e', name: 'catalog');
      emit(const CatalogSearchResultsLoaded(
        searchResult: SearchResult(products: []),
        query: '',
      ));
    }
  }

  void selectCategory(String category) {
    if (state is CatalogLoaded) {
      final current = state as CatalogLoaded;
      emit(current.copyWith(selectedCategory: category));
    }
  }
}
