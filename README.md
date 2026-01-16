# Map.sh

A bash script that generates a hierarchical tree view of directory contents with advanced features for macOS.
<br />
<br />
_Want to see Map.sh for Linux? Found a bug or have ideas for improvement? [Open an issue.](https://github.com/milestones14/map-sh/issues/new)_
## Features

- 📁 Maps directory structure with visual tree representation
- 📊 Calculates folder sizes
- 🔍 Filtering options for hidden files and subdirectories
- 💾 Save output to file
- 🚀 Special handling for macOS-specific directories (`.app`, `.framework`, etc.)

## Usage

```bash
./map.sh <directory> [options]
```

## Options
| Flag                    | Description                                       | Version of Map.sh |
|------------------------ | ------------------------------------------------- | ----------------- |
| `--ignore-hidden`       | Skip hidden files and directories.                | 1.0.0             |
| `--no-subdir`           | Don't recurse into subdirectories.                | 1.0.0             |
| `--only-folders`        | Show only folders, skip files.                    | 1.0.0             |
| `--ignore-pkg-contents` | Skip **_contents_** of `.app`, `.framework`, etc. | 1.0.0             |
| `--no-size`             | Don't calculate folder sizes.                     | 1.0.0             |
| `--save`                | Save the directory tree to a file.                | 1.0.0             |


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

## Get Started
To download and run Map.sh, [get the latest release](https://github.com/milestones14/map-sh/releases). Make sure to run `chmod +x path/to/map.sh` after downloading and unzipping.

## Requirements

- macOS (uses macOS-specific `stat` command)
- Bash 3.2 or higher

## Notes

- Handles special macOS package types (`.app`, `.bundle`, `.framework`, `.xcodeproj`, `.xcworkspace`)
- Supports Unicode filenames and paths with spaces
- Provides real-time size calculation feedback
- Progress indicators for large directories
