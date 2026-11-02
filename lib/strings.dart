// lib/strings.dart
// Every user-facing string lives here so it is easy to translate later.
class AppStrings {
  static const appName = 'EventHub';

  // Login
  static const loginTitle = 'Log in';
  static const emailLabel = 'Email';
  static const passwordLabel = 'Password';
  static const forgotPassword = 'Forgot password?';
  static const noAccount = "Don't have an account? Sign up";
  static const sendResetLink = 'Send reset link';
  static const resetEmailSent = 'Password reset email sent. Check your inbox.';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';

  // Sign up
  static const signUpTitle = 'Create account';
  static const firstNameLabel = 'First name';
  static const lastNameLabel = 'Last name';
  static const studentNumberLabel = 'Student number';
  static const contactNumberLabel = 'Contact number';
  static const schoolEmailLabel = 'School email or Gmail';
  static const confirmPasswordLabel = 'Confirm password';
  static const createAccount = 'Create account';
  static const passwordMismatch = 'Passwords do not match.';
  static const firstNameRequired = 'Enter your first name.';
  static const lastNameRequired = 'Enter your last name.';
  static const invalidStudentNumber =
      'Student number must be exactly 10 digits.';
  static const invalidContactNumber = 'Contact number must be 10 to 13 digits.';
  static const contactNumberMustStartWith63 =
      'A 13-digit contact number must start with 63.';
  static const studentNumberTaken = 'That student number is already registered.';
  static const strongPassword =
      'Use 8+ characters with a capital letter, a small letter, a number, and a special character.';
  static String inDays(int days) => 'In $days days';
  static String reminderLead(int minutes) => 'Reminder lead time: $minutes minutes';

  // Events
  static const eventsTab = 'Events';
  static const myEventsTab = 'My Events';
  static const profileTab = 'Profile';
  static const allCategory = 'All';
  static const noUpcomingEvents = 'No upcoming events';
  static const noUpcomingEventsHint = 'Check back later for new school events.';
  static const couldNotLoadEvents = 'Could not load events.';
  static const retry = 'Retry';
  static const offlineNotice = 'You are offline. Showing saved events.';
  static const openInMaps = 'Open in Maps';
  static const unknownCategory = 'Uncategorized';

  // Details
  static const eventDetails = 'Event Details';
  static const description = 'Description';
  static const dateLabel = 'Date';
  static const timeLabel = 'Time';
  static const venueLabel = 'Venue';
  static const organizerLabel = 'Organizer';
  static const capacityLabel = 'Capacity';
  static const register = 'Register';
  static const registered = 'Registered ✓';
  static const cancelRegistration = 'Cancel Registration';
  static const eventFull = 'Event Full';
  static const eventEnded = 'Event Ended';
  static const unlimitedSlots = 'Unlimited slots';
  static const slotsLeft = 'slots left';
  static const reminder = 'Remind me 1 hour before';
  static const remindersOff = 'Reminders are off. Enable notifications in your phone settings.';
  static const reminderUpdateFailed = 'Could not update the reminder.';

  // Registration
  static const registrationSuccess = 'You are registered. See you there!';
  static const registrationFailed = "Couldn't register. Check your connection.";
  static const cancelSuccess = 'Registration cancelled.';
  static const cancelFailed = 'Could not cancel the registration.';
  static const cancelConfirm = 'Cancel your registration for';
  static const yes = 'Yes';
  static const no = 'No';

  // My events
  static const upcomingTab = 'Upcoming';
  static const historyTab = 'History';
  static const noRegistrations = "You haven't registered for any events yet.";
  static const browseEvents = 'Browse events';
  static const noHistory = 'No past events yet.';
  static const eventCancelled = 'Event cancelled';
  static const today = 'Today';
  static const tomorrow = 'Tomorrow';

  // Profile / menu
  static const logout = 'Log out';
  static const darkMode = 'Dark mode';
  static const notificationsOn = 'Notifications: allowed';
  static const notificationsOff = 'Notifications: not allowed';

  // Errors
  static const wrongPassword = 'Wrong password. Try again.';
  static const invalidEmail = 'That email address is not valid.';
  static const emailInUse = 'That email is already in use.';
  static const weakPassword = 'Password is too weak. Try a longer one.';
  static const userNotFound = 'No account found for that email.';
  static const networkError = 'Network error. Check your connection.';
  static const tooManyRequests = 'Too many attempts. Try again later.';
  static const permissionError = 'You do not have permission to do that.';
  static const somethingWrong = 'Something went wrong. Try again.';
}
