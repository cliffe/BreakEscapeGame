# PixelLab to Phaser.js Sprite Sheet Converter

This script converts PixelLab character animation directories into optimized sprite sheets with Phaser.js-compatible JSON atlases.

## Why Sprite Sheets?

For Phaser.js games, sprite sheets are essential for:
- **Performance**: Single HTTP request instead of dozens/hundreds
- **Memory**: More efficient GPU texture management
- **Rendering**: Faster frame switching during animations
- **Loading**: Quicker initial load times

## Installation

The script requires Python 3.6+ and Pillow (PIL):

```bash
pip install Pillow
```

Or if you have a requirements.txt:
```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

```bash
python tools/convert_pixellab_to_spritesheet.py ~/Downloads/characters ./assets/sprites
```

### Arguments

- `input_dir`: Directory containing PixelLab character folders
- `output_dir`: Where to save the generated sprite sheets and atlases
- `--padding`: (Optional) Padding between frames in pixels (default: 2)

### Example

```bash
# Convert all characters from Downloads to game assets
python tools/convert_pixellab_to_spritesheet.py \
    ~/Downloads/characters \
    ./public/break_escape/assets/characters
```

## Input Directory Structure

The script expects this structure (as exported from PixelLab):

```
characters/
├── Female_woman._Hacker_in_a_hoodie._Hood_up_black_ob/
│   └── animations/
│       ├── breathing-idle/
│       │   ├── east/
│       │   │   ├── frame_000.png
│       │   │   ├── frame_001.png
│       │   │   └── ...
│       │   ├── north/
│       │   ├── north-east/
│       │   └── ...
│       ├── walk/
│       │   ├── east/
│       │   └── ...
│       └── ...
└── Other_Character/
    └── animations/
        └── ...
```

## Output Files

For each character, the script generates two files:

### 1. Sprite Sheet PNG (`character_name.png`)
- Single PNG combining all animation frames
- Optimized layout for efficient GPU usage
- Transparent background (RGBA)

### 2. Atlas JSON (`character_name.json`)
- Phaser.js-compatible JSON Hash format
- Contains frame positions and dimensions
- Includes animation metadata organized by type and direction
- Custom `animations` field for easy animation creation

## Using in Phaser.js

### 1. Loading the Sprite Sheet

```javascript
function preload() {
    this.load.atlas(
        'female_hacker',
        'break_escape/assets/characters/female_hacker.png',
        'break_escape/assets/characters/female_hacker.json'
    );
}
```

### 2. Creating Animations

#### Manual Method:
```javascript
function create() {
    this.anims.create({
        key: 'breathing-idle-east',
        frames: this.anims.generateFrameNames('female_hacker', {
            prefix: 'breathing-idle_east_frame_',
            start: 0,
            end: 3,
            zeroPad: 3
        }),
        frameRate: 8,
        repeat: -1
    });
}
```

#### Dynamic Method (Recommended):
```javascript
function create() {
    // Load the atlas data
    const atlasTexture = this.textures.get('female_hacker');
    const atlasData = this.cache.json.get('female_hacker');
    
    // Create all animations from metadata
    if (atlasData.animations) {
        for (const [animKey, frames] of Object.entries(atlasData.animations)) {
            this.anims.create({
                key: animKey,
                frames: frames.map(frameName => ({
                    key: 'female_hacker',
                    frame: frameName
                })),
                frameRate: 8,
                repeat: -1
            });
        }
    }
    
    // Use the animation
    const sprite = this.add.sprite(400, 300, 'female_hacker');
    sprite.play('breathing-idle_east');
}
```

### 3. Switching Animations

```javascript
// Change direction based on player input
if (cursors.right.isDown) {
    sprite.play('walk_east', true);
} else if (cursors.up.isDown) {
    sprite.play('walk_north', true);
} else {
    sprite.play('breathing-idle_east', true);
}
```

## Atlas JSON Structure

The generated JSON includes:

```json
{
  "frames": {
    "breathing-idle_east_frame_000": {
      "frame": {"x": 0, "y": 0, "w": 80, "h": 80},
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": {"x": 0, "y": 0, "w": 80, "h": 80},
      "sourceSize": {"w": 80, "h": 80}
    },
    ...
  },
  "meta": {
    "app": "PixelLab to Phaser Converter",
    "image": "female_hacker.png",
    "format": "RGBA8888",
    "size": {"w": 1280, "h": 960},
    "scale": "1"
  },
  "animations": {
    "breathing-idle_east": ["breathing-idle_east_frame_000", "breathing-idle_east_frame_001", ...],
    "breathing-idle_north": [...],
    "walk_east": [...],
    ...
  }
}
```

## Tips

1. **Frame Rate**: Adjust `frameRate` in your animations based on the visual speed you want (typically 8-12 for character animations)

2. **Preloading**: Load all sprite sheets in the preload phase to avoid lag during gameplay

3. **Multiple Characters**: Process all characters at once - the script handles multiple character directories automatically

4. **Direction Names**: The script preserves PixelLab's direction names (east, north, north-east, etc.)

5. **Animation Keys**: Animation keys are formatted as `{animation-type}_{direction}` (e.g., `walk_east`, `breathing-idle_north`)

## Troubleshooting

**No animations found**: Ensure your character directory has an `animations` subdirectory

**Frame size mismatch**: All frames should be the same dimensions (e.g., 80x80 pixels)

**Large sprite sheets**: If your sprite sheet is too large, consider splitting characters into separate sheets or reducing frame counts

## Performance Notes

- Each sprite sheet is kept as a single texture for optimal GPU performance
- The JSON atlas allows Phaser to quickly locate frames without additional parsing
- The `animations` metadata enables dynamic animation creation without hardcoding frame names
