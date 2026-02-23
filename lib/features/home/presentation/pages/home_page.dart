import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../categories/data/datasources/remote/category_remote_data_source.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../../../categories/domain/entities/category.dart';
import '../widgets/home_header.dart';
import '../widgets/special_offers_section.dart';
import '../widgets/category_section.dart';
import '../widgets/product_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Category> _categories = [];
  late final GetCategoriesUseCase _getCategoriesUseCase;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    _loadCategories();
  }

  void _initializeDependencies() {
    final apiClient = ApiClient();
    final remoteDataSource = CategoryRemoteDataSourceImpl(apiClient: apiClient);
    final repository = CategoryRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    _getCategoriesUseCase = GetCategoriesUseCase(repository: repository);
  }

  // Method mới: Load categories từ API
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await _getCategoriesUseCase(
        pageNumber: 1,
        pageSize: 10,
      );
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
      print('✅ Categories loaded: ${_categories.length} items');
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Header với location và search
          const HomeHeader(),

          // 2. Special Offers Section
          const SpecialOffersSection(),

          // 3. Category Section
          CategorySection(
            categories: _categories,
            isLoading: _isLoadingCategories,
          ),

          // 4. Best Selling Items Section
          const ProductSection(),
        ],
      ),
    );
  }
}
