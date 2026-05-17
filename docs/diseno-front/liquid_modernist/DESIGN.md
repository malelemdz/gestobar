---
name: Liquid Modernist
colors:
  surface: '#111317'
  surface-dim: '#111317'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#d1bcff'
  on-secondary: '#3c0090'
  secondary-container: '#7000ff'
  on-secondary-container: '#ddcdff'
  tertiary: '#fff3f4'
  on-tertiary: '#66002c'
  tertiary-container: '#ffccd6'
  on-tertiary-container: '#bb0058'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#e9ddff'
  secondary-fixed-dim: '#d1bcff'
  on-secondary-fixed: '#23005b'
  on-secondary-fixed-variant: '#5700c9'
  tertiary-fixed: '#ffd9e0'
  tertiary-fixed-dim: '#ffb1c3'
  on-tertiary-fixed: '#3f0019'
  on-tertiary-fixed-variant: '#8f0041'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 56px
    fontWeight: '800'
    lineHeight: 64px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.1em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  gutter: 16px
  container-padding: 24px
  section-gap: 48px
  element-gap: 12px
---

## Brand & Style
The design system is defined by a "Liquid Modernist" aesthetic—a fusion of high-end minimalism and vibrant, energetic pulses. It targets a forward-thinking audience that values clarity, speed, and tactile digital experiences. The emotional response should be one of "effortless precision."

The style utilizes heavy whitespace and extreme corner radii to create a friendly yet sophisticated silhouette. By combining the airiness of modern minimalism with the depth of glassmorphism, the UI feels organic and responsive. Every element is given room to breathe, strictly avoiding the "choked" or cluttered density often found in enterprise software.

## Colors
This design system employs a high-contrast, high-saturation palette against deep neutrals. The default mode is **Dark**, utilizing a true-black or deep charcoal foundation to make the "liquid" primary colors pop.

- **Primary (#00F0FF):** An electric cyan used for primary actions and active states.
- **Secondary (#7000FF):** A deep violet used for accents and secondary brand moments.
- **Tertiary (#FF007A):** A vibrant magenta reserved for highlights and critical notifications.
- **Surface Strategy:** Surfaces must maintain a minimum 15% contrast ratio against the background to ensure clear element separation.

## Typography
The typography strategy balances the friendly, rounded nature of **Plus Jakarta Sans** for headings with the systematic efficiency of **Inter** for long-form content. **JetBrains Mono** is introduced for labels and technical metadata to reinforce the modern, precise nature of the system.

Headlines should always use tighter letter spacing to maintain a "locked-in" visual feel, while body text remains generous to aid legibility within the expansive whitespace.

## Layout & Spacing
The layout follows a strict separation philosophy. It uses a 12-column fluid grid for desktop and a 4-column grid for mobile, but the defining characteristic is the **24px container padding** which acts as a "buffer zone" for all primary content modules.

- **Element Separation:** Elements must never overlap. Every card, button group, or text block is separated by at least a 16px gutter.
- **Breakpoints:** Mobile (< 600px), Tablet (600px - 1024px), Desktop (> 1024px).
- **Safe Zones:** Top bars and navigation elements occupy a fixed 80px height to ensure the content "liquidly" flows underneath without interference.

## Elevation & Depth
Depth is achieved through **Tonal Separation** and **Backdrop Blurs** rather than traditional heavy shadows. 

1.  **Level 0 (Background):** Solid deep neutral.
2.  **Level 1 (Cards/Containers):** Slightly lighter surface with a subtle 1px inner border (opacity 10%) to define the edge.
3.  **Level 2 (Modals/Overlays):** Centered floating containers utilizing a `40px` backdrop blur on the background layer. Shadows are "Ambient"—ultra-soft, 64px blur, 5% opacity, tinted with the primary cyan.

## Shapes
The shape language is "Liquid." This means extreme roundedness is the standard. All primary containers and buttons must use a corner radius between **24px and 32px**. This removes any sense of visual "sharpness," contributing to the friendly and modern feel. Smaller elements like chips or checkboxes utilize the full pill-shape.

## Components
### TopAppBar
The AppBar is split into three distinct zones: Left (Branding), Center (Navigation/Search), and Right (User Actions). Branding and Actions must be visually anchored to the margins, while the navigation "floats" to maintain the sense of openness.

### Buttons & Chips
Buttons are high-contrast. Primary buttons use the Cyan-to-Violet gradient with white or black text depending on legibility. Chips are fully rounded (pill-shaped) with a 1px border.

### Cards
Cards are the primary container. They must feature **24px internal padding** and **32px border radius**. Elements within the card must be spaced with an 8px or 16px rhythm to ensure no internal "choking."

### Input Fields
Inputs use a "Soft Inset" look: a 1px border that glows slightly (2px outer blur) when focused. The border radius matches the buttons at 24px.

### Modals
Modals are always centered. They occupy a maximum of 600px width on desktop. They must include a clear "X" close action in the top right, separated by the standard 24px padding from the modal content.