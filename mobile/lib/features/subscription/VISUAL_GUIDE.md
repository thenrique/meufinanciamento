# Paywall Screen - Visual Guide

## Screen Layout (Top to Bottom)

```
┌─────────────────────────────────────┐
│ ← [Back Button]                     │  ← Safe area / Status bar
├─────────────────────────────────────┤
│                                     │
│              ⏰                       │  ← Gradient Navy Header
│                                     │
│    Sua trial expirou!               │
│                                     │
│ Continue aproveitando todos os      │
│           benefícios                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  O que você recebe:                 │  ← White background content area
│                                     │
│  ✓ Simulações ilimitadas            │
│  ✓ Histórico de pagamentos          │
│  ✓ Análise de cenários              │
│  ✓ Suporte prioritário              │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Plano Premium              │   │  ← Pricing box (navy-light)
│  │                             │   │
│  │      R$ 14,90               │   │
│  │           /mês              │   │
│  │                             │   │
│  │ Sem contrato, cancele       │   │
│  │   quando quiser             │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Ativar Assinatura] ────────────┐  │  ← Green primary button
│                                  │  │
│  [Continuar como visitante] ─────┘  │  ← Navy outlined secondary
│                                     │
│          [Cancelar]                 │  ← Text tertiary button
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ℹ️                          │   │  ← Yellow info box
│  │  Se cancelou e quer voltar? │   │
│  │                             │   │
│  │ Reative sua assinatura em   │   │
│  │ até 30 dias e recupere seu  │   │
│  │         acesso              │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## Color Palette

| Element | Color | Hex Code |
|---------|-------|----------|
| Header Gradient (Start) | Navy | #1E3A5F |
| Header Gradient (End) | Navy Dark | #2D5487 |
| Primary Button | Green | #10B981 |
| Secondary Button Border | Navy | #1E3A5F |
| Tertiary Button Text | Gray | #6B7280 |
| Pricing Box Background | Navy Light | #E8EEF7 |
| Info Box Background | Amber Light | #FEF3C7 |
| Info Box Border | Amber | #FCD34D |
| Text Primary | Dark Gray | #111827 |
| Text Secondary | Medium Gray | #6B7280 |
| Checkmark Circle | Green Light | #D1FAE5 |

## Interactive Elements

### Primary Button States
- **Default**: Green button, 56px height, full width
- **Loading**: Disabled, shows circular progress spinner
- **Error**: Still clickable, error message below

### Secondary Button
- Navy outlined button
- Full width, 56px height
- Pops navigation on tap

### Tertiary Button
- Text button with gray color
- Pops navigation on tap
- Minimal visual weight

## Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| Header Title | Inter | 28px | Bold (700) |
| Subtitle | Inter | 16px | Regular (400) |
| Section Title | Inter | 18px | Bold (700) |
| Benefit Items | Inter | 16px | Medium (500) |
| Price | Inter | 42px | Bold (700) |
| Price Label | Inter | 14px | Regular (400) |
| Info Text | Inter | 13px | Regular (400) |
| Buttons | Inter | 16px | SemiBold (600) |

## Responsive Design

- **Padding**: 24px horizontal on all sides
- **Gap**: 16px between major sections, 8-12px for minor spacing
- **Safe Area**: Respects device notches and system bars
- **Scroll**: Custom scroll view for proper overflow handling

## Animations

1. **Header Gradient**: Linear gradient from top-left to bottom-right
2. **Button Loading**: Circular progress spinner (2.5px stroke)
3. **Button Opacity**: Disabled state shows 60% opacity
4. **Transitions**: Smooth color transitions in button states

## Accessibility

✓ Proper contrast ratios for WCAG AA compliance
✓ Readable text sizes (minimum 13px)
✓ Large touch targets (56px minimum height)
✓ Clear visual hierarchy
✓ Semantic button structure
✓ Proper navigation handling

## Localization

All text in Portuguese (pt-BR):
- Header: "Sua trial expirou!"
- Buttons: "Ativar Assinatura", "Continuar como visitante", "Cancelar"
- Benefits: Portuguese descriptions
- Info message: Portuguese reactivation info

---
This design follows Material Design 3 guidelines with custom branding for Meu Financiamento.
