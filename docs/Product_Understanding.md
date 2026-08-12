# AquaSense — Product Understanding

> Written while researching the product, before the interface was built. A few
> layout choices changed once the design was in front of a real screen — where
> that happened it is noted inline, and the reasoning is in the README.

AquaSense appears to be an aquarium management and control system for reef
aquarium owners. The product brings aquarium monitoring and equipment control
into one dashboard.

The main idea is to let the owner see what is happening inside the aquarium and
what the connected equipment is doing without having to check each device
separately.

## What AquaSense manages

There are two main parts:

### 1. Water / Aquarium Monitoring

The system can bring together readings such as:

* pH
* Temperature
* Salinity
* ORP
* Calcium
* Magnesium
* Alkalinity

These values tell the owner about the condition of the aquarium.

The UI should make it easy to see the current value, the unit, and whether the
reading is in a safe range.

For example:

**pH — 8.15**

**Temperature — 78.2°F**

**Salinity — 35.0 ppt**

**Calcium — 435 ppm**

**Magnesium — 1320 ppm**

The values do not all necessarily come from the same type of sensor. Basic
measurements such as temperature, pH, salinity and ORP can come from
probes/sensors, while Calcium, Magnesium, and Alkalinity can come from automated
testing equipment such as a Trident-style device.

This distinction turned out to be the most important thing in the whole product,
and it drives how the dashboard is organised. A probe is sampled continuously, so
a trend line over it is real. A titration device runs a chemical test on a
schedule, so its results are discrete points hours apart — drawing a continuous
line between them would imply data the controller does not have.

### 2. Equipment Control

AquaSense also controls and monitors aquarium equipment connected to a
power-control system.

The main example is an 8-outlet Energy Bar-style unit.

The outlets can be used for equipment such as:

* Return pump
* Heater
* Lights
* Protein skimmer
* Circulation pumps
* ATO pump
* Doser
* Other aquarium equipment

Each outlet can have its own state and power reading.

For example:

**Outlet 1 — Return Pump — ON — 42 W**

**Outlet 4 — Heater — OFF — 0 W**

The outlet can be controlled individually, and the dashboard shows whether it is
ON or OFF.

## How the information fits together

AquaSense should be thought of as the software layer that brings different
aquarium hardware into one place.

Conceptually:

```text
             AQUARIUM
                 │
       ┌─────────┴─────────┐
       │                   │
   Probes / Sensors    Testing Device
       │                   │
   pH / Temp /          Ca / Mg /
   Salinity / ORP       Alkalinity
       │                   │
       └─────────┬─────────┘
                 ↓
             Controller
                 │
        ┌────────┴────────┐
        ↓                 ↓
   AquaSense App     Power Hardware
                          │
                    8 controlled outlets
                          │
              ┌───────────┼───────────┐
              ↓           ↓           ↓
             Pump       Heater       Lights
```

The exact AquaSense hardware architecture is not confirmed from the available
product information. The above describes the product concept and the type of
system the UI is representing.

## What the dashboard needs to communicate

The app needs to answer two basic questions quickly:

**How is my aquarium doing?**

and

**What is my equipment doing?**

That means the interface needs both:

### Aquarium health

* Current water parameters
* Safe/drifting/out-of-range status
* Parameter trends
* Anything that needs attention

### Equipment status

* Which outlets are active
* Which equipment is connected to each outlet
* ON/OFF state
* Current power consumption
* Total electrical load

## UI direction

The controller screen reflects this structure.

### Header

* AquaSense wordmark

### Trident

Three cards, because these three values come from one test run and are read as a
set:

* Alkalinity
* Calcium
* Magnesium

Each card shows:

* Parameter name
* Current value inside a ring gauge
* Unit
* Where the reading sits across the parameter's full scale

How long ago the test ran is shown on the section header, since a titration
result is only as good as how recent it is.

### Live Water

Four cards for the continuously sampled probes:

* pH
* Salinity
* Temperature
* ORP

Each card shows the current value and a 24-hour trace, with dashed rules marking
the parameter's target limits so the reading can be judged without knowing reef
chemistry.

The status system uses:

* Cyan = in range
* Amber = drifting
* Red = out of range

Colour is reserved for status alone. Nothing decorative borrows from that ramp,
because a card that is amber for branding reasons is indistinguishable from one
that is amber because the tank is in trouble.

### Power Board

The power section represents an 8-outlet Energy Bar-style board, laid out in the
chassis's real 2 × 4 arrangement.

Each outlet shows:

* Socket, drawn with real NEMA slot geometry
* Outlet number
* Live draw in watts, directly beneath the outlet
* ON/OFF toggle

The whole tile is the tap target, not just the switch.

The total load is also shown, for example:

**181 W · 1.5 A**

## Responsive behavior

The product is not just a mobile dashboard, so the layout has to adapt.

*This is the part that changed most once the design met a real screen.* The
original thought was that eight outlets would become a vertical list on a phone,
since eight columns seemed unlikely to fit.

That turned out to be the wrong call. The outlet arrangement has to match the
physical unit at every width — an outlet that moves when the screen narrows can
no longer be matched against the bar on the wall, which defeats the purpose of
drawing it as a board at all. Removing the per-outlet card chrome freed enough
width to keep the true 2 × 4 down to 360pt. Below roughly 300pt of usable width
the board scrolls sideways instead of rearranging.

The parameter cards do reflow:

* Phone — Trident three across, Live Water as a 2 × 2
* Tablet — the same structure with more breathing room

The information and hierarchy stay the same at every size; only the spacing
changes.

## Overall understanding

AquaSense is best understood as a central interface for a reef aquarium system.

It brings together:

**Water measurements + automated testing + equipment control + power monitoring**

into one place.

The app is therefore not simply a water-tracking app. The stronger concept is an
**aquarium control center** where the owner can monitor the tank, understand
equipment activity, control connected equipment, and quickly spot anything that
needs attention.
