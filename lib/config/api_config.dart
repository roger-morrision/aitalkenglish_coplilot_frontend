class ApiConfig {
  // Change this to your deployed backend URL
  static const String productionBackendUrl = 'https://your-backend-url.onrender.com';
  static const String developmentBackendUrl = 'http://localhost:3000';
  
  // Set to true when deploying to production
  static const bool useProduction = false;
  
  static String get baseUrl {
    return useProduction ? productionBackendUrl : developmentBackendUrl;
  }
}
