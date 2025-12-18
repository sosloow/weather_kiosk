#!/bin/bash
set -e

# Define directories and colors
SRC_DIR="priv/static/images/SVG"
DEST_DIR="priv/static/images/weather"

# DEFAULT_FILL_COLOR="#a6adbb"
DEFAULT_FILL_COLOR="#38bdf8"
SUN_MOON_FILL_COLOR="#fcd34d"

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Function to convert a single icon
convert_icon() {
  local src_svg="$1"
  local dest_name="$2"
  local fill_color="${3:-$DEFAULT_FILL_COLOR}" # Use provided color or default
  local dest_png="${dest_name}.png"

  if [ ! -f "$SRC_DIR/$src_svg" ]; then
    echo "Warning: Source file not found, skipping: $SRC_DIR/$src_svg"
    return
  fi

  echo "Converting $src_svg to $dest_png with color $fill_color"
  # Use ImageMagick to convert SVG to PNG with a specific fill color and transparent background
  if command -v convert &>/dev/null; then
    convert -background none -fill "$fill_color" -colorize 100 "$SRC_DIR/$src_svg" "$DEST_DIR/$dest_png"
  else
    echo "Error: ImageMagick not found. Please install it."
    echo "Ubuntu/Debian: sudo apt install imagemagick"
    exit 1
  fi
}

# --- Icon Mapping ---

# Weather conditions with default color
convert_icon "cloud-sun.svg" "partly-cloudy"
convert_icon "cloud-moon.svg" "partly-cloudy-night"
convert_icon "cloud.svg" "cloudy"
convert_icon "clouds.svg" "overcast"
convert_icon "cloud-fog.svg" "mist"
convert_icon "cloud-fog-moon.svg" "mist-night"
convert_icon "cloud-fog.svg" "fog"
convert_icon "cloud-fog.svg" "freezing-fog"
convert_icon "cloud-drizzle.svg" "patchy-rain"
convert_icon "cloud-drizzle-moon.svg" "patchy-rain-night"
convert_icon "drizzle.svg" "patchy-light-drizzle"
convert_icon "drizzle.svg" "light-drizzle"
convert_icon "cloud-drizzle.svg" "freezing-drizzle"
convert_icon "cloud-drizzle.svg" "heavy-freezing-drizzle"
convert_icon "cloud-rain.svg" "patchy-light-rain"
convert_icon "cloud-rain-moon.svg" "patchy-light-rain-night"
convert_icon "rain.svg" "light-rain"
convert_icon "cloud-rain.svg" "moderate-rain-at-times"
convert_icon "cloud-rain-moon.svg" "moderate-rain-at-times-night"
convert_icon "rain.svg" "moderate-rain"
convert_icon "cloud-rain-2.svg" "heavy-rain-at-times"
convert_icon "cloud-rain-2-moon.svg" "heavy-rain-at-times-night"
convert_icon "rain.svg" "heavy-rain"
convert_icon "cloud-drizzle.svg" "light-freezing-rain"
convert_icon "cloud-drizzle.svg" "moderate-or-heavy-freezing-rain"
convert_icon "cloud-rain.svg" "light-rain-shower"
convert_icon "cloud-rain-2.svg" "moderate-or-heavy-rain-shower"
convert_icon "cloud-rain-2.svg" "torrential-rain-shower"
convert_icon "hail.svg" "light-sleet"
convert_icon "hail.svg" "moderate-or-heavy-sleet"
convert_icon "cloud-drizzle.svg" "patchy-sleet"
convert_icon "cloud-drizzle-moon.svg" "patchy-sleet-night"
convert_icon "hail.svg" "light-sleet-showers"
convert_icon "hail.svg" "moderate-or-heavy-sleet-showers"
convert_icon "cloud-snow.svg" "patchy-snow"
convert_icon "cloud-snow-moon.svg" "patchy-snow-night"
convert_icon "cloud-wind.svg" "blowing-snow"
convert_icon "cloud-wind.svg" "blizzard"
convert_icon "cloud-snow.svg" "patchy-light-snow"
convert_icon "cloud-snow-moon.svg" "patchy-light-snow-night"
convert_icon "snow.svg" "light-snow"
convert_icon "cloud-snow.svg" "patchy-moderate-snow"
convert_icon "cloud-snow-moon.svg" "patchy-moderate-snow-night"
convert_icon "snow.svg" "moderate-snow"
convert_icon "cloud-snow.svg" "patchy-heavy-snow"
convert_icon "cloud-snow-moon.svg" "patchy-heavy-snow-night"
convert_icon "snow.svg" "heavy-snow"
convert_icon "cloud-snow.svg" "light-snow-showers"
convert_icon "cloud-snow.svg" "moderate-or-heavy-snow-showers"
convert_icon "hail.svg" "ice-pellets"
convert_icon "hail.svg" "light-showers-of-ice-pellets"
convert_icon "hail.svg" "moderate-or-heavy-showers-of-ice-pellets"
convert_icon "cloud-lightning.svg" "thundery-outbreaks"
convert_icon "cloud-lightning-moon.svg" "thundery-outbreaks-night"
convert_icon "cloud-rain-lightning.svg" "patchy-light-rain-with-thunder"
convert_icon "cloud-rain-lightning-moon.svg" "patchy-light-rain-with-thunder-night"
convert_icon "thunderstorm.svg" "moderate-or-heavy-rain-with-thunder"
convert_icon "cloud-lightning.svg" "patchy-light-snow-with-thunder"            # Fallback
convert_icon "cloud-lightning-moon.svg" "patchy-light-snow-with-thunder-night" # Fallback
convert_icon "thunderstorm.svg" "moderate-or-heavy-snow-with-thunder"
convert_icon "wet.svg" "wet"
convert_icon "wind.svg" "wind"

# Sun and Moon phases with special color
convert_icon "sun.svg" "sunny" "$SUN_MOON_FILL_COLOR"
convert_icon "moon-stars.svg" "sunny-night" "$SUN_MOON_FILL_COLOR"
convert_icon "moon-25.svg" "moon-25" "$SUN_MOON_FILL_COLOR"
convert_icon "moon-50.svg" "moon-50" "$SUN_MOON_FILL_COLOR"
convert_icon "moon-75.svg" "moon-75" "$SUN_MOON_FILL_COLOR"
convert_icon "moon-100.svg" "moon-100" "$SUN_MOON_FILL_COLOR"
convert_icon "sun-low.svg" "sun-low" "$SUN_MOON_FILL_COLOR"
convert_icon "sun-lower.svg" "sun-lower" "$SUN_MOON_FILL_COLOR"
convert_icon "sun-set.svg" "sun-set" "$SUN_MOON_FILL_COLOR"

echo ""
echo "Icon conversion complete!"
