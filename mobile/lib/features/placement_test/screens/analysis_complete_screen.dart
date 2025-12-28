import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';

class AnalysisCompleteScreen extends StatefulWidget {
  final String testId;

  const AnalysisCompleteScreen({
    super.key,
    required this.testId,
  });

  @override
  State<AnalysisCompleteScreen> createState() => _AnalysisCompleteScreenState();
}

class _AnalysisCompleteScreenState extends State<AnalysisCompleteScreen> {
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getTestAnalysis(widget.testId);
      
      // Debug: Print data to see what we're getting
      print('📊 Analysis data: $data');
      print('📊 subjectId: ${data['subjectId']}');
      
      setState(() {
        _analysisData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Analysis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalysis,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _analysisData == null
                  ? const Center(child: Text('No analysis data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Score Card
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Text(
                                    'Your Score',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_analysisData!['score'] ?? 0}%',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Level: ${_analysisData!['level'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Strengths
                          if (_analysisData!['strengths'] != null) ...[
                            const Text(
                              'Strengths',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              (_analysisData!['strengths'] as List).length,
                              (index) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.green.shade50,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  title: Text(
                                    (_analysisData!['strengths'] as List)[index],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Weaknesses
                          if (_analysisData!['weaknesses'] != null) ...[
                            const Text(
                              'Areas for Improvement',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              (_analysisData!['weaknesses'] as List).length,
                              (index) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.orange.shade50,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    (_analysisData!['weaknesses'] as List)[index],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Action Buttons
                          Builder(
                            builder: (context) {
                              // Get subjectId directly from test result (API returns PlacementTest entity directly)
                              final subjectId = _analysisData!['subjectId'] as String?;
                              
                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.go('/dashboard');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Dashboard'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (mounted) {
                                          if (subjectId != null && subjectId.isNotEmpty) {
                                            // Test đã có subjectId từ onboarding
                                            // Skill tree đã được tự động tạo ở backend
                                            // Navigate trực tiếp đến skill tree để xem tổng quan
                                            context.go('/skill-tree?subjectId=$subjectId');
                                          } else {
                                            // Không có subjectId, cho user chọn môn học
                                            context.go('/subjects');
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: Text(
                                        subjectId != null && subjectId.isNotEmpty
                                            ? 'Xem Skill Tree'
                                            : 'Chọn môn học',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}

