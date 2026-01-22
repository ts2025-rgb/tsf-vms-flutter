# API Configuration Guide

## Overview
This Flutter app uses a centralized API configuration system to easily switch between development (ngrok) and production (Koyeb) environments.

## Configuration File
Location: `lib/config/api_config.dart`

## How to Switch Environments

### For Development (ngrok):
1. Open `lib/config/api_config.dart`
2. Set `kIsDebug = true`
3. The app will use: `https://shrew-concrete-cobra.ngrok-free.app`

### For Production (Koyeb):
1. Open `lib/config/api_config.dart`
2. Set `kIsDebug = false`
3. The app will use: `https://frantic-mable-saluman-ef0457fa.koyeb.app`

## Current Configuration
- **Debug URL (ngrok)**: `https://shrew-concrete-cobra.ngrok-free.app`
- **Production URL (Koyeb)**: `https://frantic-mable-saluman-ef0457fa.koyeb.app`
- **Current Mode**: Debug (kIsDebug = true)

## Important Notes
1. **Remember to rebuild** the app after changing the configuration
2. The configuration affects ALL API calls throughout the app
3. To update the ngrok URL when it changes, edit only the `_debugBaseUrl` constant in `api_config.dart`
4. To update the production URL, edit only the `_productionBaseUrl` constant

## Files Using This Configuration
All network requests in the following files now use `ApiConfig.apiUrl`:
- `lib/admin.dart`
- `lib/admin_login_screen.dart`
- `lib/admin_mentee_management.dart`
- `lib/admin_query_management.dart`
- `lib/companionconnect.dart`
- `lib/create_mentee_page.dart`
- `lib/home_screen.dart`
- `lib/login_screen.dart`
- `lib/profile_screen.dart`
- `lib/register_screen.dart`
- `lib/services/vms_service.dart`

## Example Usage
```dart
import 'config/api_config.dart';

// Get current API URL
final String baseUrl = ApiConfig.apiUrl;

// Make API call
final response = await http.get(
  Uri.parse('$baseUrl/endpoint'),
);
```

## For Quick Deployment
When deploying to production, ensure you:
1. Set `kIsDebug = false`
2. Build the release version
3. Deploy
