import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../config/app_colors.dart';

class VolunteerResource {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String url;
  final String category;
  final List<String> tags;
  final int order;

  VolunteerResource({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    required this.category,
    required this.tags,
    required this.order,
  });

  factory VolunteerResource.fromJson(Map<String, dynamic> json) {
    return VolunteerResource(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      url: json['url'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      order: json['order'] ?? 0,
    );
  }
}

class VolunteerResourcesScreen extends StatefulWidget {
  const VolunteerResourcesScreen({super.key});

  @override
  State<VolunteerResourcesScreen> createState() => _VolunteerResourcesScreenState();
}

class _VolunteerResourcesScreenState extends State<VolunteerResourcesScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;

  List<VolunteerResource> _resources = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _selectedType = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _resourceTypes = [
    {'value': 'youtube', 'label': 'YouTube Videos'},
    {'value': 'google_drive', 'label': 'Google Drive'},
    {'value': 'pdf', 'label': 'PDF Documents'},
    {'value': 'document', 'label': 'Documents'},
    {'value': 'link', 'label': 'External Links'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndTypes();
    _fetchResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoriesAndTypes() async {
    try {
      final token = await secureStorage.read(key: "token");
      if (token == null) return;

      final categoriesResponse = await http.get(
        Uri.parse('$baseUrl/resources/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (categoriesResponse.statusCode == 200) {
        final categoriesData = json.decode(categoriesResponse.body);
        if (categoriesData['success'] == true) {
          setState(() => _categories = List<Map<String, dynamic>>.from(categoriesData['data']));
        }
      }

      final typesResponse = await http.get(
        Uri.parse('$baseUrl/resources/types'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (typesResponse.statusCode == 200) {
        final typesData = json.decode(typesResponse.body);
        if (typesData['success'] == true) {
          setState(() => _types = List<Map<String, dynamic>>.from(typesData['data']));
        }
      }
    } catch (e) {
      print('Error fetching categories/types: $e');
    }
  }

  Future<void> _fetchResources() async {
    setState(() => _isLoading = true);

    try {
      final token = await secureStorage.read(key: "token");
      if (token == null) return;

      final queryParams = {
        'page': _currentPage.toString(),
        'limit': '20',
        'sortBy': 'order',
        'sortOrder': 'asc',
      };

      if (_selectedCategory != 'all') {
        queryParams['category'] = _selectedCategory;
      }

      if (_selectedType != 'all') {
        queryParams['type'] = _selectedType;
      }

      final uri = Uri.parse('$baseUrl/resources').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final resourcesData = data['data']['resources'] as List;
          final pagination = data['data']['pagination'];

          setState(() {
            _resources = resourcesData.map((r) => VolunteerResource.fromJson(r)).toList();
            _totalPages = pagination['totalPages'] ?? 1;
            _isLoading = false;
          });
        }
      } else {
        _showError('Failed to load resources');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching resources: $e');
      _showError('Error loading resources');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchResources() async {
    if (_searchController.text.trim().length < 2) {
      _showError('Search query must be at least 2 characters');
      return;
    }

    setState(() => _isSearching = true);

    try {
      final token = await secureStorage.read(key: "token");
      if (token == null) return;

      final queryParams = {
        'q': _searchController.text.trim(),
        'page': '1',
        'limit': '20',
      };

      if (_selectedCategory != 'all') {
        queryParams['category'] = _selectedCategory;
      }

      if (_selectedType != 'all') {
        queryParams['type'] = _selectedType;
      }

      final uri = Uri.parse('$baseUrl/resources/search').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final resourcesData = data['data']['resources'] as List;
          final pagination = data['data']['pagination'];

          setState(() {
            _resources = resourcesData.map((r) => VolunteerResource.fromJson(r)).toList();
            _totalPages = pagination['totalPages'] ?? 1;
            _currentPage = 1;
            _isSearching = false;
          });
        }
      } else {
        _showError('Search failed');
        setState(() => _isSearching = false);
      }
    } catch (e) {
      print('Error searching resources: $e');
      _showError('Error searching resources');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _openResource(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open resource');
      }
    } catch (e) {
      _showError('Invalid URL');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _currentPage = 1;
    });
    _fetchResources();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'youtube':
        return '📺';
      case 'google_drive':
        return '📁';
      case 'pdf':
        return '📄';
      case 'document':
        return '📝';
      case 'link':
        return '🔗';
      default:
        return '📚';
    }
  }

  String _getCategoryLabel(String category) {
    final categoryData = _categories.firstWhere(
      (cat) => cat['value'] == category,
      orElse: () => {'label': category},
    );
    return categoryData['label'] ?? category;
  }

  String _getTypeLabel(String type) {
    final typeData = _resourceTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => {'label': type},
    );
    return typeData['label'] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight1,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Resources',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchResources,
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Search and Filters Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access Learning Resources',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find training materials, guides, and resources to support your mentoring journey',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.gray1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search resources...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _searchResources(),
                  ),
                  const SizedBox(height: 16),
                  // Filters
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Categories')),
                      ..._categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['value'] as String,
                          child: Text('${category['label']} (${category['count']})'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                      _fetchResources();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      ..._types.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'] as String,
                          child: Text('${type['label']} (${type['count']})'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                      _fetchResources();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Resources List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: _isLoading || _isSearching
                ? SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    ),
                  )
                : _resources.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.library_books, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _isSearching ? 'No search results found' : 'No resources available',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              if (_isSearching) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _clearSearch,
                                  child: Text('Clear Search'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final resource = _resources[index];
                            return _buildResourceCard(resource);
                          },
                          childCount: _resources.length,
                        ),
                      ),
          ),

          // Pagination
          if (_totalPages > 1 && !_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              _fetchResources();
                            }
                          : null,
                    ),
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: GoogleFonts.poppins(),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages
                          ? () {
                              setState(() => _currentPage++);
                              _fetchResources();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),

          // Bottom padding
          SliverToBoxAdapter(
            child: const SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(VolunteerResource resource) {
    final typeIcon = _getTypeIcon(resource.type);
    final categoryLabel = _getCategoryLabel(resource.category);
    final typeLabel = _getTypeLabel(resource.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openResource(resource.url),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    typeIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                typeLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                categoryLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
              if (resource.description != null && resource.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  resource.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.gray1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (resource.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: resource.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to open resource',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.gray1,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.primaryBlue,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}