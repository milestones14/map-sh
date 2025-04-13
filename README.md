# Map.sh

A bash script that generates a hierarchical tree view of directory contents with advanced features for macOS.
<br />
<br />
_Want to see Map.sh for Linux? [Open an issue.](https://github.com/milestones14/map-sh/issues/new)_
## Features

- 📁 Maps directory structure with visual tree representation
- 📊 Calculates folder sizes
- 🔍 Filtering options for hidden files and subdirectories
- 💾 Save output to file
- 🚀 Special handling for macOS-specific directories (.app, .framework, etc.)

## Usage

```bash
./map.sh <directory> [save]

# Options
--ignore-hidden       # Skip hidden files and directories
--no-subdir           # Don't recurse into subdirectories
--only-folders        # Show only folders, skip files
--ignore-pkg-contents # Skip contents of .app, .framework, etc.
--no-size             # Don't calculate folder sizes
```

## Example Output

```bash
$ ./map.sh ~/Documents


/Users/username/Documents
| - Projects [folder, 179MB]
|   | - WebApp [folder, 156MB]
|   | - iOS.xcodeproj [xcode project, 23MB]
| - Documents.pdf [PDF file]

[DONE - 3 FOLDERS, 1 FILE, 4 ITEMS, 184MB TOTAL]
```

## Requirements

- macOS (uses macOS-specific `stat` command)
- Bash 3.2 or higher

## Notes

- Handles special macOS package types (.app, .bundle, .framework, .xcodeproj, .xcworkspace)
- Supports Unicode filenames and paths with spaces
- Provides real-time size calculation feedback
- Progress indicators for large directories
<br />
<br />
<br />
