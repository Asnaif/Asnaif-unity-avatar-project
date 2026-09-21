import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/services/template_service.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:interprep/common/resources/widgets/skeleton/skeleton_loader.dart';
import 'package:interprep/common/resources/widgets/empty_states/empty_state_widget.dart';
import 'package:interprep/common/resources/widgets/refresh/enhanced_refresh_indicator.dart';
import 'package:get/get.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TemplateService _templateService = TemplateService();
  List<Map<String, dynamic>> _templates = [];
  final List<String> _industries = ['All', 'Technology', 'Finance', 'Healthcare', 'Business'];
  String _selectedIndustry = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = _selectedIndustry == 'All'
          ? await _templateService.getTemplates()
          : await _templateService.getTemplatesByIndustry(_selectedIndustry);
      
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading templates: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Templates'),
        backgroundColor: Styles.primaryColor,
      ),
      body: Column(
        children: [
          _buildIndustryFilter(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _templates.isEmpty
                    ? _buildEmptyState()
                    : EnhancedRefreshIndicator(
                        onRefresh: _loadTemplates,
                        child: _buildTemplatesList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _industries.length,
        itemBuilder: (context, index) {
          final industry = _industries[index];
          final isSelected = _selectedIndustry == industry;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(industry),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedIndustry = industry;
                  _loadTemplates();
                });
              },
              selectedColor: Styles.primaryColor,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonLoader(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.description,
      title: 'No templates available',
      message: 'Practice templates will appear here once they are added to the system',
      iconColor: Colors.grey,
    );
  }

  Widget _buildTemplatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Styles.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIndustryIcon(template['industry'] as String? ?? ''),
                color: Styles.primaryColor,
                size: 32,
              ),
            ),
            title: Text(
              template['name'] ?? 'Template',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  template['description'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        template['industry'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${(template['questions'] as List?)?.length ?? 0} questions',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => _useTemplate(template),
            ),
          ),
        );
      },
    );
  }

  IconData _getIndustryIcon(String industry) {
    switch (industry.toLowerCase()) {
      case 'technology':
        return Icons.computer;
      case 'finance':
        return Icons.account_balance;
      case 'healthcare':
        return Icons.medical_services;
      case 'business':
        return Icons.business;
      default:
        return Icons.description;
    }
  }

  void _useTemplate(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Use ${template['name']}?'),
        content: Text(
          'This will start a practice session using the ${template['name']} template.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final sessionData = await _templateService.useTemplate(template['id']);
                // Navigate to practice session with template data
                Get.toNamed('/start_session', arguments: {
                  'template': sessionData,
                });
              } catch (e) {
                CustomToast.showError('Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.primaryColor,
            ),
            child: const Text('Start Practice'),
          ),
        ],
      ),
    );
  }
}

