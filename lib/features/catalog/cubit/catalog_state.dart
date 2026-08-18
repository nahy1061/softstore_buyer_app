import 'package:equatable/equatable.dart';
import '../models/catalog_models.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {
  const CatalogInitial();
}

class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

class CatalogLoaded extends CatalogState {
  final HomepageData homepageData;
  final String selectedCategory;

  const CatalogLoaded({
    required this.homepageData,
    this.selectedCategory = 'All',
  });

  CatalogLoaded copyWith({
    HomepageData? homepageData,
    String? selectedCategory,
  }) {
    return CatalogLoaded(
      homepageData: homepageData ?? this.homepageData,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [homepageData, selectedCategory];
}

class CatalogSearchResultsLoaded extends CatalogState {
  final SearchResult searchResult;
  final String query;

  const CatalogSearchResultsLoaded({
    required this.searchResult,
    required this.query,
  });

  @override
  List<Object?> get props => [searchResult, query];
}

class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}
