# Cutline

**Cutline** is a minimalist and highly satisfying geometry puzzle game built with Flutter. The objective is simple but challenging: slice a random shape into two pieces that match a specific area ratio as accurately as possible.

![Cutline Logo](logo.png)

## Features

- **Free-hand Slashing**: Draw any polyline path with your finger. The game engine uses an advanced polyline-polygon splitting algorithm to cut the object exactly where you draw.
- **Dynamic Shape Generation**: Procedurally generated organic shapes (Blobs) and sharp polygons (Pointy).
- **Object Library**: A curated collection of day-to-day silhouettes including Hearts, Bottles, Houses, and more.
- **Pass the Phone Multiplayer**: Compete with up to 5 friends on the same device. Each person takes a turn on the same shape, and a leaderboard shows the most accurate "Cutter" at the end.
- **Precision Scoring**: An accurate geometry engine calculates the area of each resulting piece (subtracting any internal holes) to give you a percentage score.
- **Rich Aesthetics**: A premium high-contrast theme featuring Charcoal Grey, Vibrant Orange, and smooth animations.

## Tech Stack

- **Flutter / Dart**
- **Custom Geometry Engine**: Implemented area calculations (Shoelace formula), Chaikin's curvature smoothing, and polyline splitting.
- **Provider**: For clean and reactive state management.

## Settings

Customize your experience in the settings menu:

- **Target Ratio**: Set the challenge from a simple 50/50 split to a complex 10/90 ratio.
- **Symmetry**: Toggle between symmetric and completely random shapes.
- **Pointy vs. Smooth**: Choose between sharp polygonal vertices or rounded organic blobs.

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/knkahuro/cutline.git
   ```

2. Navigate to the project directory:

   ```bash
   cd cutline
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```
