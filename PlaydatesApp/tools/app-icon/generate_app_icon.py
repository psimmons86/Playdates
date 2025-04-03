#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os
import math

# Create a directory for the app icon if it doesn't exist
output_dir = "PlaydatesApp/Assets.xcassets/AppIcon.appiconset"
os.makedirs(output_dir, exist_ok=True)

# Define the icon sizes needed
icon_sizes = [
    (1024, "playdates-icon-1024.png"),
    (180, "playdates-icon-180.png"), # iPhone @3x
    (120, "playdates-icon-120.png"), # iPhone @2x
    (167, "playdates-icon-167.png"), # iPad Pro @2x
    (152, "playdates-icon-152.png"), # iPad @2x
    (87, "playdates-icon-87.png"),  # iPhone Notification @3x
    (80, "playdates-icon-80.png"),  # Spotlight @2x
    (76, "playdates-icon-76.png"),  # iPad @1x
    (60, "playdates-icon-60.png"),  # iPhone App @3x
    (58, "playdates-icon-58.png"),  # iPhone Notification @2x
    (40, "playdates-icon-40.png"),  # Spotlight @1x, Settings @2x
    (29, "playdates-icon-29.png"),  # Settings @1x
    (20, "playdates-icon-20.png")   # Notification @1x
]

# Colors from ColorTheme (RGB tuples 0-255)
primary_color = (145, 221, 207)  # Mint green #91DDCF
secondary_color = (247, 249, 242)  # Off-white #F7F9F2
accent_color = (232, 197, 229)  # Soft lavender #E8C5E5
highlight_color = (241, 158, 210)  # Pink #F19ED2
text_color = (93, 78, 109)      # Dark Purple #5D4E6D
info_blue_color = (33, 150, 243)   # Info Blue #2196F3

# Create the base icon (1024x1024)
base_size = 1024
# Use the Info Blue color for the background
icon = Image.new('RGBA', (base_size, base_size), info_blue_color)
draw = ImageDraw.Draw(icon)

# --- New Icon Design: Calendar with Activity Icons ---

# Define dimensions relative to base_size
calendar_size = base_size * 0.65 # Make calendar larger
icon_size_small = base_size * 0.12 # Size of small activity icons
offset_factor = calendar_size * 0.4 # How far to offset small icons

# Center positions
center_x = base_size / 2
center_y = base_size / 2

# Draw Base Calendar (Lavender)
calendar_x1 = center_x - calendar_size / 2
calendar_y1 = center_y - calendar_size / 2
calendar_x2 = center_x + calendar_size / 2
calendar_y2 = center_y + calendar_size / 2
calendar_corner_radius = calendar_size * 0.1
draw.rounded_rectangle(
    [calendar_x1, calendar_y1, calendar_x2, calendar_y2],
    radius=calendar_corner_radius,
    fill=accent_color # Lavender
)
# Add calendar top bar detail (slightly darker lavender or dark purple)
top_bar_height = calendar_size * 0.15
draw.rounded_rectangle(
    [calendar_x1, calendar_y1, calendar_x2, calendar_y1 + top_bar_height],
    radius=calendar_corner_radius,
    fill=text_color # Dark Purple
)
# Simulate rings (optional)
ring_radius = top_bar_height * 0.2
ring_y = calendar_y1 + top_bar_height / 2
ring_spacing = calendar_size * 0.2
draw.ellipse([center_x - ring_spacing - ring_radius, ring_y - ring_radius, center_x - ring_spacing + ring_radius, ring_y + ring_radius], fill=info_blue_color)
draw.ellipse([center_x + ring_spacing - ring_radius, ring_y - ring_radius, center_x + ring_spacing + ring_radius, ring_y + ring_radius], fill=info_blue_color)


# Function to draw SF Symbols (requires a font that supports them or pre-rendered images)
# Pillow doesn't directly support SF Symbols. We'll use simple shapes as placeholders.
# In a real scenario, you'd use a tool that can render SF Symbols or use pre-rendered images.

def draw_placeholder_icon(symbol_name, position, size, color):
    x, y = position
    half_size = size / 2
    if symbol_name == "leaf.fill": # Tree placeholder (Greenish)
        draw.ellipse([x - half_size, y - half_size, x + half_size, y + half_size], fill=primary_color)
    elif symbol_name == "building.columns.fill": # Museum placeholder (Dark Purple)
        draw.rectangle([x - half_size, y - half_size, x + half_size, y + half_size], fill=text_color)
    elif symbol_name == "figure.play": # Playground placeholder (Pink)
        # Simple stick figure
        head_radius = size * 0.2
        body_height = size * 0.4
        arm_width = size * 0.4
        leg_sep = size * 0.2
        draw.ellipse([x - head_radius, y - half_size, x + head_radius, y - half_size + 2 * head_radius], fill=color) # Head
        draw.line([(x, y - half_size + 2 * head_radius), (x, y + head_radius)], fill=color, width=max(1, int(size*0.1))) # Body
        draw.line([(x - arm_width/2, y), (x + arm_width/2, y)], fill=color, width=max(1, int(size*0.1))) # Arms
        draw.line([(x, y + head_radius), (x - leg_sep, y + half_size)], fill=color, width=max(1, int(size*0.1))) # Left Leg
        draw.line([(x, y + head_radius), (x + leg_sep, y + half_size)], fill=color, width=max(1, int(size*0.1))) # Right Leg


# Draw Placeholder Icons around Calendar
icon_center_y = center_y + top_bar_height / 2 # Center icons vertically below top bar

# Tree Icon (Top Left)
draw_placeholder_icon(
    "leaf.fill",
    (center_x - offset_factor, icon_center_y - offset_factor * 0.8),
    icon_size_small,
    highlight_color # Pink
)

# Museum Icon (Top Right)
draw_placeholder_icon(
    "building.columns.fill",
    (center_x + offset_factor, icon_center_y - offset_factor * 0.8),
    icon_size_small,
    text_color # Dark Purple
)

# Playground Icon (Bottom Center)
draw_placeholder_icon(
    "figure.play",
    (center_x, icon_center_y + offset_factor * 0.8),
    icon_size_small,
    highlight_color # Pink
)


# --- End New Icon Design ---

# Save the base icon
base_icon_path = os.path.join(output_dir, "playdates-icon-1024.png")
icon.save(base_icon_path)
print(f"Created base icon: {base_icon_path}")

# Generate all other sizes
for size, filename in icon_sizes:
    if size == base_size:  # Already created
        continue

    # Use high-quality downsampling
    resized_icon = icon.resize((size, size), Image.Resampling.LANCZOS)
    output_path = os.path.join(output_dir, filename)
    resized_icon.save(output_path)
    print(f"Created icon: {output_path}")

print("\nApp icons generated successfully!")
print(f"Ensure the Contents.json in '{output_dir}' is updated if needed.")
print("Remember to clean the build folder in Xcode and rebuild the app.")
