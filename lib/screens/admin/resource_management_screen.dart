import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../../config/app_colors.dart';

class Resource {
  final String id;
  final String title;
  final String? description;
  final String type;
  final String url;
  final String category;
  final List<String> tags;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Resource({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    required this.category,
    required this.tags,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      url: json['url'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'category': category,
      'tags': tags,
      'isActive': isActive,
      'order': order,
    };
  }
}

class AdminResourceManagementScreen extends StatefulWidget {
  const AdminResourceManagementScreen({super.key});

  @override
  State<AdminResourceManagementScreen> createState() => _AdminResourceManagementScreenState();
}

class _AdminResourceManagementScreenState extends State<AdminResourceManagementScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;

  // JWT decoder function
  Map<String, dynamic>? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded);
    } catch (e) {
      return null;
    }
  }

  List<Resource> _resources = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  Map<String, dynamic> _stats = {};

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();

  String _selectedType = 'youtube';
  String _selectedCategory = 'training';
  bool _isActive = true;

  final List<Map<String, String>> _resourceTypes = [
    {'value': 'youtube', 'label': 'YouTube Video'},
    {'value': 'google_drive', 'label': 'Google Drive'},
    {'value': 'pdf', 'label': 'PDF Document'},
    {'value': 'document', 'label': 'Google Doc/Sheet'},
    {'value': 'link', 'label': 'External Link'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _categories = [
    {'value': 'training', 'label': 'Training Materials'},
    {'value': 'mentoring', 'label': 'Mentoring Resources'},
    {'value': 'resources', 'label': 'General Resources'},
    {'value': 'guides', 'label': 'Guides & Tutorials'},
    {'value': 'videos', 'label': 'Video Content'},
    {'value': 'documents', 'label': 'Documents'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchResources();
    _fetchStats();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _fetchResources() async {
    setState(() => _isLoading = true);

    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;

      final queryParams = {
        'page': _currentPage.toString(),
        'limit': '20',
        'sortBy': 'order',
        'sortOrder': 'asc',
      };

      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'active') {
          queryParams['isActive'] = 'true';
        } else if (_selectedFilter == 'inactive') {
          queryParams['isActive'] = 'false';
        }
      }

      final uri = Uri.parse('$baseUrl/admin/resources').replace(queryParameters: queryParams);

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
            _resources = resourcesData.map((r) => Resource.fromJson(r)).toList();
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

  Future<void> _fetchStats() async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/admin/resources/stats/overview'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _stats = data['data']);
        }
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> _createResource() async {
    if (_titleController.text.trim().isEmpty || _urlController.text.trim().isEmpty) {
      _showError('Title and URL are required');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;

      // Decode JWT to get admin ID
      final decodedToken = _decodeJWT(token);
      final adminId = decodedToken?['id'] ?? decodedToken?['adminId'] ?? decodedToken?['userId'];

      if (adminId == null) {
        _showError('Unable to identify admin user');
        return;
      }

      final tags = _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

      final resourceData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'url': _urlController.text.trim(),
        'category': _selectedCategory,
        'tags': tags,
        'isActive': _isActive,
        'order': int.tryParse(_orderController.text) ?? 0,
        'createdBy': adminId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/resources'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(resourceData),
      );

      if (response.statusCode == 201) {
        _clearForm();
        _fetchResources();
        _fetchStats();
        Navigator.of(context).pop();
        _showSuccess('Resource created successfully');
      } else {
        final data = json.decode(response.body);
        _showError(data['message'] ?? 'Failed to create resource');
      }
    } catch (e) {
      print('Error creating resource: $e');
      _showError('Error creating resource');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _toggleResourceStatus(String resourceId) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/resources/$resourceId/toggle'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchResources();
        _fetchStats();
        _showSuccess('Resource status updated');
      } else {
        _showError('Failed to update resource status');
      }
    } catch (e) {
      print('Error toggling resource status: $e');
      _showError('Error updating resource status');
    }
  }

  Future<void> _deleteResource(String resourceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Resource'),
        content: Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/resources/$resourceId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchResources();
        _fetchStats();
        _showSuccess('Resource deleted successfully');
      } else {
        _showError('Failed to delete resource');
      }
    } catch (e) {
      print('Error deleting resource: $e');
      _showError('Error deleting resource');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _urlController.clear();
    _tagsController.clear();
    _orderController.clear();
    setState(() {
      _selectedType = 'youtube';
      _selectedCategory = 'training';
      _isActive = true;
    });
  }

  void _showCreateDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'Create New Resource',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _resourceTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category['value'],
                            child: Text(category['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'URL *',
                          hintText: 'https://...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          hintText: 'tag1, tag2, tag3',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _orderController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Display Order',
                                hintText: '0',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() => _isActive = value ?? true);
                                  },
                                ),
                                Text('Active'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createResource,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isCreating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Create Resource'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
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
            backgroundColor: AppColors.accentGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Resource Management',
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
                      AppColors.accentGreen,
                      AppColors.accentGreen.withOpacity(0.7),
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
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _showCreateDialog,
                tooltip: 'Create Resource',
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _fetchResources();
                  _fetchStats();
                },
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resource Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Resources',
                        _stats['total']?.toString() ?? '0',
                        Icons.library_books,
                        AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Active',
                        _stats['active']?.toString() ?? '0',
                        Icons.check_circle,
                        AppColors.accentGreen,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Inactive',
                        _stats['inactive']?.toString() ?? '0',
                        Icons.pause_circle,
                        Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filters Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilter,
                      decoration: InputDecoration(
                        labelText: 'Filter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Resources')),
                        DropdownMenuItem(value: 'active', child: Text('Active Only')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive Only')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedFilter = value!);
                        _fetchResources();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      // TODO: Implement search
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resources List
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: _isLoading
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
                                'No resources found',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
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
          if (_totalPages > 1)
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
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    final typeLabel = _resourceTypes.firstWhere(
      (type) => type['value'] == resource.type,
      orElse: () => {'label': resource.type},
    )['label'];

    final categoryLabel = _categories.firstWhere(
      (category) => category['value'] == resource.category,
      orElse: () => {'label': resource.category},
    )['label'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                            typeLabel!,
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
                            categoryLabel!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!resource.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Inactive',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'toggle':
                      _toggleResourceStatus(resource.id);
                      break;
                    case 'delete':
                      _deleteResource(resource.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(resource.isActive ? 'Deactivate' : 'Activate'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
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
            children: [
              IconButton(
                icon: Icon(Icons.open_in_new, color: AppColors.primaryBlue),
                onPressed: () {
                  // TODO: Open URL
                },
                tooltip: 'Open Resource',
              ),
              const Spacer(),
              Text(
                'Order: ${resource.order}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}