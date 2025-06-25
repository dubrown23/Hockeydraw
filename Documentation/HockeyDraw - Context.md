#  🏒 HOCKEY DRAW MASTER CONTEXT
(June 11, 2025 - v0.1)

## 🔧 General App Overview
- **App Name**: Hockey Draw
- **Purpose**: Professional hockey drill creation and animation app with Apple Pencil support
- **Core Technologies**:
  • UIKit for precise drawing control
  • Core Graphics for accurate rink rendering
  • Core Animation for drill animations
  • PencilKit for Apple Pencil integration
  • AVFoundation for video export
  • PDFKit for diagram export
  • Core Data for drill storage
- **Platforms**: iOS (iPad Pro optimized)
- **Distribution**: [Development Phase - Future App Store]
- **UI Design**: Professional coaching interface optimized for Apple Pencil workflow
- **Code Quality**: Clean, maintainable Swift with proper MVC architecture

## 📊 Data Architecture

### Core Data Model (Planned)
**Drill**: Main drill definition entity
- Properties: id, name, category, tags, dateCreated, dateModified, isFavorite
- Relationships: objects (one-to-many with DrillObject), paths (one-to-many with MovementPath)

**DrillObject**: Individual objects on ice (players, cones, pucks)
- Properties: id, type (player/cone/puck/goal), position (CGPoint), color, playerNumber, teamSide
- Relationships: drill (many-to-one with Drill), paths (one-to-many with MovementPath)

**MovementPath**: Drawing paths for object movement
- Properties: id, pathData (encoded UIBezierPath), movementType (skate/pass/shoot), startTime, duration, color
- Relationships: drill (many-to-one), object (many-to-one with DrillObject)

**DrillTemplate**: Pre-built drill patterns
- Properties: id, name, category, description, difficulty, playerCount
- Relationships: baseObjects (serialized drill setup)

### Persistence Stack (Planned)
- **CoreDataManager**: Singleton manager for drill storage
- **Container**: NSPersistentContainer for local storage
- **Backup System**: JSON export/import for drill sharing
- **File Format**: .drill files for cross-platform compatibility

## 🏗 App Architecture

### View Controller Structure
- **MainViewController**: Root container with drill canvas and controls
- **IceRinkView**: Custom UIView rendering NHL regulation rink
- **DrillCanvasViewController**: Manages object placement and drawing
- **AnimationViewController**: Controls drill playback and timing
- **DrillLibraryViewController**: Manages saved drills and templates
- **ExportViewController**: Handles video and PDF generation

### Key UI Components
- **IceRinkView**: Core drawing canvas with precise NHL specifications
- **ObjectPaletteView**: Draggable drill components (players, cones, pucks)
- **DrawingToolbar**: Tool selection and Apple Pencil controls
- **AnimationControls**: Playback, speed, and timing controls
- **PropertyPanel**: Object editing and customization

### Rink Rendering System
- **Precise Measurements**: All NHL specifications mathematically accurate
  • Rink: 200ft x 85ft (2.35:1 ratio)
  • Goal lines: 11ft from boards
  • Blue lines: 75ft from boards
  • Face-off circles: 15ft radius
  • Goal creases: 6ft radius
  • Corner radius: 28ft
- **Color Standards**: Official hockey colors (red lines, blue lines, white ice)
- **Scaling System**: Maintains proportions across all iPad sizes
- **Performance**: Optimized Core Graphics rendering for smooth drawing

## 📱 Current Implementation Status

### Core Rink Drawing (✅ Complete)
- **IceRinkView.swift**: Custom UIView with Core Graphics implementation
- **Precise Scaling**: Dynamic sizing maintaining 200:85 ratio
- **NHL Specifications**: All measurements proportionally accurate
- **Visual Polish**: Proper line weights, colors, and positioning
- **Board Line Rendering**: Clean edges with proper z-ordering

### Drawing Implementation Details
```swift
class IceRinkView: UIView {
    override func draw(_ rect: CGRect) {
        // NHL rink: 200ft x 85ft (exact 2.35:1 ratio)
        // Goal lines: 11ft from ends = 5.5% of 200ft
        // Blue lines: 75ft from ends = 37.5% of 200ft
        // Center circle: 15ft radius = 17.6% of 85ft width
        // Face-off circles: 15ft radius = 17.6% of 85ft width
        // Goals: 6ft x 4ft positioned on goal lines
        // Goal creases: 6ft radius extending toward center ice
    }
}
```

### Technical Achievements
- **Proportional Accuracy**: Maintains NHL specs regardless of iPad screen size
- **Visual Fidelity**: Professional appearance matching broadcast hockey
- **Performance**: Smooth rendering with efficient Core Graphics usage
- **Code Organization**: Clean separation of drawing logic and measurements

## 🎯 Feature Implementation Roadmap

### Phase 1: Foundation (Current - In Progress)
| Component | Status | Notes |
|-----------|--------|-------|
| IceRinkView | ✅ Complete | NHL regulation rink with accurate proportions |
| Basic Project Structure | ✅ Complete | UIKit-based with MVC architecture |
| iPad Interface | 🏗️ In Progress | Canvas and basic controls |
| Apple Pencil Setup | 📋 Planned | PencilKit integration |

### Phase 2: Object System (Next Priority)
| Component | Status | Notes |
|-----------|--------|-------|
| DrillObject Classes | 📋 Planned | Player, cone, puck, goal objects |
| Drag & Drop System | 📋 Planned | Touch and pencil interaction |
| Object Properties | 📋 Planned | Colors, numbers, team assignment |
| Selection System | 📋 Planned | Multi-select and editing |

### Phase 3: Drawing Engine
| Component | Status | Notes |
|-----------|--------|-------|
| Path Drawing | 📋 Planned | Apple Pencil path capture |
| Movement Types | 📋 Planned | Skating, passing, shooting lines |
| Path Editing | 📋 Planned | Modify existing paths |
| Path Association | 📋 Planned | Link paths to objects |

### Phase 4: Animation System
| Component | Status | Notes |
|-----------|--------|-------|
| Timeline Engine | 📋 Planned | Coordinate object movement |
| Animation Curves | 📋 Planned | Realistic skating physics |
| Collision Detection | 📋 Planned | Player interaction handling |
| Playback Controls | 📋 Planned | Play, pause, scrub, speed |

### Phase 5: Export & Sharing
| Component | Status | Notes |
|-----------|--------|-------|
| Video Export | 📋 Planned | MP4 generation with AVFoundation |
| PDF Export | 📋 Planned | Static drill diagrams |
| Drill File Format | 📋 Planned | .drill files for sharing |
| AirDrop Integration | 📋 Planned | Quick sharing between devices |

## 🎨 UI/UX Standards

### Visual Design Principles
- **Professional Appearance**: Clean, coach-friendly interface
- **Apple Pencil First**: Optimized for pencil workflow
- **Authentic Hockey**: Real NHL colors and proportions
- **Touch Targets**: Appropriate sizing for fingers and pencil
- **Contrast**: High contrast for rink visibility

### Color Standards
- **Ice Surface**: Pure white (#FFFFFF)
- **Goal Lines**: NHL red (#FF0000)
- **Blue Lines**: NHL blue (#0000FF)
- **Center Line**: NHL red (#FF0000)
- **Boards**: Black (#000000)
- **Goal Creases**: Light blue with transparency
- **Face-off Dots**: Solid red (#FF0000)

### Typography & Icons
- **Primary Font**: SF Pro (iOS system font)
- **Icon Style**: SF Symbols for consistency
- **Coaching Terminology**: Proper hockey terms throughout
- **Internationalization**: Ready for multiple languages

## 🔨 Technical Implementation Details

### Drawing Performance
- **Static Formatting**: Reuse formatters and drawing contexts
- **Efficient Rendering**: Minimize Core Graphics calls
- **Memory Management**: Proper cleanup of drawing resources
- **Background Processing**: Heavy calculations off main thread

### Apple Pencil Integration
- **Pressure Sensitivity**: Variable line weights for natural drawing
- **Tilt Support**: Natural pencil behavior
- **Palm Rejection**: Ignore palm touches during pencil use
- **Hover Support**: Preview placement before touching

### Animation Architecture
```swift
class AnimationEngine {
    func createAnimationFromPaths(_ paths: [MovementPath]) -> CAAnimation
    func calculateTiming(for objects: [DrillObject]) -> [TimeInterval]
    func handleCollisions(between objects: [DrillObject]) -> Bool
    func exportToVideo(animation: CAAnimation) -> URL
}
```

### File Format Standards
- **Drill Files**: JSON-based .drill format
- **Backward Compatibility**: Version-aware loading
- **Export Quality**: High-resolution outputs
- **Cross-Platform**: Readable by future tools

## 🎯 Current Development Status

### Working Features (v0.1)
- ✅ **Perfect NHL Rink**: Accurate proportions and positioning
- ✅ **Proper Colors**: Official hockey line colors
- ✅ **iPad Optimization**: Designed for iPad workflow
- ✅ **Clean Code**: Maintainable Swift implementation

### In Development
- 🏗️ **Object Placement**: Drag-and-drop system for drill components
- 🏗️ **Apple Pencil**: Drawing integration with PencilKit
- 🏗️ **Basic Animation**: Simple object movement

### Technical Debt
- Need comprehensive error handling
- Performance optimization for complex drills
- Memory management for large animations
- Accessibility support for coaching tools

## 🔧 Development Environment

### Requirements
- **Xcode**: 15.0+ for latest iOS features
- **iOS Deployment**: 18.0+ for modern APIs
- **Hardware**: iPad Pro for testing Apple Pencil
- **Languages**: Swift 5.9+

### Project Structure
```
HockeyDraw/
├── ViewControllers/
│   ├── MainViewController.swift
│   ├── DrillCanvasViewController.swift
│   └── AnimationViewController.swift
├── Views/
│   ├── IceRinkView.swift
│   ├── ObjectPaletteView.swift
│   └── AnimationControls.swift
├── Models/
│   ├── DrillObject.swift
│   ├── MovementPath.swift
│   └── DrillTemplate.swift
├── Utilities/
│   ├── AnimationEngine.swift
│   ├── ExportManager.swift
│   └── Constants.swift
└── Resources/
    └── Assets.xcassets
```

### Code Quality Standards
- **No Force Unwraps**: Safe optional handling throughout
- **Modern Swift**: Use latest language features appropriately
- **Documentation**: Inline comments for complex algorithms
- **Testing**: Unit tests for mathematical calculations
- **Performance**: Profile and optimize drawing code

## 🎯 Key Architectural Decisions

### UIKit vs SwiftUI Choice
- **UIKit Selected**: Better control for precise drawing and Apple Pencil
- **Core Graphics**: Required for accurate rink measurements
- **Performance**: Lower overhead for animation-heavy app
- **Maturity**: More stable APIs for drawing applications

### Data Storage Strategy
- **Core Data**: Local drill storage and management
- **JSON Export**: Human-readable drill files
- **No Cloud Sync**: Focus on local creation and file sharing
- **Version Control**: Track drill modifications

### Animation Approach
- **Core Animation**: Smooth, hardware-accelerated movement
- **Physics-Based**: Realistic skating and puck movement
- **Customizable**: Coach-controllable timing and speed
- **Export Ready**: Animation suitable for video generation

## 🔍 Performance Considerations

### Drawing Optimization
- **Cached Rink**: Pre-render static rink elements
- **Dirty Rectangles**: Only redraw changed areas
- **Level of Detail**: Simplify complex objects when zoomed out
- **Background Threading**: Heavy calculations off main queue

### Memory Management
- **Object Pooling**: Reuse drill objects to reduce allocation
- **Image Caching**: Cache commonly used graphics
- **Animation Cleanup**: Proper disposal of completed animations
- **Large Drill Support**: Handle drills with many objects efficiently

## 🐛 Known Issues & Limitations

### Current Limitations
- iPad-only interface (iPhone not optimized)
- No real-time collaboration features
- Limited export formats in initial version
- Requires Apple Pencil for optimal experience

### Technical Challenges
- Complex animation timing coordination
- Apple Pencil lag on older iPads
- Large file sizes for complex animated drills
- Cross-device compatibility for shared drills

## 📅 Version History & Roadmap

### Version 0.1 (Current)
- NHL regulation rink rendering
- Basic project structure
- iPad interface foundation

### Version 0.2 (Next Release)
- Object placement system
- Apple Pencil drawing
- Basic animation preview

### Version 1.0 (First Release)
- Complete drill creation workflow
- Video and PDF export
- Drill library management
- Basic sharing capabilities

### Version 1.5 (Enhanced)
- Advanced animation features
- Drill templates library
- Team management tools
- Cloud storage integration

### Version 2.0 (Professional)
- Real-time collaboration
- Advanced analytics
- Custom rink configurations
- Integration with team management systems

## 🎯 Success Metrics

### Technical Goals
- Smooth 60fps animation playback
- Sub-100ms Apple Pencil latency
- Export quality suitable for professional use
- Stable performance with 50+ drill objects

### User Experience Goals
- Intuitive for non-technical coaches
- Quick drill creation (under 5 minutes for simple drills)
- Professional-quality output
- Minimal learning curve for hockey coaches

✅ This Master Context file should be referenced for all future Hockey Draw development.
(Version 0.1 — June 11, 2025)
