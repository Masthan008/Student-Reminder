class ValidationUtils {
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Password validation
  static bool isValidPassword(String password) {
    // At least 6 characters
    return password.length >= 6;
  }

  // Strong password validation
  static bool isStrongPassword(String password) {
    // At least 8 characters, contains uppercase, lowercase, number
    final strongPasswordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
    );
    return strongPasswordRegex.hasMatch(password);
  }

  // Name validation
  static bool isValidName(String name) {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty && trimmedName.length >= 2;
  }

  // Title validation for reminders
  static bool isValidReminderTitle(String title) {
    final trimmedTitle = title.trim();
    return trimmedTitle.isNotEmpty && trimmedTitle.length <= 100;
  }

  // Description validation for reminders
  static bool isValidReminderDescription(String description) {
    return description.length <= 500;
  }

  // Date validation for reminders
  static bool isValidReminderDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return date.isAfter(yesterday);
  }

  // Get email validation error message
  static String? getEmailError(String email) {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Get password validation error message
  static String? getPasswordError(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (!isValidPassword(password)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Get name validation error message
  static String? getNameError(String name) {
    if (name.trim().isEmpty) {
      return 'Name is required';
    }
    if (!isValidName(name)) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Get reminder title validation error message
  static String? getReminderTitleError(String title) {
    if (title.trim().isEmpty) {
      return 'Title is required';
    }
    if (!isValidReminderTitle(title)) {
      return 'Title must be between 1 and 100 characters';
    }
    return null;
  }

  // Get reminder description validation error message
  static String? getReminderDescriptionError(String description) {
    if (!isValidReminderDescription(description)) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  // Get reminder date validation error message
  static String? getReminderDateError(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    if (!isValidReminderDate(date)) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  // Sanitize input text
  static String sanitizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Check if string contains only alphanumeric characters and spaces
  static bool isAlphanumericWithSpaces(String text) {
    final regex = RegExp(r'^[a-zA-Z0-9\s]+$');
    return regex.hasMatch(text);
  }

  // Check if string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Validate phone number (basic validation)
  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phoneNumber.trim());
  }

  // Get phone number validation error message
  static String? getPhoneNumberError(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) {
      return null; // Phone number is optional
    }
    if (!isValidPhoneNumber(phoneNumber)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}