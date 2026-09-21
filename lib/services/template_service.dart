import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Get all industry templates
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final snapshot = await _firestore.collection('templates').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting templates: $e');
      return _getDefaultTemplates();
    }
  }

  // Get templates by industry
  Future<List<Map<String, dynamic>>> getTemplatesByIndustry(String industry) async {
    try {
      final snapshot = await _firestore
          .collection('templates')
          .where('industry', isEqualTo: industry)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return _getDefaultTemplates().where((t) => t['industry'] == industry).toList();
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting templates by industry: $e');
      return _getDefaultTemplates().where((t) => t['industry'] == industry).toList();
    }
  }

  // Use template for practice session
  Future<Map<String, dynamic>> useTemplate(String templateId) async {
    try {
      final templateDoc = await _firestore.collection('templates').doc(templateId).get();
      if (!templateDoc.exists) {
        throw Exception('Template not found');
      }

      final template = templateDoc.data()!;
      
      // Create session from template
      return {
        'templateId': templateId,
        'templateName': template['name'],
        'industry': template['industry'],
        'questions': template['questions'] ?? [],
        'scenarios': template['scenarios'] ?? [],
      };
    } catch (e) {
      debugPrint('Error using template: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getDefaultTemplates() {
    return [
      {
        'id': 'tech_software',
        'name': 'Software Engineering Interview',
        'industry': 'Technology',
        'description': 'Practice technical interviews for software engineering roles',
        'questions': [
          'Explain your approach to solving complex technical problems',
          'Describe a challenging project you worked on',
          'How do you handle code reviews and feedback?',
        ],
        'scenarios': [
          'System design interview',
          'Coding challenge',
          'Behavioral questions',
        ],
      },
      {
        'id': 'finance_analyst',
        'name': 'Financial Analyst Interview',
        'industry': 'Finance',
        'description': 'Practice for financial analyst positions',
        'questions': [
          'How do you analyze financial data?',
          'Describe your experience with financial modeling',
          'How do you stay updated with market trends?',
        ],
        'scenarios': [
          'Case study analysis',
          'Technical questions',
          'Market discussion',
        ],
      },
      {
        'id': 'healthcare_doctor',
        'name': 'Medical Professional Interview',
        'industry': 'Healthcare',
        'description': 'Practice for healthcare professional interviews',
        'questions': [
          'Describe your approach to patient care',
          'How do you handle difficult medical cases?',
          'Explain your experience with medical procedures',
        ],
        'scenarios': [
          'Clinical scenarios',
          'Ethical dilemmas',
          'Patient communication',
        ],
      },
      {
        'id': 'business_manager',
        'name': 'Business Management Interview',
        'industry': 'Business',
        'description': 'Practice for management and leadership roles',
        'questions': [
          'Describe your leadership style',
          'How do you handle team conflicts?',
          'Explain your strategic planning approach',
        ],
        'scenarios': [
          'Leadership scenarios',
          'Team management',
          'Business strategy',
        ],
      },
    ];
  }
}

