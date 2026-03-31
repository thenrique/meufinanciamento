# E2E Test Guide - "Estimado x Realizado" Feature

## Overview

This guide documents the end-to-end (E2E) integration tests for the "Estimado x Realizado" (Estimated vs Actual) feature in the Meu Financiamento app. These tests exercise the complete flow from creating a loan through managing payments with real-time chart and summary updates.

## Test Framework

**Framework:** Flutter Integration Tests (flutter drive)
**Package:** `integration_test`
**Test File:** `integration_test/loan_history_e2e_test.dart`

### Why Integration Tests?

- ✅ Tests run on actual Flutter app
- ✅ Can test actual Supabase API integration
- ✅ Tests UI, business logic, and API together
- ✅ Simulates real user interactions
- ✅ Validates complete feature flows
- ✅ Performance and memory monitoring

## Running the Tests

### Prerequisites

1. Flutter SDK installed and configured
2. Android emulator or physical device connected
3. iOS simulator or device (for iOS testing)
4. Supabase project configured
5. Valid test credentials (if authentication required)

### Run All E2E Tests

```bash
cd mobile
flutter drive --target=integration_test/loan_history_e2e_test.dart
```

### Run Specific Test

```bash
# Run a single test by name
flutter drive --target=integration_test/loan_history_e2e_test.dart -t "E2E Flow 1"
```

### Run with Custom Device

```bash
# For Android
flutter drive --device-id emulator-5554 --target=integration_test/loan_history_e2e_test.dart

# For iOS
flutter drive --device-id 12345678-1234-1234-1234-123456789012 --target=integration_test/loan_history_e2e_test.dart
```

### Run with Driver Output

```bash
# Verbose output
flutter drive --target=integration_test/loan_history_e2e_test.dart --verbose

# Save performance metrics
flutter drive --target=integration_test/loan_history_e2e_test.dart --profile
```

## Test Scenarios Covered

### Flow 1: Create Loan → Add Payment → View History (Full E2E)
**Duration:** ~30 seconds

**Steps:**
1. Navigate to "Criar Financiamento" screen ✅
2. Fill loan form (amount, rate, months, due date) ✅
3. Click "Criar" button ✅
4. System saves loan to Supabase ✅
5. Navigate to loan detail ✅
6. Click "Histórico de Pagamentos" button ✅
7. View loads showing empty history ✅
8. Click "Adicionar Pagamento" button ✅
9. Form dialog appears ✅
10. Fill: date (today), amount (R$ 1.500), type (normal) ✅
11. Click "Adicionar" button ✅
12. Payment saved, list updates ✅
13. Chart shows updated balance ✅
14. Summary shows updated metrics ✅
15. Add 2nd payment (different month) ✅
16. Verify monthly grouping ✅
17. Edit first payment (R$ 2.000) ✅
18. Delete 2nd payment ✅
19. Navigate back and verify persistence ✅
20. Only 1 payment showing (edited one) ✅

**Expected Results:**
- Loan created successfully
- Payments persisted to Supabase
- Chart displays with estimated vs actual
- Summary metrics update in real-time
- Data persists across navigation
- Monthly grouping works correctly

### Flow 2: Multiple Payments in Different Months
**Duration:** ~20 seconds

**Steps:**
1. Create test loan
2. Navigate to payment history
3. Add payment in current month (R$ 1.000)
4. Add payment 1 month ago (R$ 1.200)
5. Add payment 2 months ago (R$ 1.500)
6. Verify monthly grouping
7. Verify payments in correct order within each month

**Expected Results:**
- 3 payments grouped into 3 month sections
- Each month showing payment in descending date order
- Total amounts correct

### Flow 3: Data Persistence Across Navigation
**Duration:** ~15 seconds

**Steps:**
1. Create test loan with payment
2. Navigate away from history screen
3. Navigate back to history screen
4. Verify payment data still present

**Expected Results:**
- Payment data persisted in Supabase
- No loss of data during navigation
- List rebuilds correctly

### Flow 4: Chart Updates After Payment Added
**Duration:** ~10 seconds

**Steps:**
1. Open loan history (empty state)
2. Add first payment
3. Verify chart renders with data
4. Check "Estimado" (blue) line visible
5. Check "Realizado" (green) line visible

**Expected Results:**
- Chart component renders
- Both legend items visible
- Chart updates without errors
- No visual glitches

### Flow 5: Summary Metrics Update Correctly
**Duration:** ~10 seconds

**Steps:**
1. Add multiple payments with different types
2. Verify summary card displays
3. Check metric calculations
4. Add additional payment
5. Verify metrics update

**Expected Results:**
- Summary card visible with 4 metrics
- Metrics: Total Pago, Média, Última Parcela, Próxima Data
- Values update in real-time
- Currency formatting correct (R$ 1.234,56)

### Flow 6: Validation Errors Display Properly
**Duration:** ~15 seconds

**Tests:**
- Future date validation (❌ Can't add future payment)
- Amount exceeds balance (❌ Insufficient balance)
- Duplicate payment date (❌ Payment already exists)
- Invalid payment type (❌ Invalid selection)
- Network error (➡️ Retry available)
- Form validation (📊 Submit button disabled)

**Expected Results:**
- Clear error messages displayed
- Form remains open for correction
- Validation errors prevent submission
- No silent failures

### Flow 7: Payment List Groups and Sorts Correctly
**Duration:** ~15 seconds

**Steps:**
1. Add payments out of chronological order
2. Verify automatic grouping by month
3. Verify sorting within each month
4. Check header shows month name and count

**Expected Results:**
- Payments grouped by month
- Months displayed in descending order (newest first)
- Within each month, payments in descending date order
- Month headers show: "fev/2026 (3 pagamentos)"

### Flow 8: Error Recovery and Retry Works
**Duration:** ~10 seconds

**Steps:**
1. Simulate network error
2. Verify error state and retry button
3. Click retry
4. Verify successful recovery

**Expected Results:**
- Error message displayed
- Retry button available and functional
- Successful retry completes operation
- No orphaned state

### Flow 9: Complete CRUD Operations on Payments
**Duration:** ~20 seconds

**Steps:**
1. **Create:** Add payment with all details
2. **Read:** Verify payment in list
3. **Update:** Edit payment amount
4. **Delete:** Remove payment
5. Verify empty state

**Expected Results:**
- Create: Payment appears in list immediately
- Read: All payment details visible
- Update: Changes reflected in UI instantly
- Delete: Payment removed, empty state shows
- No residual data

## Test Cases Summary

| # | Test Name | Duration | Status |
|---|-----------|----------|--------|
| 1 | Full create → add → view → edit → delete flow | 30s | ✅ |
| 2 | Multiple payments in different months | 20s | ✅ |
| 3 | Data persists across navigation | 15s | ✅ |
| 4 | Chart updates after payment added | 10s | ✅ |
| 5 | Summary metrics update correctly | 10s | ✅ |
| 6 | Validation errors display properly | 15s | ✅ |
| 7 | Payment list groups and sorts correctly | 15s | ✅ |
| 8 | Error recovery and retry works | 10s | ✅ |
| 9 | Complete CRUD operations | 20s | ✅ |

**Total Test Duration:** ~145 seconds (~2.5 minutes)

## Verification Points

### UI Elements
- ✅ Loan form renders with all fields
- ✅ Payment form dialog opens/closes correctly
- ✅ Payment list displays payment items
- ✅ Chart renders with both lines
- ✅ Summary card visible with metrics
- ✅ Edit/delete buttons available

### Data Persistence
- ✅ Loan saved to Supabase
- ✅ Payments saved to Supabase
- ✅ Data loads after navigation
- ✅ Updates reflect immediately
- ✅ No data loss on app restart

### API Integration
- ✅ POST /loans - create loan
- ✅ GET /loans/{id}/history - fetch history
- ✅ GET /loans/{id}/payments - list payments
- ✅ POST /loans/{id}/payments - create payment
- ✅ PUT /loans/{id}/payments/{id} - update payment
- ✅ DELETE /loans/{id}/payments/{id} - delete payment

### Business Logic
- ✅ Chart calculations (estimated vs actual)
- ✅ Summary metrics (total, average, last, next)
- ✅ Monthly grouping algorithm
- ✅ Date sorting (descending)
- ✅ Currency formatting (R$ 1.234,56)
- ✅ Date formatting (15/jan/2026)

### Performance
- ✅ History loads in < 2s
- ✅ Payment adds in < 1s
- ✅ Chart updates in < 500ms
- ✅ No memory leaks
- ✅ Smooth 60fps animations

### Error Handling
- ✅ Network errors handled
- ✅ Validation errors shown
- ✅ Retry mechanism works
- ✅ No unhandled exceptions
- ✅ User guidance provided

## Helper Functions Reference

### Navigation
```dart
_navigateToCreateLoan(tester)      // Open create loan screen
_navigateToHistory(tester, loanId) // Navigate to payment history
```

### Data Management
```dart
_createTestLoan(tester)            // Create loan with test data
_addPayment(tester, ...)           // Add payment to history
_editPayment(tester, ...)          // Edit existing payment
_deletePayment(tester, ...)        // Delete payment
```

### Verification
```dart
_verifyChart(tester)               // Check chart renders
_verifySummary(tester, values)     // Check summary metrics
_verifyPaymentList(tester, list)   // Check payment list
```

### Error Testing
```dart
_tryAddPaymentWithFutureDate(tester) // Test validation
```

## Known Issues & Limitations

### Current Limitations

1. **Authentication**
   - Tests assume user is already authenticated
   - For integration with real auth, add login flow to `setUpAll()`

2. **Network Mocking**
   - Tests use actual Supabase API
   - For faster tests, consider mocking HTTP layer

3. **Device-Specific**
   - Tests optimized for 1080x1920 screen
   - May need adjustments for tablets/large screens

4. **Data Cleanup**
   - Tests create data on Supabase
   - Manual cleanup may be needed between test runs
   - Consider adding tearDown to delete test data

5. **Date-Dependent**
   - Tests use `DateTime.now()` for dates
   - May fail if running at midnight (date boundary)
   - Consider using fixed test dates

### Workarounds

```dart
// Add to test setup for authentication
setUpAll(() async {
  await _loginUser(
    tester,
    email: 'test@example.com',
    password: 'test_password',
  );
});

// Add to test cleanup for data management
tearDown(() async {
  // Delete test payments created during test
  // Delete test loans created during test
});
```

## Troubleshooting

### Common Issues & Solutions

#### **Issue: Tests timeout on app startup**
**Solution:**
```dart
// Increase initial pump duration
await tester.pumpWidget(const MyApp());
await tester.pumpAndSettle(const Duration(seconds: 5));
```

#### **Issue: Can't find UI elements**
**Solution:**
```dart
// Add debugging to see UI tree
debugPrintBeginFrame = true;
await tester.pumpAndSettle();
expect(find.byType(YourWidget), findsOneWidget);
```

#### **Issue: API calls timing out**
**Solution:**
```bash
# Run with increased timeout
flutter drive --target=integration_test/loan_history_e2e_test.dart --verbosity=verbose
```

#### **Issue: Memory usage grows during tests**
**Solution:**
```dart
// Clear resources between tests
tearDown(() async {
  await tester.binding.window.physicalSizeTestValue = Size.zero;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
});
```

#### **Issue: Payments not saving to Supabase**
**Solution:**
```
1. Verify Supabase connection
2. Check network connectivity
3. Review RLS policies allow INSERT/UPDATE/DELETE
4. Check API client authentication token
```

#### **Issue: Chart not rendering**
**Solution:**
```
1. Verify payment data exists
2. Check fl_chart package installed
3. Review theme colors defined
4. Check chart build context
```

## Performance Benchmarks

**Expected Performance Metrics:**

| Operation | Expected Time | Acceptable Range |
|-----------|---------------|-----------------|
| Load history | < 2s | < 3s |
| Add payment | < 1s | < 1.5s |
| Update payment | < 1s | < 1.5s |
| Delete payment | < 0.5s | < 1s |
| Chart render | < 500ms | < 1s |
| Summary update | < 200ms | < 500ms |

**Memory Usage:**
- Initial: ~80-100 MB
- After 10 payments: ~100-120 MB
- Peak: ~150 MB (acceptable)

**Frame Rate:**
- Target: 60 FPS
- Minimum: 24 FPS
- During animations: 50+ FPS

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Install dependencies
        run: cd mobile && flutter pub get
      
      - name: Run E2E tests
        run: cd mobile && flutter drive --target=integration_test/loan_history_e2e_test.dart
```

## Best Practices

### Writing E2E Tests

1. **Keep tests independent**
   - Each test should create its own data
   - Don't depend on test execution order

2. **Use descriptive test names**
   - Clearly state what is being tested
   - Include flow step or scenario

3. **Add debugging output**
   - Use `debugPrint()` for test progress
   - Include timestamps for performance analysis

4. **Handle async operations**
   - Always use `pumpAndSettle()` after user interactions
   - Add explicit waits for animations

5. **Verify multiple aspects**
   - Check UI elements rendered
   - Verify data in backend
   - Validate calculations
   - Check error states

### Code Example

```dart
testWidgets('Payment added successfully', (WidgetTester tester) async {
  // Setup
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Execute
  final loanId = await _createTestLoan(tester);
  await _navigateToHistory(tester, loanId);
  await _addPayment(tester, date: DateTime.now(), amount: 1500.0);
  
  // Verify UI
  expect(find.byType(ListView), findsOneWidget);
  
  // Verify data
  final payment = await _verifyPaymentInDatabase(loanId);
  expect(payment.amountPaid, equals(1500.0));
});
```

## Support & Debugging

### Enabling Debug Logs

```bash
# Run with verbose output
flutter drive --target=integration_test/loan_history_e2e_test.dart --verbose

# Save logs to file
flutter drive --target=integration_test/loan_history_e2e_test.dart > e2e_test.log 2>&1
```

### Taking Screenshots

```dart
// Add to any test to save screenshot
await tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
await tester.pumpAndSettle();
await _saveScreenshot(tester, 'payment_list');
```

### Analyzing Performance

```bash
# Run with performance profiling
flutter drive --target=integration_test/loan_history_e2e_test.dart --profile
```

## Additional Resources

- [Flutter Integration Testing](https://flutter.dev/docs/testing/integration-tests)
- [flutter_test Documentation](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
- [integration_test Package](https://pub.dev/packages/integration_test)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)

## Contributing

To add new tests:

1. Create test function following naming convention
2. Add to appropriate test group
3. Document test steps and expected results
4. Update this guide
5. Run all tests to ensure no regressions

## Changelog

### v1.0.0 (2026-03-30)
- Initial E2E test suite created
- 9 test scenarios implemented
- Helper functions for common operations
- Comprehensive documentation
- Performance benchmarking setup

---

**Last Updated:** 2026-03-30
**Maintainer:** QA Team
**Status:** ✅ Ready for use
