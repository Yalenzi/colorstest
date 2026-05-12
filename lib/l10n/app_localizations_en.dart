import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitleWithIcon => '⚙️ Settings';

  @override
  String get errorLoadingSettings => 'Error loading settings';

  @override
  String get retry => 'Retry';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSubtitle => 'Choose your preferred theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get language => 'Language';

  @override
  String get appLanguage => 'App Language';

  @override
  String get appLanguageSubtitle => 'Select your preferred language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle => 'Receive notifications about test results';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationSubtitle => 'Vibrate on notifications and interactions';

  @override
  String get about => 'About';

  @override
  String get developers => 'Developers';

  @override
  String get developersSubtitle => 'Meet the team behind this app';

  @override
  String get version => 'Version';

  @override
  String get comingSoonTitle => '🚧 Coming Soon';

  @override
  String comingSoonContent(Object feature) {
    return '$feature functionality will be implemented soon!';
  }

  @override
  String get ok => 'OK';

  @override
  String get developersDialogTitle => 'Developers';

  @override
  String get reagentTestingApp => 'ReagentKit';

  @override
  String get theDevelopers => 'Developers';

  @override
  String get developerOneName => 'يوسف مسير العنزي';

  @override
  String get developerTwoName => ' محمد نفاع الرويلي';

  @override
  String get aboutTheApp => '🧪 About the App:';

  @override
  String get aboutTheAppContent => 'This app helps users safely test substances using chemical reagents.';

  @override
  String get contact => '📧 Contact:testscolors@gmail.com';

  @override
  String get reagentTesting => 'Reagent Testing';

  @override
  String get searchReagents => 'Search reagents...';

  @override
  String get clear => 'Clear';

  @override
  String get initializingReagentData => 'Initializing reagent data...';

  @override
  String get loadingReagents => 'Loading reagents...';

  @override
  String get errorLoadingReagents => 'Error Loading Reagents';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noReagentsAvailable => 'No Reagents Available';

  @override
  String get unableToLoadReagentData => 'Unable to load reagent data from assets.\nPlease check your internet connection and try again.';

  @override
  String get retryLoading => 'Retry Loading';

  @override
  String testing(Object reagentName) {
    return 'Testing $reagentName';
  }

  @override
  String duration(Object duration) {
    return 'Duration: $duration min';
  }

  @override
  String get safetyLevel => 'Safety Level';

  @override
  String get readyToStart => 'Ready to Start Testing';

  @override
  String get readyToStartDescription => 'Please ensure you have read and understood all safety instructions before proceeding with the test.';

  @override
  String get testProcedure => 'Test Procedure';

  @override
  String step(Object stepNumber) {
    return 'Step $stepNumber';
  }

  @override
  String get reactionTimer => 'Reaction Timer';

  @override
  String get startTimer => 'Start Timer';

  @override
  String get stopTimer => 'Stop Timer';

  @override
  String get resetTimer => 'Reset Timer';

  @override
  String get timerRunning => 'Timer Running';

  @override
  String get observedColor => 'Observed Color';

  @override
  String get observedColorDescription => 'Select the color you observed after adding the reagent';

  @override
  String get tapColorInstruction => 'Tap the color that best matches what you observed';

  @override
  String get testNotes => 'Test Notes';

  @override
  String get testNotesPlaceholder => 'Add any additional observations or notes about the test...';

  @override
  String get completeTest => 'Complete Test';

  @override
  String get completeTestDescription => 'Review your observations and complete the test';

  @override
  String get goBack => 'Go Back';

  @override
  String get unknownState => 'Unknown state';

  @override
  String get safetyInformation => 'Safety Information';

  @override
  String get chemicalComponents => 'Chemical Components';

  @override
  String get testInstructions => 'Test Instructions';

  @override
  String get references => 'Scientific References';

  @override
  String get safetyAcknowledgment => 'Safety Acknowledgment';

  @override
  String get safetyAcknowledgmentText => 'I have read and understand all safety instructions and will follow proper safety procedures during testing.';

  @override
  String get startTest => 'Start Test';

  @override
  String get safetyAcknowledgmentRequired => 'Safety Acknowledgment Required';

  @override
  String get equipment => 'Required Equipment';

  @override
  String get handlingProcedures => 'Handling Procedures';

  @override
  String get specificHazards => 'Specific Hazards';

  @override
  String get storage => 'Storage Requirements';

  @override
  String get testResults => 'Test Results';

  @override
  String get testHistory => 'Test History';

  @override
  String get statistics => 'Statistics';

  @override
  String get loading => 'Loading...';

  @override
  String error(Object message) {
    return 'Error: $message';
  }

  @override
  String get noTestResultsYet => 'No test results yet';

  @override
  String get completeTestsToSeeHistory => 'Complete some tests to see your history here';

  @override
  String get searchBySubstanceOrNotes => 'Search by substance or notes...';

  @override
  String get filterByReagent => 'Filter by reagent:';

  @override
  String get all => 'All';

  @override
  String get totalTests => 'Total Tests';

  @override
  String get testsByReagent => 'Tests by Reagent';

  @override
  String get averageConfidence => 'Average Confidence';

  @override
  String get mostUsedReagent => 'Most Used Reagent';

  @override
  String confidenceWithPercentage(Object confidence) {
    return 'Confidence: $confidence%';
  }

  @override
  String get possibleSubstances => 'Possible Substances';

  @override
  String get notes => 'Notes';

  @override
  String get testResult => 'Test Result';

  @override
  String get reagent => 'Reagent';

  @override
  String get observedColorLabel => 'Observed Color';

  @override
  String get testDate => 'Test Date';

  @override
  String get deleteTestResult => 'Delete Test Result';

  @override
  String deleteConfirmation(Object reagentName) {
    return 'Are you sure you want to delete this $reagentName test result?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get refresh => 'Refresh';

  @override
  String get noTestHistory => 'No test results yet';

  @override
  String get noTestHistoryDescription => 'Complete some tests to see your history here';

  @override
  String get deleteTest => 'Delete Test Result';

  @override
  String get deleteTestConfirmation => 'Are you sure you want to delete this test result?';

  @override
  String get confirmExit => 'Confirm Exit';

  @override
  String get testProgressWillBeLost => 'Your test progress will be lost. Are you sure you want to exit?';

  @override
  String get exit => 'Exit';

  @override
  String get loadingTestHistory => 'Loading test history...';

  @override
  String get errorLoadingHistory => 'Error loading test history';

  @override
  String get testSummary => 'Test Summary';

  @override
  String get uniqueReagents => 'Unique Reagents';

  @override
  String get recentTests => 'Recent Tests';

  @override
  String get confidence => 'Confidence';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get daysAgo => 'days ago';

  @override
  String get syncToCloud => 'Sync to Cloud';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get syncingToCloud => 'Syncing to cloud...';

  @override
  String get clearAllConfirmation => 'Are you sure you want to clear all test results? This action cannot be undone.';

  @override
  String get clearAll => 'Clear All';

  @override
  String get captureImage => 'Capture Image';

  @override
  String get captureImageDescription => 'Take a photo of your test result for AI analysis';

  @override
  String get analyzeWithAI => 'Analyze with AI';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get aiAnalysisResult => 'AI Analysis Result';

  @override
  String get aiAnalysisError => 'AI Analysis Error';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get aiSuggestion => 'AI Suggestion';

  @override
  String get confidenceLevel => 'Confidence Level';

  @override
  String get possibleMatches => 'Possible Matches';

  @override
  String get analysisNotes => 'Analysis Notes';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get extreme => 'Extreme';

  @override
  String get noColorChange => 'No color change';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get unknownSubstance => 'Unknown substance or impure sample';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get fromGallery => 'From Gallery';

  @override
  String get uploadImageDescription => 'Upload an image of your test result for AI analysis';

  @override
  String get red => 'Red';

  @override
  String get darkRed => 'Dark Red';

  @override
  String get orange => 'Orange';

  @override
  String get redOrange => 'Red-Orange';

  @override
  String get yellow => 'Yellow';

  @override
  String get lightYellow => 'Light Yellow';

  @override
  String get green => 'Green';

  @override
  String get paleGreen => 'Pale Green';

  @override
  String get blue => 'Blue';

  @override
  String get purple => 'Purple';

  @override
  String get violet => 'Violet';

  @override
  String get magenta => 'Magenta';

  @override
  String get pink => 'Pink';

  @override
  String get brown => 'Brown';

  @override
  String get brownish => 'Brownish';

  @override
  String get black => 'Black';

  @override
  String get grey => 'Grey';

  @override
  String get lightBlue => 'Light Blue';

  @override
  String get lightGreen => 'Light Green';

  @override
  String get darkBlue => 'Dark Blue';

  @override
  String get darkGreen => 'Dark Green';

  @override
  String get olive => 'Olive';

  @override
  String get greenishBrown => 'Greenish Brown';

  @override
  String get maroon => 'Maroon';

  @override
  String get navy => 'Navy';

  @override
  String get teal => 'Teal';

  @override
  String get clearNoChange => 'Clear/No change';

  @override
  String get category => 'Category';

  @override
  String get primaryTests => 'Primary Tests';

  @override
  String get secondaryTests => 'Secondary Tests';

  @override
  String get specializedTests => 'Specialized Tests';

  @override
  String get laboratoryProfile => 'Laboratory Profile';

  @override
  String get labAccess => 'Lab Access';

  @override
  String get joinLaboratory => 'Join Laboratory';

  @override
  String get laboratoryTechnician => 'Laboratory Technician';

  @override
  String get verified => 'Verified';

  @override
  String get pending => 'Pending';

  @override
  String get testingStatistics => 'Testing Statistics';

  @override
  String get testsPerformed => 'Tests Performed';

  @override
  String get reagentsUsed => 'Reagents Used';

  @override
  String get successRate => 'Success Rate';

  @override
  String get labHours => 'Lab Hours';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get dayAgo => 'day ago';

  @override
  String get safetyReminder => 'Safety Reminder';

  @override
  String get safetyReminderText => 'Always wear protective equipment when handling reagents. Ensure proper ventilation and follow safety protocols.';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get memberSince => 'Member Since';

  @override
  String get signOut => 'Sign Out';

  @override
  String get welcomeBack => 'Welcome';

  @override
  String get joinOurLab => 'Join Our Lab';

  @override
  String get accessYourLab => 'Access your reagent testing laboratory';

  @override
  String get startYourJourney => 'Start your journey in substance analysis';

  @override
  String get loginMode => 'Login';

  @override
  String get registerMode => 'Register';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveLabAccess => 'Don\'t have lab access?';

  @override
  String get alreadyHaveLabAccess => 'Already have lab access?';

  @override
  String get joinNow => 'Join Now';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get accessLaboratory => 'Access Laboratory';

  @override
  String get signingIn => 'Signing In...';

  @override
  String get creatingAccount => 'Creating Account...';

  @override
  String get pleaseEnterUsername => 'Please enter a username';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String get usernameInvalidChars => 'Username can only contain letters, numbers, and underscores';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordTitle => 'Reset Your Password';

  @override
  String get resetPasswordDescription => 'Enter your email address and we\'ll send you instructions to reset your password.';

  @override
  String get sendResetEmail => 'Send Reset Email';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get enterEmailToReset => 'Enter your email address to reset your password';

  @override
  String get passwordResetEmailSent => 'Password reset email sent! Check your inbox.';

  @override
  String get resetEmailSending => 'Sending reset email...';

  @override
  String get useAiResults => 'Use AI Results';

  @override
  String get aiResultsApplied => 'AI color selection applied successfully!';
}
