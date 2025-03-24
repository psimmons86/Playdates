#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

# Create a directory for the app icon if it doesn't exist
os.makedirs("PlaydatesApp/Assets.xcassets/AppIcon.appiconset", exist_ok=True)

# Define the icon sizes needed
icon_sizes = [
    (1024, "playdates-icon-1024.png"),
    (180, "playdates-icon-180.png"),
    (120, "playdates-icon-120.png"),
    (167, "playdates-icon-167.png"),
    (152, "playdates-icon-152.png"),
    (76, "playdates-icon-76.png"),
    # Additional sizes needed for iOS
    (40, "playdates-icon-40.png"),
    (60, "playdates-icon-60.png"),
    (58, "playdates-icon-58.png"),
    (87, "playdates-icon-87.png"),
    (80, "playdates-icon-80.png"),
    (20, "playdates-icon-20.png"),
    (29, "playdates-icon-29.png")
]

# Colors from ColorTheme
primary_color = (145, 221, 207)  # Mint green #91DDCF
secondary_color = (247, 249, 242)  # Off-white #F7F9F2
accent_color = (232, 197, 229)  # Soft lavender #E8C5E5
highlight_color = (241, 158, 210)  # Pink #F19ED2
text_color = (93, 78, 109)  # Dark Purple #5D4E6D

# Create the base icon (1024x1024)
icon_size = 1024
icon = Image.new('RGB', (icon_size, icon_size), primary_color)
draw = ImageDraw.Draw(icon)

# Draw rounded corners (approximate with a circle in each corner)
corner_radius = 220
draw.rectangle((corner_radius, 0, icon_size - corner_radius, icon_size), fill=primary_color)
draw.rectangle((0, corner_radius, icon_size, icon_size - corner_radius), fill=primary_color)
draw.ellipse((0, 0, corner_radius * 2, corner_radius * 2), fill=primary_color)
draw.ellipse((icon_size - corner_radius * 2, 0, icon_size, corner_radius * 2), fill=primary_color)
draw.ellipse((0, icon_size - corner_radius * 2, corner_radius * 2, icon_size), fill=primary_color)
draw.ellipse((icon_size - corner_radius * 2, icon_size - corner_radius * 2, icon_size, icon_size), fill=primary_color)

# Draw the stylized figures
# Child figure 1 (left)
draw.ellipse((400, 350, 460, 410), fill=secondary_color)  # Head
draw.ellipse((415, 370, 423, 378), fill=text_color)  # Left eye
draw.ellipse((437, 370, 445, 378), fill=text_color)  # Right eye
draw.ellipse((420, 390, 440, 396), fill=text_color)  # Mouth

# Adult figure (middle)
draw.ellipse((470, 330, 550, 410), fill=highlight_color)  # Head
draw.ellipse((490, 355, 500, 365), fill=text_color)  # Left eye
draw.ellipse((520, 355, 530, 365), fill=text_color)  # Right eye
draw.ellipse((500, 380, 525, 388), fill=text_color)  # Mouth

# Child figure 2 (right)
draw.ellipse((560, 350, 620, 410), fill=accent_color)  # Head
draw.ellipse((575, 370, 583, 378), fill=text_color)  # Left eye
draw.ellipse((597, 370, 605, 378), fill=text_color)  # Right eye
draw.ellipse((580, 390, 600, 396), fill=text_color)  # Mouth

# Add decorative elements
draw.ellipse((340, 340, 380, 380), fill=(*accent_color, 128))  # Circle top left
draw.ellipse((640, 340, 670, 370), fill=(*highlight_color, 128))  # Circle top right
draw.ellipse((640, 640, 665, 665), fill=(*secondary_color, 128))  # Circle bottom right

# Add app name at the bottom
# Note: This is a simple placeholder. In a real app, you'd use a proper font.
draw.rectangle((412, 700, 612, 730), fill=primary_color)  # Clear area for text
draw.text((440, 700), "Playdates", fill=text_color)

# Save the base icon
base_icon_path = "PlaydatesApp/Assets.xcassets/AppIcon.appiconset/playdates-icon-1024.png"
icon.save(base_icon_path)
print(f"Created base icon: {base_icon_path}")

# Generate all other sizes
for size, filename in icon_sizes:
    if size == 1024:  # Already created
        continue
    
    resized_icon = icon.resize((size, size), Image.LANCZOS)
    output_path = f"PlaydatesApp/Assets.xcassets/AppIcon.appiconset/{filename}"
    resized_icon.save(output_path)
    print(f"Created icon: {output_path}")

print("App icons generated successfully!")
