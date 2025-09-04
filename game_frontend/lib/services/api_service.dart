import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/goal_validation.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _apiVersion = '/api/v1';
  
  static ApiService? _instance;
  
  ApiService._();
  
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// Validate a financial goal using the AI backend
  Future<GoalValidationResponse> validateGoal(GoalValidationRequest request) async {
    final url = Uri.parse('$_baseUrl$_apiVersion/validate-goal');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw GoalValidationException(
            'Request timed out. Please check your connection and try again.',
          );
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return GoalValidationResponse.fromJson(jsonData);
      } else if (response.statusCode == 422) {
        // Validation error from FastAPI
        final errorData = jsonDecode(response.body);
        throw GoalValidationException(
          'Invalid request: ${errorData['detail'] ?? 'Please check your input'}',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw GoalValidationException(
          'Server error. Please try again later.',
          statusCode: response.statusCode,
        );
      } else {
        throw GoalValidationException(
          'Failed to validate goal. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('DEBUG: SocketException details: $e');
      print('DEBUG: Trying to connect to: $_baseUrl$_apiVersion/validate-goal');
      throw GoalValidationException(
        'Cannot connect to server. Please make sure the AI backend is running on ${'$_baseUrl'}. Error: ${e.message}',
      );
    } on http.ClientException {
      throw GoalValidationException(
        'Network error. Please check your connection and try again.',
      );
    } on FormatException {
      throw GoalValidationException(
        'Invalid response from server. Please try again.',
      );
    } catch (e) {
      if (e is GoalValidationException) {
        rethrow;
      }
      throw GoalValidationException(
        'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Check if the backend API is available
  Future<bool> isBackendAvailable() async {
    final url = Uri.parse('$_baseUrl$_apiVersion/health');
    
    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get the backend URL for debugging
  String get backendUrl => _baseUrl;
}