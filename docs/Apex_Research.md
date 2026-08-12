# Neptune Apex — Research

Neptune Apex is an established aquarium controller ecosystem and is the clearest
reference point for understanding the type of system AquaSense is intended to
resemble.

The important thing about Apex is that it is not one device doing everything. It
is an ecosystem of a controller, power-control hardware, probes/sensors, and
additional testing or control modules.

## Apex Controller

The Apex controller is the central controller or "brain" of the system.

It connects the different hardware components and makes their information
available to the software/cloud interface.

Conceptually:

```text
Energy Bar ──┐
             │
Probes ──────┼──→ Apex Controller ──→ Apex Fusion / App
             │
Trident ─────┘
```

The controller is therefore the central point between the aquarium hardware and
the user interface.

## Energy Bar 832

The Energy Bar 832 is the power-control component.

It has **8 individually controllable AC outlets**.

These outlets are where aquarium equipment can be connected, such as:

* Return pumps
* Heaters
* Lights
* Skimmers
* Circulation pumps
* Other equipment

The important distinction is that these are **power outlets**, not water sensors.

The Energy Bar can also monitor power consumption from the connected equipment.

This makes information such as:

**Outlet 1 — Return Pump — ON — 42 W**

possible in the software.

If an outlet is off, its measured consumption can drop to:

**0 W**

The power information can also be useful for detecting equipment problems. For
example, a pump that should be running but is drawing no power can indicate that
something has stopped working.

## Probes / Sensors

The Apex system also uses separate probes and sensors for aquarium measurements.

Examples include:

### Temperature probe

Measures the aquarium's water temperature.

```text
Temperature probe
       ↓
Apex system
       ↓
78.2°F
```

### pH probe

Measures the aquarium's pH.

```text
pH probe
   ↓
Apex system
   ↓
8.15
```

### Salinity

A dedicated salinity/conductivity sensor can provide salinity information.

```text
Salinity sensor
      ↓
Conductivity measurement
      ↓
Salinity
      ↓
35.0 ppt
```

These sensors are fundamentally different from the Energy Bar outlets. The Energy
Bar deals with electrical power and connected equipment; the probes measure
conditions in the aquarium.

## Neptune Trident

The Trident is a separate automated testing device.

It tests:

* Alkalinity
* Calcium
* Magnesium

This is important because these values are not simply measured by the same basic
probes used for temperature or pH.

Conceptually:

```text
Aquarium water
      ↓
Trident
      ↓
Alkalinity
Calcium
Magnesium
      ↓
Apex system
      ↓
Software / app
```

The results can then be monitored alongside the other aquarium information.

## The Complete Apex Ecosystem

Putting the main components together:

```text
                         AQUARIUM
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ↓              ↓              ↓
          Probes         Trident       Equipment
        / Sensors            │              │
             │               │              ↓
        pH / Temp /       ALK / Ca /    Energy Bar 832
        Salinity            Mg              │
             │               │         8 outlets
             │               │              │
             └───────────────┼──────────────┘
                             ↓
                       APEX CONTROLLER
                             │
                             ↓
                      Apex Fusion / App
```

This explains why the controller experience can contain both water parameters and
power outlets even though they originate from different physical components.

## Why Apex Matters for AquaSense

AquaSense appears to be targeting the same general category: an integrated system
for monitoring and controlling a reef aquarium.

Apex demonstrates the product model:

**Sensors and testing hardware provide aquarium data.**

**Power hardware controls aquarium equipment.**

**A central controller connects the system.**

**Software brings everything together for the aquarium owner.**

## Important Hardware Distinction

The different sources of information should not be treated as one generic sensor
system.

### Energy Bar

Provides:

* 8 controllable outlets
* Equipment ON/OFF control
* Power consumption
* Electrical load information

### Probes / Sensors

Provide measurements such as:

* Temperature
* pH
* Salinity

### Trident

Provides automated chemical measurements:

* Alkalinity
* Calcium
* Magnesium

### Controller

Brings the different hardware components together and communicates their
information to the software.
