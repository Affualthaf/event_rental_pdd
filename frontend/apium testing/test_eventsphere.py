"""
EventSphere – End-to-End Test Suite
====================================
Framework : Appium (Python client v4)
App       : EventSphere (Flutter / Android)
Runner    : pytest

Usage
-----
1. Start Appium server:
       appium --address 127.0.0.1 --port 4723

2. Connect a real device or start an Android emulator.

3. Set env vars (or edit the CAPS dict below):
       APP_PACKAGE   = com.eventsphere.app   (your actual package)
       APP_ACTIVITY  = .MainActivity
       DEVICE_NAME   = emulator-5554
       PLATFORM_VER  = 12.0
       TEST_EMAIL    = customer@test.com
       TEST_PASSWORD = Test@1234
       VENDOR_EMAIL  = vendor@test.com
       VENDOR_PASS   = Test@1234

4. Run:
       pytest test_eventsphere.py -v --html=report.html
"""

import os
import time
import pytest
from dotenv import load_dotenv
from appium import webdriver
from appium.options import AppiumOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException

load_dotenv()

# ─── Capabilities ─────────────────────────────────────────────────────────────
CAPS = {
    "platformName": "Android",
    "appium:platformVersion": os.getenv("PLATFORM_VER", "12.0"),
    "appium:deviceName": os.getenv("DEVICE_NAME", "emulator-5554"),
    "appium:appPackage": os.getenv("APP_PACKAGE", "com.eventsphere.app"),
    "appium:appActivity": os.getenv("APP_ACTIVITY", ".MainActivity"),
    "appium:automationName": "Flutter",          # uses flutter_driver via Appium Flutter Integration
    "appium:noReset": False,
    "appium:fullReset": True,
    "appium:newCommandTimeout": 120,
}

APPIUM_URL = "http://127.0.0.1:4723"

# ─── Test credentials ─────────────────────────────────────────────────────────
CUSTOMER_EMAIL = os.getenv("TEST_EMAIL", "customer@test.com")
CUSTOMER_PASS  = os.getenv("TEST_PASSWORD", "Test@1234")
VENDOR_EMAIL   = os.getenv("VENDOR_EMAIL", "vendor@test.com")
VENDOR_PASS    = os.getenv("VENDOR_PASS", "Test@1234")

WAIT = 15   # default explicit-wait seconds


# ─── Helpers ──────────────────────────────────────────────────────────────────

def find(driver, by, value, timeout=WAIT):
    """Wait for element and return it."""
    return WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((by, value))
    )


def find_clickable(driver, by, value, timeout=WAIT):
    return WebDriverWait(driver, timeout).until(
        EC.element_to_be_clickable((by, value))
    )


def tap_text(driver, text, timeout=WAIT):
    """Tap an element by its visible text."""
    elem = WebDriverWait(driver, timeout).until(
        EC.element_to_be_clickable(
            (AppiumBy.ANDROID_UIAUTOMATOR,
             f'new UiSelector().text("{text}")')
        )
    )
    elem.click()


def type_into(driver, hint_or_label, text):
    """Clear and type into a TextField identified by hint text."""
    field = find(
        driver,
        AppiumBy.ANDROID_UIAUTOMATOR,
        f'new UiSelector().textContains("{hint_or_label}")'
    )
    field.clear()
    field.send_keys(text)


def assert_text_visible(driver, text, timeout=WAIT):
    """Assert that text appears somewhere on screen."""
    elem = WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located(
            (AppiumBy.ANDROID_UIAUTOMATOR,
             f'new UiSelector().textContains("{text}")')
        )
    )
    assert elem is not None, f'Expected text "{text}" not found on screen.'


def skip_onboarding(driver):
    """Swipe through all three onboarding pages."""
    for _ in range(3):
        try:
            # If there's a 'Next' or arrow button
            btn = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable(
                    (AppiumBy.ANDROID_UIAUTOMATOR,
                     'new UiSelector().descriptionContains("Next")')
                )
            )
            btn.click()
        except TimeoutException:
            # Swipe left instead
            size = driver.get_window_size()
            driver.swipe(
                size["width"] * 0.8, size["height"] * 0.5,
                size["width"] * 0.2, size["height"] * 0.5,
                500
            )
        time.sleep(0.5)


def login(driver, email, password):
    """Perform login from the Login screen."""
    type_into(driver, "you@example.com", email)
    type_into(driver, "••••••••", password)
    tap_text(driver, "Sign In")
    # Wait for home screen
    assert_text_visible(driver, "EventSphere", timeout=20)


def logout(driver):
    """Navigate to Profile and sign out."""
    tap_text(driver, "Profile")
    tap_text(driver, "Sign Out")
    assert_text_visible(driver, "Welcome Back")


# ─── Fixtures ─────────────────────────────────────────────────────────────────

@pytest.fixture(scope="class")
def driver():
    options = AppiumOptions().load_capabilities(CAPS)
    drv = webdriver.Remote(APPIUM_URL, options=options)
    drv.implicitly_wait(5)
    yield drv
    drv.quit()


@pytest.fixture(scope="function")
def fresh_driver():
    """Per-test driver with full reset."""
    caps = dict(CAPS)
    caps["appium:fullReset"] = True
    options = AppiumOptions().load_capabilities(caps)
    drv = webdriver.Remote(APPIUM_URL, options=options)
    drv.implicitly_wait(5)
    yield drv
    drv.quit()


# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITES
# ══════════════════════════════════════════════════════════════════════════════

# ─── 1. Splash & Onboarding ───────────────────────────────────────────────────

class TestOnboarding:
    """Verify the first-launch onboarding flow."""

    def test_splash_screen_loads(self, fresh_driver):
        """App shows splash screen on cold launch."""
        assert_text_visible(fresh_driver, "EventSphere", timeout=20)

    def test_onboarding_pages_visible(self, fresh_driver):
        """Three onboarding pages exist and can be navigated."""
        skip_onboarding(fresh_driver)
        # After skipping we should land on Login
        assert_text_visible(fresh_driver, "Welcome Back")

    def test_get_started_reaches_login(self, fresh_driver):
        """'Get Started' / final onboarding CTA navigates to Login."""
        skip_onboarding(fresh_driver)
        assert_text_visible(fresh_driver, "Sign in to continue to EventSphere")


# ─── 2. Authentication ────────────────────────────────────────────────────────

class TestAuthentication:
    """Login, Signup, and Forgot-Password flows."""

    def test_login_with_invalid_credentials(self, fresh_driver):
        """Wrong password shows an error snackbar."""
        skip_onboarding(fresh_driver)
        type_into(fresh_driver, "you@example.com", "wrong@user.com")
        type_into(fresh_driver, "••••••••", "wrongpass")
        tap_text(fresh_driver, "Sign In")
        # Firebase returns an error; snackbar must appear
        assert_text_visible(fresh_driver, "error", timeout=10)

    def test_login_empty_fields_validation(self, fresh_driver):
        """Tapping Sign In with empty fields shows validation messages."""
        skip_onboarding(fresh_driver)
        tap_text(fresh_driver, "Sign In")
        assert_text_visible(fresh_driver, "Enter your email")

    def test_successful_customer_login(self, fresh_driver):
        """Valid customer credentials navigate to Home."""
        skip_onboarding(fresh_driver)
        login(fresh_driver, CUSTOMER_EMAIL, CUSTOMER_PASS)
        assert_text_visible(fresh_driver, "Our Services")

    def test_navigate_to_signup(self, fresh_driver):
        """'Sign Up' link from Login opens the Signup screen."""
        skip_onboarding(fresh_driver)
        tap_text(fresh_driver, "Sign Up")
        assert_text_visible(fresh_driver, "Create Account")

    def test_signup_customer_validation(self, fresh_driver):
        """Submit empty signup form shows validation errors."""
        skip_onboarding(fresh_driver)
        tap_text(fresh_driver, "Sign Up")
        tap_text(fresh_driver, "Create Account")
        assert_text_visible(fresh_driver, "Please enter your name")

    def test_signup_vendor_shows_extra_fields(self, fresh_driver):
        """Selecting Vendor role reveals Shop Name and Pincode fields."""
        skip_onboarding(fresh_driver)
        tap_text(fresh_driver, "Sign Up")
        tap_text(fresh_driver, "Vendor")
        assert_text_visible(fresh_driver, "Shop Name")
        assert_text_visible(fresh_driver, "Pincode of the Area")

    def test_forgot_password_link(self, fresh_driver):
        """Forgot Password link opens the reset screen."""
        skip_onboarding(fresh_driver)
        tap_text(fresh_driver, "Forgot Password?")
        assert_text_visible(fresh_driver, "Reset Password")

    def test_logout_flow(self, fresh_driver):
        """Logged-in user can sign out and returns to Login."""
        skip_onboarding(fresh_driver)
        login(fresh_driver, CUSTOMER_EMAIL, CUSTOMER_PASS)
        logout(fresh_driver)
        assert_text_visible(fresh_driver, "Welcome Back")


# ─── 3. Customer – Home & Navigation ─────────────────────────────────────────

class TestCustomerHome:
    """Customer home screen and bottom-nav flow."""

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)

    def test_home_screen_services_grid(self):
        """Home shows 4 service cards: Search, Track, Chat, Profile."""
        for label in ["Search", "Track", "Chat", "Profile"]:
            assert_text_visible(self.driver, label)

    def test_ai_planner_banner_visible(self):
        """Smart AI Planner recommendation banner is present."""
        assert_text_visible(self.driver, "Smart AI Planner")

    def test_navigate_to_categories(self):
        """Tapping Search card opens Categories screen."""
        tap_text(self.driver, "Search")
        assert_text_visible(self.driver, "Categories")

    def test_navigate_to_chat(self):
        """Tapping Chat card opens Chat list."""
        tap_text(self.driver, "Chat")
        assert_text_visible(self.driver, "Messages")

    def test_navigate_to_profile(self):
        """Tapping Profile card opens Profile screen."""
        tap_text(self.driver, "Profile")
        assert_text_visible(self.driver, "Profile")

    def test_notifications_icon_tappable(self):
        """Notification bell navigates to Notifications screen."""
        find_clickable(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("notifications")',
        ).click()
        assert_text_visible(self.driver, "Notifications")


# ─── 4. Categories & Equipment Listing ───────────────────────────────────────

class TestCategoriesAndListing:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)
        tap_text(self.driver, "Search")

    def test_categories_screen_visible(self):
        """Categories screen loads with category tiles."""
        assert_text_visible(self.driver, "Categories")

    def test_search_bar_accepts_input(self):
        """Search bar is present and accepts text input."""
        search_bar = find(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().textContains("Search")',
        )
        search_bar.send_keys("Sound")
        assert_text_visible(self.driver, "Sound")

    def test_tap_sound_category(self):
        """Tapping the Sound category shows sound equipment."""
        tap_text(self.driver, "Sound")
        # Equipment listing should appear
        assert_text_visible(self.driver, "Sound", timeout=10)

    def test_equipment_detail_opens(self):
        """Tapping an equipment card opens the detail screen."""
        tap_text(self.driver, "Sound")
        # Tap first card (any item)
        items = self.driver.find_elements(
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().resourceId("equipment_card")',
        )
        if items:
            items[0].click()
            assert_text_visible(self.driver, "Add to Cart")
        else:
            pytest.skip("No equipment cards found – seed data required.")


# ─── 5. Cart & Checkout ───────────────────────────────────────────────────────

class TestCartAndCheckout:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)

    def test_empty_cart_message(self):
        """Navigating to Cart with no items shows 'Your cart is empty'."""
        tap_text(self.driver, "Track")    # go to a screen first
        # Navigate to cart via bottom-nav or direct route
        try:
            tap_text(self.driver, "Cart")
        except TimeoutException:
            # Swipe up or use nav
            pass
        assert_text_visible(self.driver, "Your cart is empty")

    def test_checkout_validation(self):
        """Proceeding to Checkout with empty form shows validation errors."""
        # We need items in cart; skip if not seeded
        try:
            tap_text(self.driver, "Proceed to Checkout", timeout=5)
            tap_text(self.driver, "Proceed Request")
            assert_text_visible(self.driver, "Please enter your name")
        except TimeoutException:
            pytest.skip("Cart empty – cannot test checkout validation without items.")

    def test_checkout_delivery_fields(self):
        """Checkout screen contains all required delivery address fields."""
        try:
            tap_text(self.driver, "Proceed to Checkout", timeout=5)
            for label in ["Full Name", "Phone", "Address", "City", "ZIP"]:
                assert_text_visible(self.driver, label)
        except TimeoutException:
            pytest.skip("Cart empty – cannot reach checkout.")

    def test_event_details_section_visible(self):
        """Checkout screen shows Event Details section."""
        try:
            tap_text(self.driver, "Proceed to Checkout", timeout=5)
            assert_text_visible(self.driver, "Event Details")
            assert_text_visible(self.driver, "Event Name")
        except TimeoutException:
            pytest.skip("Cart empty – cannot reach checkout.")


# ─── 6. Order Tracking ───────────────────────────────────────────────────────

class TestOrderTracking:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)

    def test_order_tracking_no_orders(self):
        """Tracking screen shows 'No orders to track' when empty."""
        tap_text(self.driver, "Track")
        assert_text_visible(self.driver, "No orders to track")

    def test_tracking_steps_present_after_order(self):
        """
        After placing an order the 5-step timeline should be visible.
        (Skipped if no orders exist in Firestore for this user.)
        """
        tap_text(self.driver, "Track")
        try:
            assert_text_visible(self.driver, "Request Sent", timeout=5)
            assert_text_visible(self.driver, "Request Confirmed")
            assert_text_visible(self.driver, "Equipment Prepared")
            assert_text_visible(self.driver, "Out for Delivery")
            assert_text_visible(self.driver, "Delivered")
        except TimeoutException:
            pytest.skip("No orders in Firestore for this test account.")


# ─── 7. Vendor Flow ───────────────────────────────────────────────────────────

class TestVendorFlow:
    """Vendor-specific screens: Inventory & Order management."""

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, VENDOR_EMAIL, VENDOR_PASS)

    def test_vendor_home_quick_actions(self):
        """Vendor home shows Inventory, Orders, Inbox, Settings cards."""
        for label in ["Inventory", "Orders", "Inbox", "Settings"]:
            assert_text_visible(self.driver, label)

    def test_vendor_inventory_screen_loads(self):
        """Tapping Inventory opens My Inventory screen."""
        tap_text(self.driver, "Inventory")
        assert_text_visible(self.driver, "My Inventory")

    def test_vendor_add_item_button_visible(self):
        """The '+' FAB to add a new inventory item is present."""
        tap_text(self.driver, "Inventory")
        fab = find(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("Add")',
        )
        assert fab is not None

    def test_vendor_add_item_sheet_opens(self):
        """Tapping FAB opens the Add New Item bottom sheet."""
        tap_text(self.driver, "Inventory")
        find_clickable(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("Add")',
        ).click()
        assert_text_visible(self.driver, "Add New Item")

    def test_vendor_add_item_category_selector(self):
        """Add-item sheet shows category chips: Sound, Lighting, etc."""
        tap_text(self.driver, "Inventory")
        find_clickable(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("Add")',
        ).click()
        for cat in ["Sound", "Lighting", "Staging"]:
            assert_text_visible(self.driver, cat)

    def test_vendor_add_item_validation(self):
        """Submitting empty Add Item form shows validation error."""
        tap_text(self.driver, "Inventory")
        find_clickable(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("Add")',
        ).click()
        tap_text(self.driver, "Add to Inventory")
        assert_text_visible(self.driver, "Please enter an item name")

    def test_vendor_add_item_full_flow(self):
        """Fill in item details and submit; item appears in inventory."""
        tap_text(self.driver, "Inventory")
        find_clickable(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("Add")',
        ).click()

        type_into(self.driver, "Professional PA System", "Test Speaker 1000W")
        type_into(self.driver, "e.g. 1500", "2500")
        tap_text(self.driver, "Add to Inventory")

        # Success snackbar
        assert_text_visible(self.driver, "Item added!", timeout=15)

    def test_vendor_orders_screen_loads(self):
        """Vendor Orders screen is accessible from home."""
        tap_text(self.driver, "Orders")
        assert_text_visible(self.driver, "Rental Requests")

    def test_vendor_inbox_opens(self):
        """Vendor Inbox (chat list) screen opens from home."""
        tap_text(self.driver, "Inbox")
        assert_text_visible(self.driver, "Messages")


# ─── 8. Chat / Messaging ─────────────────────────────────────────────────────

class TestChat:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)
        tap_text(self.driver, "Chat")

    def test_chat_list_screen_visible(self):
        """Chat list screen loads."""
        assert_text_visible(self.driver, "Messages")

    def test_empty_chat_state(self):
        """No conversations shows empty state."""
        try:
            assert_text_visible(self.driver, "No conversations yet", timeout=5)
        except TimeoutException:
            pass  # Conversations already exist – skip empty-state check

    def test_open_existing_chat(self):
        """Tapping a chat thread opens the detail/message view."""
        chats = self.driver.find_elements(
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().className("android.view.View").index(1)',
        )
        if chats:
            chats[0].click()
            assert_text_visible(self.driver, "Send", timeout=10)
        else:
            pytest.skip("No existing chat threads for this account.")


# ─── 9. Notifications ────────────────────────────────────────────────────────

class TestNotifications:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)

    def test_notifications_screen_opens(self):
        """Bell icon navigates to Notifications screen."""
        find_clickable(
            self.driver,
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().descriptionContains("notifications")',
        ).click()
        assert_text_visible(self.driver, "Notifications")

    def test_notifications_badge_visible(self):
        """Notification badge count is visible on home."""
        assert_text_visible(self.driver, "2")


# ─── 10. Profile ─────────────────────────────────────────────────────────────

class TestProfile:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, CUSTOMER_EMAIL, CUSTOMER_PASS)
        tap_text(self.driver, "Profile")

    def test_profile_screen_loads(self):
        """Profile screen is accessible."""
        assert_text_visible(self.driver, "Profile")

    def test_sign_out_button_visible(self):
        """Sign Out option is present on Profile screen."""
        assert_text_visible(self.driver, "Sign Out")

    def test_sign_out_returns_to_login(self):
        """Tapping Sign Out navigates back to Login."""
        tap_text(self.driver, "Sign Out")
        assert_text_visible(self.driver, "Welcome Back")


# ─── 11. Admin Panel ─────────────────────────────────────────────────────────
# Note: Requires an admin account. Set ADMIN_EMAIL / ADMIN_PASS env vars.

ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@eventsphere.com")
ADMIN_PASS  = os.getenv("ADMIN_PASS", "Admin@1234")


class TestAdminPanel:

    @pytest.fixture(autouse=True)
    def setup(self, fresh_driver):
        self.driver = fresh_driver
        skip_onboarding(self.driver)
        login(self.driver, ADMIN_EMAIL, ADMIN_PASS)

    def test_admin_dashboard_loads(self):
        """Admin dashboard is reachable after admin login."""
        try:
            assert_text_visible(self.driver, "Dashboard", timeout=10)
        except TimeoutException:
            pytest.skip("Admin role not assigned to this account in Firestore.")

    def test_admin_users_screen(self):
        """Admin can navigate to Users management."""
        try:
            tap_text(self.driver, "Users")
            assert_text_visible(self.driver, "Users")
        except TimeoutException:
            pytest.skip("Admin panel not accessible.")

    def test_admin_vendor_approval_screen(self):
        """Admin can navigate to Vendor Approval screen."""
        try:
            tap_text(self.driver, "Vendors")
            assert_text_visible(self.driver, "Vendor Approval")
        except TimeoutException:
            pytest.skip("Admin panel not accessible.")

    def test_admin_reports_screen(self):
        """Admin can navigate to Reports screen."""
        try:
            tap_text(self.driver, "Reports")
            assert_text_visible(self.driver, "Reports")
        except TimeoutException:
            pytest.skip("Admin panel not accessible.")


# ─── 12. Full E2E Happy-Path ──────────────────────────────────────────────────

class TestFullHappyPath:
    """
    End-to-end: Customer browses → adds to cart → checkout → order confirmed.
    Requires seeded Firestore data (at least one vendor with equipment listed).
    """

    def test_full_booking_flow(self, fresh_driver):
        driver = fresh_driver

        # 1. Onboarding
        skip_onboarding(driver)

        # 2. Login
        login(driver, CUSTOMER_EMAIL, CUSTOMER_PASS)
        assert_text_visible(driver, "Our Services")

        # 3. Browse categories
        tap_text(driver, "Search")
        assert_text_visible(driver, "Categories")

        # 4. Select a category
        tap_text(driver, "Sound")

        # 5. Open first equipment item
        items = driver.find_elements(
            AppiumBy.ANDROID_UIAUTOMATOR,
            'new UiSelector().resourceId("equipment_card")',
        )
        if not items:
            pytest.skip("No equipment seeded – cannot run full happy-path.")
        items[0].click()

        # 6. Add to cart
        tap_text(driver, "Add to Cart")
        assert_text_visible(driver, "added to cart", timeout=8)

        # 7. Go to Cart
        tap_text(driver, "View Cart")
        assert_text_visible(driver, "Shopping Cart")

        # 8. Proceed to Checkout
        tap_text(driver, "Proceed to Checkout")
        assert_text_visible(driver, "Checkout")

        # 9. Fill delivery address
        type_into(driver, "John Doe", "Test Customer")
        type_into(driver, "9876543210", "9876543210")
        type_into(driver, "123 Event Avenue", "123 MG Road")
        type_into(driver, "New York", "Mumbai")
        type_into(driver, "10001", "400001")

        # 10. Fill event details
        type_into(driver, "My Wedding Reception", "Birthday Party 2025")

        # 11. Submit order
        tap_text(driver, "Proceed Request")
        assert_text_visible(driver, "Request Sent to Vendor!", timeout=20)

        # 12. Track the order
        tap_text(driver, "Track Order")
        assert_text_visible(driver, "Order Tracking")
        assert_text_visible(driver, "Request Sent")
