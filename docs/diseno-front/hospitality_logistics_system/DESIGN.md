---
name: Hospitality Logistics System
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#504532'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#827660'
  outline-variant: '#d4c5ab'
  surface-tint: '#795900'
  primary: '#795900'
  on-primary: '#ffffff'
  primary-container: '#ffbf00'
  on-primary-container: '#6d5000'
  inverse-primary: '#fbbc00'
  secondary: '#006a65'
  on-secondary: '#ffffff'
  secondary-container: '#6ff7ee'
  on-secondary-container: '#00716b'
  tertiary: '#006879'
  on-tertiary: '#ffffff'
  tertiary-container: '#04dcff'
  on-tertiary-container: '#005d6d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdfa0'
  primary-fixed-dim: '#fbbc00'
  on-primary-fixed: '#261a00'
  on-primary-fixed-variant: '#5c4300'
  secondary-fixed: '#6ff7ee'
  secondary-fixed-dim: '#4edbd2'
  on-secondary-fixed: '#00201e'
  on-secondary-fixed-variant: '#00504c'
  tertiary-fixed: '#aaedff'
  tertiary-fixed-dim: '#00d9fc'
  on-tertiary-fixed: '#001f26'
  on-tertiary-fixed-variant: '#004e5c'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
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
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

This design system is engineered for the high-velocity world of premium hospitality management. The brand personality balances white-glove service with operational precision—it is professional, urgent, and impeccably clean. The UI must evoke a sense of organized calm amidst high-traffic environments.

We employ a **Corporate / Modern** style with a focus on "High-Velocity Minimalism." This means maximizing whitespace to reduce cognitive load while using vibrant accent colors to guide the eye toward critical actions. Surfaces are primarily bright and airy, utilizing subtle tonal shifts rather than heavy textures to maintain a lightweight, digital-first feel.

## Colors

The palette is anchored in a "High-Contrast Light" logic. The primary surface is pure white (#FFFFFF), with secondary containers using a very light grey (#F8F9FA) to define boundaries.

*   **Primary Amber (#FFBF00):** Reserved for high-priority actions, notifications, and "Hero" interactive states. It signals warmth and hospitality while maintaining high visibility.
*   **Secondary Cyan (#00B5AD):** Used for logistical data, secondary buttons, and information-heavy highlights. It provides a cool, technical contrast to the amber.
*   **Neutral Palette:** Deep charcoals are used for typography to ensure maximum legibility against the light backgrounds. Success, Warning, and Error states should be clearly delineated, though the primary/secondary accents handle most functional signaling.

## Typography

The typography system uses a tiered approach to separate "Hospitality" from "Logistics."

*   **Headlines:** **Plus Jakarta Sans** provides a modern, welcoming, and premium feel. It is used for page titles and section headers to maintain the brand's approachable character.
*   **Functional UI:** **Inter** is used for all body copy, data tables, labels, and inputs. Its systematic, neutral design ensures that high-density information remains legible and professional.

Weights are used strategically: Semi-Bold for interactive labels and Medium for data points to ensure they stand out against the white backgrounds.

## Layout & Spacing

The design system utilizes a **12-column fluid grid** for desktop and a **4-column grid** for mobile. We follow a strict 8px base unit to ensure a mathematical rhythm across all components.

*   **Hospitality Breathing Room:** Layouts should use generous margins (32px on desktop) to avoid a "cluttered" enterprise feel.
*   **High-Velocity Density:** Within data-heavy components like tables or dash cards, the spacing can tighten to 12px (sm) to allow more information to be visible at once.
*   **Responsive Reflow:** On mobile, complex side-by-side elements stack vertically, and the primary amber actions are pinned to the bottom of the viewport for thumb-friendly accessibility.

## Elevation & Depth

In light mode, we avoid heavy shadows to maintain the "clean" aesthetic. Instead, we use **Tonal Layers** supplemented by **Ambient Shadows**.

1.  **Level 0 (Floor):** Light grey background (#F8F9FA).
2.  **Level 1 (Card/Container):** White (#FFFFFF) surfaces with a subtle 1px border (#E9ECEF).
3.  **Level 2 (Hover/Active):** A soft, extra-diffused shadow (0px 4px 20px rgba(0,0,0,0.04)).
4.  **Level 3 (Modals/Popovers):** A more defined shadow (0px 12px 32px rgba(0,0,0,0.08)) with a backdrop blur on the layer below to maintain focus.

Depth is used to signify interactivity—as elements rise, they become more actionable.

## Shapes

We use a **Rounded (8px base)** shape language. This softens the professional layout, making the software feel more accessible and hospitality-oriented.

*   **Standard Elements (Buttons, Inputs, Cards):** 0.5rem (8px).
*   **Large Containers (Modals, Feature Sections):** 1rem (16px).
*   **Utility Elements (Chips, Badges):** Pill-shaped (fully rounded) to differentiate them from interactive buttons.

This consistent curvature provides a cohesive, modern look that bridges the gap between a high-end consumer app and a powerful professional tool.

## Components

*   **Buttons:** Primary buttons use Amber (#FFBF00) with dark text for high contrast. Secondary buttons use a Cyan outline or ghost style. Buttons have an 8px radius and a subtle lift on hover.
*   **Input Fields:** Use a white background with a 1px grey border. On focus, the border transitions to Cyan with a 2px offset glow to indicate the active state.
*   **Chips:** Utilized for status tracking (e.g., "In Progress," "Checked In"). These are pill-shaped with low-opacity background tints of Cyan or Amber to remain unobtrusive but visible.
*   **Cards:** The core of the dashboard. White background, 8px radius, subtle border. Content is padded with 24px (md) spacing to ensure data doesn't feel cramped.
*   **Lists:** High-density lists use alternating tonal backgrounds (White and #F8F9FA) to assist horizontal eye tracking across data rows.
*   **Navigation:** A clean left-hand sidebar or top-bar using semi-transparent glass effects when scrolling over content, keeping the interface feeling lightweight.