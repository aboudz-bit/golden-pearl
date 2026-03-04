// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Golden Pearl';

  @override
  String get home => 'Home';

  @override
  String get shop => 'Shop';

  @override
  String get cart => 'Cart';

  @override
  String get settings => 'Settings';

  @override
  String get orders => 'Orders';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get heroTitle => 'Elegance Redefined';

  @override
  String get heroSubtitle =>
      'Discover our latest collection of handcrafted luxury fashion';

  @override
  String get newCollection => 'New Collection 2026';

  @override
  String get exploreCollection => 'Explore Collection';

  @override
  String get shopNow => 'Shop Now';

  @override
  String get categories => 'Categories';

  @override
  String get dresses => 'Dresses';

  @override
  String get jalabiyas => 'Jalabiyas';

  @override
  String get kids => 'Kids';

  @override
  String get gifts => 'Gifts';

  @override
  String get all => 'All';

  @override
  String get featuredPieces => 'Featured Pieces';

  @override
  String get viewAll => 'View All';

  @override
  String get addToBag => 'Add to Cart';

  @override
  String get addedToBag => 'Added to cart';

  @override
  String get size => 'Size';

  @override
  String get color => 'Color';

  @override
  String get quantity => 'Quantity';

  @override
  String get description => 'Description';

  @override
  String get fabricCare => 'Fabric & Care';

  @override
  String get selectSize => 'Select Size';

  @override
  String get selectColor => 'Select Color';

  @override
  String get price => 'Price';

  @override
  String get sortBy => 'Sort';

  @override
  String get newest => 'Newest';

  @override
  String get priceLowHigh => 'Price: Low to High';

  @override
  String get priceHighLow => 'Price: High to Low';

  @override
  String get bestSellers => 'Best Sellers';

  @override
  String get filterBy => 'Filter By';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get noProducts => 'No products found';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get yourBag => 'Your Cart';

  @override
  String get emptyBag => 'Your cart is empty';

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get shipping => 'Shipping';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get freeShipping => 'Free';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get checkout => 'Checkout';

  @override
  String get shippingAddress => 'Shipping Address';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get country => 'Country';

  @override
  String get discountCode => 'Discount Code';

  @override
  String get apply => 'Apply';

  @override
  String get invalidCode => 'Invalid discount code';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get orderConfirmed => 'Order Confirmed!';

  @override
  String get orderConfirmedMessage =>
      'Thank you for your order. You will receive a confirmation email shortly.';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get orderHistory => 'Order History';

  @override
  String get noOrders => 'No Orders';

  @override
  String get pending => 'Pending';

  @override
  String get paid => 'Paid';

  @override
  String get processing => 'Processing';

  @override
  String get shipped => 'Shipped';

  @override
  String get delivered => 'Delivered';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get remove => 'Remove';

  @override
  String get clearAll => 'Clear All';

  @override
  String get confirmRemove => 'Remove this item?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get networkError => 'Network error. Please try again.';

  @override
  String get required => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get shippingInfo => 'Free shipping on orders over SAR 560';

  @override
  String get returnPolicy => '30-day return policy';

  @override
  String get securePayment => 'Secure payment';

  @override
  String get handcrafted => 'Handcrafted with love';

  @override
  String get eidCollection => 'Eid Collection';

  @override
  String get newDrop => 'New Drop';

  @override
  String get aboutBrand =>
      'Luxury fashion house specializing in handcrafted embroidered pieces';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String orderStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get welcomeDiscount =>
      'Use code WELCOME10 for 10% off your first order';

  @override
  String get sizeGuide => 'Size Guide';

  @override
  String get wishlist => 'Wishlist';

  @override
  String reviews(int count) {
    return '$count Reviews';
  }

  @override
  String get deliveryMethod => 'Delivery Method';

  @override
  String get deliveryToAddress => 'Deliver to Address';

  @override
  String get delivery => 'Delivery';

  @override
  String get storePickup => 'Store Pickup';

  @override
  String get selectStore => 'Select Store';

  @override
  String get noStoresAvailable => 'No stores available at the moment';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get fulfillment => 'Fulfillment';

  @override
  String get pickupInstructions => 'Pickup Instructions';

  @override
  String get pickupIdRequired => 'Valid ID is required for pickup';

  @override
  String get pickupOrderNumber => 'Show your order confirmation number';

  @override
  String get pickupReadyTime => 'Your order will be ready within 24 hours';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get readyForPickup => 'Ready for Pickup';

  @override
  String get pickedUp => 'Picked Up';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get call => 'Call';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get selectCity => 'Select City';

  @override
  String get searchCountry => 'Search country...';

  @override
  String get searchCity => 'Search city...';

  @override
  String get selectCountryFirst => 'Please select a country first';

  @override
  String get noResults => 'No results found';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get myOrders => 'My Orders';

  @override
  String get storeHours => 'Working Hours';

  @override
  String get storeName => 'Golden Pearl - Saihat';

  @override
  String get storeAddress => 'Saihat 32437, Eastern Province';

  @override
  String get storePhone => '055 501 2942';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get password => 'Password';

  @override
  String get loginToProceed => 'Login to proceed with checkout';

  @override
  String get createAccount => 'Create a new account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get loginSuccess => 'Logged in successfully';

  @override
  String get registerSuccess => 'Account created successfully';

  @override
  String get logoutSuccess => 'Logged out successfully';

  @override
  String get logout => 'Logout';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get products => 'Products';

  @override
  String get analytics => 'Analytics';

  @override
  String get adminSettings => 'Settings';

  @override
  String get totalVisits => 'Total Visits';

  @override
  String get uniqueSessions => 'Unique Sessions';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get addProduct => 'Add Product';

  @override
  String get manageOrders => 'Manage Orders';

  @override
  String get manageBanners => 'Manage Banners';

  @override
  String get viewAnalytics => 'View Analytics';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get stock => 'Stock';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get heroBanner => 'Hero Banner Image';

  @override
  String get imageUrlHint => 'Enter image URL...';

  @override
  String get topProducts => 'Top Viewed Products';

  @override
  String get views => 'views';

  @override
  String get notes => 'Notes';

  @override
  String get account => 'Account';

  @override
  String get welcomeBack => 'Welcome';

  @override
  String get edit => 'Edit';

  @override
  String get customers => 'Customers';

  @override
  String get searchCustomers => 'Search by name, email, phone...';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get lastOrder => 'Last Order';

  @override
  String get registered => 'Registered';

  @override
  String get hasOrders => 'Has Orders';

  @override
  String get allCustomers => 'All Customers';

  @override
  String get newestFirst => 'Newest';

  @override
  String get highestSpent => 'Highest Spent';

  @override
  String get mostOrders => 'Most Orders';

  @override
  String get lastOrderDate => 'Last Order Date';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get currentCart => 'Current Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get exportList => 'Export List';

  @override
  String get exportCustomer => 'Export Report';

  @override
  String get customerInfo => 'Customer Info';

  @override
  String get itemsCount => 'Items';

  @override
  String get notifyCustomer => 'Notify Customer';

  @override
  String get sendCartNotification => 'Send cart notification';

  @override
  String get arabicMessage => 'Arabic message';

  @override
  String get englishMessage => 'English message (optional)';

  @override
  String get send => 'Send';

  @override
  String get cartWaitingTemplate =>
      'Your cart is waiting — complete your order';

  @override
  String get itemsMaySellOutTemplate => 'Items in your cart may sell out';

  @override
  String get notificationSent => 'Notification sent successfully';

  @override
  String get notificationFailed => 'Failed to send notification';

  @override
  String get quickTemplates => 'Quick templates';

  @override
  String get currentStatus => 'Current status';

  @override
  String get items => 'Items';

  @override
  String get deliveryFee => 'Delivery fee';

  @override
  String get trackingNumber => 'Tracking number';

  @override
  String get confirm => 'Confirm';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get confirmLogout => 'Confirm Logout';
}
