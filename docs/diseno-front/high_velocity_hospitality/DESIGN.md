---
name: High-Velocity Hospitality
colors:
  surface: '#181309'
  surface-dim: '#181309'
  surface-bright: '#3f382d'
  surface-container-lowest: '#120e05'
  surface-container-low: '#201b11'
  surface-container: '#241f14'
  surface-container-high: '#2f291e'
  surface-container-highest: '#3a3428'
  on-surface: '#ede1d0'
  on-surface-variant: '#d4c5ab'
  inverse-surface: '#ede1d0'
  inverse-on-surface: '#363024'
  outline: '#9c8f78'
  outline-variant: '#504532'
  surface-tint: '#fbbc00'
  primary: '#ffe2ab'
  on-primary: '#402d00'
  primary-container: '#ffbf00'
  on-primary-container: '#6d5000'
  inverse-primary: '#795900'
  secondary: '#43dde6'
  on-secondary: '#003739'
  secondary-container: '#00c1ca'
  on-secondary-container: '#00494d'
  tertiary: '#b4efff'
  on-tertiary: '#003640'
  tertiary-container: '#04dcff'
  on-tertiary-container: '#005d6d'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdfa0'
  primary-fixed-dim: '#fbbc00'
  on-primary-fixed: '#261a00'
  on-primary-fixed-variant: '#5c4300'
  secondary-fixed: '#6bf6ff'
  secondary-fixed-dim: '#3edae3'
  on-secondary-fixed: '#002022'
  on-secondary-fixed-variant: '#004f53'
  tertiary-fixed: '#aaedff'
  tertiary-fixed-dim: '#00d9fc'
  on-tertiary-fixed: '#001f26'
  on-tertiary-fixed-variant: '#004e5c'
  background: '#181309'
  on-background: '#ede1d0'
  surface-variant: '#3a3428'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
  numeral-xl:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  touch-target-min: 48px
  container-padding: 16px
---

## Brand & Style

The design system is engineered for the high-pressure environment of nightlife and hospitality. It prioritizes **efficiency, clarity, and speed of thought**, ensuring that staff can navigate complex orders in low-light, high-distraction settings. 

The aesthetic is **Corporate Modern with High-Contrast accents**. It utilizes a deep charcoal foundation to reduce eye strain and screen glare in dark bars, while deploying "Electric" accent colors to highlight critical paths and transaction states. The visual language is unapologetically functional, emphasizing large interactive zones and unmistakable status indicators to minimize input errors.

## Colors

The palette is optimized for dark-room legibility. 
- **Primary (Electric Amber):** Reserved for core "Success" or "Confirm" actions, such as sending an order to the kitchen or processing a payment.
- **Secondary (Neon Teal):** Used for navigation, filtering, and secondary modifications that require visibility without the urgency of the primary action.
- **Neutral/Background:** A multi-layered charcoal system. The base is a deep `#121212`, with elevated surfaces using progressively lighter greys to create a sense of depth and hierarchy without relying on traditional drop shadows.
- **Semantic Colors:** High-saturation reds and greens are used sparingly for errors (voided items) and success (paid bills) to ensure they stand out against the amber and teal accents.

## Typography

This design system uses **Inter** exclusively for its exceptional legibility and neutral, professional character. 

- **Weight Strategy:** Headlines use Bold (700) or Semi-Bold (600) to anchor the page. Body text remains at Regular (400) for high-density information, while labels utilize Medium (500) and Semi-Bold (600) for quick scanning of item modifiers or prices.
- **Numerals:** Since the product is a POS app, currency and quantities are prioritized. The `numeral-xl` style is used for total balances and large numpad inputs.
- **Scaling:** On mobile, font sizes are kept slightly larger than standard consumer apps to ensure readability when the device is held at an arm's length on a bar counter.

## Layout & Spacing

The layout follows a **Fluid Grid** model built on an 8px base unit, specifically optimized for touch interaction.

- **Touch Targets:** All interactive elements must maintain a minimum height of `48px` to accommodate rapid "fat-finger" inputs during busy shifts.
- **Safe Zones:** A standard `16px` margin (container-padding) is applied to the left and right of the screen. 
- **Grid Structure:** A 4-column grid is used for mobile layouts. In list views, 8px gutters separate item cards, while 16px gutters are used for larger dashboard modules.
- **Rhythm:** Vertical rhythm is strictly enforced using the 8px unit to ensure a clean, structured appearance that feels "engineered" and reliable.

## Elevation & Depth

In this design system, depth is communicated through **Tonal Layering** rather than traditional shadows. In a dark POS environment, shadows can muddy the interface; instead, we use light.

1.  **Level 0 (Background):** `#121212` – The canvas.
2.  **Level 1 (Cards/Lists):** `#1E1E1E` – Primary content containers.
3.  **Level 2 (Modals/Overlays):** `#2C2C2C` – High-priority pop-ups or active states.
4.  **Active Indicators:** Instead of elevation shadows, active states use a `2px` inner border or a "glow" effect using low-opacity versions of the primary Amber or Teal colors. This ensures the user always knows which item is selected in a high-speed workflow.

## Shapes

The design system employs **Rounded (0.5rem / 8px)** corners as the default for all core UI elements.

- **Cards:** Use `rounded-lg` (16px) to clearly define groupings of menu items or table layouts.
- **Buttons:** Use `rounded-md` (8px) for a professional, sturdy feel that maintains high clickability.
- **Search & Chips:** Use `rounded-full` (Pill-shaped) for elements that are purely navigational or represent individual tags (e.g., "Draft Beer," "Happy Hour").

## Components

### Buttons
- **Primary:** Solid Electric Amber background with Black (#000000) text for maximum contrast. Full-width on mobile for "Checkout" or "Send" actions.
- **Secondary:** Outlined in Neon Teal with Teal text. Used for "Add Note" or "Print Receipt."
- **Ghost:** No background, Teal or White text. Used for dismissive or low-priority actions.

### Menu Cards
Cards are the backbone of the POS. They feature a Level 1 surface. The item name is Bold, with the price anchored to the top-right in Electric Amber. If an item is "Out of Stock," the card opacity drops to 40% with a subtle diagonal pattern overlay.

### Status Indicators
- **Table Status:** Circular pips. Amber for "Occupied," Teal for "Available," and a Pulsing Amber for "Check Requested."
- **Order Status:** Rectangular chips with low-opacity backgrounds and high-saturation text (e.g., "Pending" in Teal, "Void" in Red).

### Input Fields
Darker than the surface they sit on (`#000000` background) with a `1px` stroke in `#2C2C2C`. On focus, the stroke changes to Neon Teal. Labels sit permanently above the input to ensure context is never lost during fast typing.

### Numpad
A custom 3x4 grid for quantity and price entry. Large, borderless keys with high-contrast numerals. The "Enter" or "Confirm" key is always the primary Electric Amber.