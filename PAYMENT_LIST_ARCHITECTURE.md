# PaymentListWidget - Visual Structure & Architecture

## Widget Tree Structure

```
PaymentListWidget (StatelessWidget)
├── if payments.isEmpty
│   └── _buildEmptyState()
│       └── Center
│           └── Column
│               ├── Icon(Icons.inbox)
│               └── Text("Nenhum pagamento registrado")
│
└── else
    └── ListView.builder
        └── for each month
            └── Column
                ├── _buildMonthHeader(monthKey, count)
                │   └── Container
                │       └── Text("Março/2026 (2 pagamentos)")
                │
                └── for each payment in month
                    └── _buildPaymentCard(context, payment)
                        └── Padding
                            └── GestureDetector
                                └── Container
                                    └── Column
                                        ├── Row 1: Date | Type | Amount
                                        ├── Row 2: Status Badge
                                        └── Row 3: Edit & Delete Buttons
```

## Data Flow

```
Input: List<PaymentRecord>
  ↓
_groupPaymentsByMonth()
  ├─ Group by month key
  ├─ Sort within groups (desc by date)
  └─ Sort groups (desc by date)
  ↓
ListView.builder
  ├─ For each month
  │   ├─ Month header
  │   └─ Payment cards
  ↓
User Interaction
  ├─ Edit button → onEdit(payment) callback
  └─ Delete button
      ├─ Show confirmation dialog
      └─ onDelete(paymentId) callback
```

## Component Details

### 1. Month Header Component
```
┌─────────────────────────────────────┐
│ Março/2026 (2 pagamentos)           │  ← 14pt bold, dark gray
│ #F5F5F5 background                  │  ← Light gray background
│ 12pt horiz. 8pt vert. padding       │
└─────────────────────────────────────┘
```

### 2. Payment Card Component
```
┌────────────────────────────────────────┐
│ 15/mar - Normal      R$ 1.500,00       │  ← Row 1: Date, Type, Amount
│                                        │
│ [No prazo]                             │  ← Row 2: Status badge
│                                        │
│ [✎ Edit]                   [🗑 Delete]│  ← Row 3: Buttons
└────────────────────────────────────────┘
```

### 3. Confirmation Dialog
```
┌─────────────────────────────────────────┐
│ Confirmar exclusão                      │
│                                         │
│ Tem certeza que deseja deletar este     │
│ pagamento?                              │
│                                         │
│  [Cancelar]            [Confirmar]      │
└─────────────────────────────────────────┘
```

## Method Organization

### Main Methods
- `build()` - Main widget rendering
- `_groupPaymentsByMonth()` - Grouping logic
- `_buildEmptyState()` - Empty state UI
- `_buildMonthHeader()` - Month header widget
- `_buildPaymentCard()` - Payment card widget

### Helper Methods
- `_formatMonthKey()` - Convert date to "mar/2026" format
- `_getFullMonthName()` - Get "Março" from month
- `_getMonthNumber()` - Convert "mar" to 3
- `_buildStatusBadge()` - Status indicator widget
- `_buildEditButton()` - Edit action button
- `_buildDeleteButton()` - Delete action button
- `_showDeleteConfirmation()` - Delete dialog
- `_formatPaymentDate()` - Format as "15/mar"
- `_getPaymentTypeLabel()` - Get Portuguese label
- `_formatAmount()` - Format as "R$ 1.500,00"

## Styling Specifications

### Colors Used
```
Text Primary:      #111827 (month headers, main text)
Text Secondary:    #6B7280 (dates, secondary text)
Green:             #10B981 (amounts, success)
Error:             #EF4444 (delete button, errors)
White:             #FFFFFF (card background)
Light Gray:        #F5F5F5 (month header background)
Border Gray:       #E0E0E0 (card borders)
```

### Typography
```
Month Headers:     14pt Inter Bold, #111827
Payment Types:     13pt Inter Medium, #111827
Payment Dates:     13pt Inter Regular, #6B7280
Amounts:           14pt Inter Bold, #10B981
Status Badges:     12pt Inter Medium, status-color
Dialog Text:       Default Flutter typography
```

### Spacing
```
Month Header:      12pt horizontal, 8pt vertical padding
Payment Cards:     8pt horizontal, 4pt vertical margin, 12pt padding
Content Rows:      8pt gap between rows
List Items:        8pt vertical padding
```

### Borders & Corners
```
Month Headers:     No border, full width
Payment Cards:     1pt #E0E0E0 border, 8pt border radius
Status Badges:     4pt border radius, colored background
Dialog Buttons:    Standard Flutter styling
```

## State Management Integration

### With Riverpod
```dart
// Read payments
final payments = ref.watch(paymentProvider(loanId));

// Handle edit
onEdit: (payment) {
  ref.read(paymentProvider(loanId).notifier)
     .updatePayment(payment.id, ...);
}

// Handle delete
onDelete: (paymentId) {
  ref.read(paymentProvider(loanId).notifier)
     .deletePayment(paymentId);
}
```

## Localization Points

### Portuguese Strings
```
"Nenhum pagamento registrado"      - Empty state message
"Tem certeza que deseja deletar?"  - Delete confirmation
"Pagamento deletado com sucesso"   - Success message
"Erro ao deletar: {error}"         - Error message
"Abrindo formulário de edição..."  - Edit feedback

Month names:
janeiro, fevereiro, março, abril, maio, junho,
julho, agosto, setembro, outubro, novembro, dezembro

Payment types:
Normal, Extra Mensal, Extra Única, Amortização

Status:
Adiantado, No prazo, Atrasado
```

## Performance Considerations

1. **ListView.builder**: Lazy rendering for large lists
2. **Map iteration**: O(n) for grouping
3. **Sorting**: O(n log n) per month
4. **Immutable widgets**: Proper const constructors
5. **Memory**: Single pass through payments

## Accessibility Features

1. **Icon buttons**: Semantic icons (pencil, trash)
2. **Color contrast**: WCAG compliant
3. **Text sizing**: Readable 13-14pt minimum
4. **Spacing**: Proper touch targets (44pt minimum)
5. **Semantic widgets**: Proper widget hierarchy
6. **Error feedback**: Clear error messages

## Testing Coverage Matrix

| Scenario | Test | Status |
|----------|------|--------|
| Multiple payments | Test 1 | ✅ PASS |
| Grouping by month | Test 2 | ✅ PASS |
| Descending sort | Test 3 | ✅ PASS |
| Empty state | Test 4 | ✅ PASS |
| Callbacks | Test 5 | ✅ PASS |

## Extension Points

Future enhancements could add:
1. Pull-to-refresh functionality
2. Search/filter by amount or date
3. Export to CSV/PDF
4. Batch operations (select multiple)
5. Swipe-to-delete gestures
6. Custom date range filtering
7. Payment notes display
8. Attachment previews
9. Recurring payment indicators
10. Payment status history

---

**Architecture follows:**
- ✅ Flutter best practices
- ✅ Dart style guide
- ✅ Clean code principles
- ✅ SOLID principles
- ✅ Material Design 3
- ✅ Responsive design
- ✅ PT-BR localization standards
