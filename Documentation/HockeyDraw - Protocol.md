# 🏒 HOCKEY DRAW COLLABORATION PROTOCOL
Updated: June 11, 2025
## 🔑 Essential Working Rules
### 1. EXPLICIT ACKNOWLEDGMENT REQUIRED
At the start of each new chat, I will explicitly
acknowledge this protocol with the exact phrase: **"I
acknowledge the Hockey Draw Collaboration Protocol and
will follow all rules precisely."**
### 2. ONE COMPLETE FILE AT A TIME
- I will only provide ONE complete file implementation per
response
- Each file will be contained in a SINGLE code block
- I will wait for your confirmation before providing the
next file
- I will NEVER use placeholder comments like "// rest of
code remains the same"
### 3. CLEAR FILE IDENTIFICATION
- Every code response will begin with: **"FILE:
[filename.swift]"**
- I will explicitly state if it's a new file or an update
to an existing file
- I will confirm the file's location in the project
structure
### 4. GREEN UPDATE BARS
- ✅ Every code update will be announced with a full-width
green bar
- The format will be: **"✅ UPDATED: [filename.swift]"**
- All changes will be explicitly described AFTER the code
block
### 5. EXPLICIT BUILD INSTRUCTIONS
- After providing code, I will include specific build and
test instructions
- These will always appear in a separate section after the
code explanation
### 6. FILE VERIFICATION BEFORE CHANGES
- I will confirm which file I'm updating by stating:
**"Updating: [filename.swift]"**
- If uncertain, I will ask: **"Are we updating [filename]
or [other filename]?"**
- I will show awareness of the current file content before
making changes
## 📋 Workflow Requirements
### 1. CHANGE TRANSPARENCY
- After each code update, I will provide a bulleted list of
ALL changes made
- I will explain every modification, no matter how small
- All affected functions/properties will be explicitly
named
### 2. UPDATE LOG SYSTEM
- After each significant code change, I will ALWAYS prompt:
**"Would you like me to update the Update Log?"**
- If confirmed, I will create a proper Update Log entry
with this exact format:
MM.DD.YYYY - Code Update
- [Feature/fix description in past tense]
- [Feature/fix description in past tense]
- I will then ALWAYS ask: **"Would you like to add any
specific tags to this update?"**
- I understand that the Update Log is a dedicated file
where ALL changes are documented
- Update Log entries must use proper bullet points and past
tense descriptions
### 3. ERROR HANDLING
- If I spot potential errors or conflicts, I will
proactively highlight them
- I will not make architectural choices without explicit
approval
- When uncertain, I will ask clarifying questions before
proceeding
## 📚 Documentation Management
### 1. MASTER DOCUMENT UPDATES
- When completing major project phases, I will ALWAYS ask:
**"Should we update the master documentation?"**
- Master documents include: Master Context, App Overview,
Technical Reference, and this Protocol
- Updates must maintain original format while adding new
information
- Version dates must be updated with each revision
### 2. PROJECT COMPLETION PROTOCOLS
- Upon completing major features/implementations, I will create
comprehensive completion summaries
- Include detailed checklists of what was accomplished
- Update all relevant status indicators in master documents
- Document any new patterns or standards established
### 3. CONTEXT SYNCHRONIZATION
- I will reference uploaded files against master context
for consistency
- Flag any discrepancies between documentation and actual
implementation
- Suggest master document updates when significant changes
occur
## 🎨 Code Style Requirements
### 1. FUNCTIONALITY FIRST
- Stability and functionality take absolute priority over
design improvements
- All existing functionality must be preserved in every
update
### 2. COMPLETE CODE ONLY
- All code blocks will contain COMPLETE implementation
files
- No fragments, placeholders, or omissions will ever be
used
### 3. DARK/LIGHT MODE COMPATIBILITY
- All UI code must work properly in both Dark and Light
modes
- Use `.foregroundStyle` instead of `.foregroundColor`
- Always use system colors or `Color(uiColor: .systemXXX)`
variants
- All SF Symbols must use
`.symbolRenderingMode(.hierarchical)`
### 4. UIKIT BEST PRACTICES
- Use proper Auto Layout constraints and safe areas
- Respect system styling with appropriate UI elements
- Avoid over-nested view hierarchies
- Favor `.spring()` animations where natural
- Use consistent spacing and padding throughout
### 5. DEPLOYMENT SAFETY
- New risky features must be behind toggles or in isolated
components
- Handle Swift version differences appropriately (5.8 vs
5.9+)
- Maintain backward compatibility for data structures
### 6. CORE GRAPHICS PRECISION
- Always maintain NHL regulation proportions
- Use precise mathematical calculations for rink measurements
- Ensure drawing performance remains smooth
- Test on actual iPad hardware when possible
## 🏒 Hockey Draw Specific Standards
### 1. NHL REGULATION COMPLIANCE
- All rink measurements must match official NHL specifications
- Maintain 200ft x 85ft proportions (2.35:1 ratio)
- Goal lines: 11ft from boards, Blue lines: 75ft from boards
- Face-off circles: 15ft radius, Goal creases: 6ft radius
### 2. DRAWING PERFORMANCE
- IceRinkView rendering must remain smooth and responsive
- Use Core Graphics efficiently to minimize drawing overhead
- Cache static elements when possible
- Optimize for Apple Pencil latency
### 3. COACH-FRIENDLY DESIGN
- Interface must be intuitive for non-technical hockey coaches
- Use proper hockey terminology throughout
- Visual elements should match real hockey equipment and markings
- Professional appearance suitable for team presentations
### 4. APPLE PENCIL OPTIMIZATION
- All drawing interactions should feel natural with Apple Pencil
- Support pressure sensitivity and tilt where appropriate
- Implement palm rejection for comfortable drawing
- Maintain low latency for responsive drawing experience
## 🔍 File Organization Standards
### 1. SYSTEMATIC REVIEW PROCESS
- When reviewing multiple files, analyze and document
patterns first
- Group files by similar functionality (Views, Controllers,
Models, Utilities)
- Address files in logical dependency order
- Maintain running checklist of completed vs. pending files
### 2. OPTIMIZATION WORKFLOWS
- Core drawing performance before visual enhancements
- Essential functionality before convenience features
- Error handling before edge case optimization
- Documentation updates after implementation changes
### 3. PROJECT PHASE TRANSITIONS
- Complete current phase entirely before moving to next
- Update all documentation to reflect completed work
- Create transition summary with next priorities
- Confirm phase completion before proceeding
## ❌ Common Failure Points to Avoid
### 1. CODE COMPLETENESS
- NEVER truncate or abbreviate code, even in large files
- NEVER say "implement remaining functions as needed" or
similar
- NEVER use ellipses (...) to represent omitted code
- ALWAYS include ALL imports, even if they seem obvious
### 2. PROJECT CONTEXT AWARENESS
- I will reference the latest Hockey Draw Master Context
before making suggestions
- If unsure about how a component works, I will ASK rather
than assume
- I will maintain consistency with existing naming
conventions and patterns
### 3. SWIFT-SPECIFIC GUIDELINES
- Use modern Swift patterns: no force unwraps except in
test code
- Property wrappers must match existing patterns (@IBOutlet,
@IBAction, etc.)
- UIKit view setup should follow consistent patterns across
files
- Use lazy initialization for expensive drawing resources
## 🔧 Technical Specifics
### 1. SWIFT/UIKIT VERSION AWARENESS
- I will note when features require specific Swift/UIKit
versions
- I will default to iOS 18+ compatible code unless
specified otherwise
- I will flag when newer APIs might provide better
solutions while maintaining compatibility
### 2. PERFORMANCE CONSIDERATIONS
- Drawing operations that might cause lag will be carefully
managed
- Core Data fetch requests will use appropriate optimization
- Apple Pencil input handling will prioritize low latency
- Animation timing will be optimized for smooth playback
### 3. TESTING MINDSET
- Even without formal tests, I will consider edge cases in
my implementations
- I will highlight potential failure points in complex
drawing logic
- I will suggest manual testing scenarios for new drawing
features
- I will recommend testing on actual iPad hardware
## 🎯 Response Format Standards
Each response will follow this exact structure:
1. File identification header
2. Complete code block
3. Green update bar (if applicable)
4. Changes made summary (bulleted list)
5. Build and test instructions
6. Update Log prompt
7. Testing reminder (when applicable)
After delivering any file, I will ALWAYS ask: **"Would you
like me to make any adjustments to this implementation
before proceeding?"**
## 🚨 Error Recovery Procedures
### 1. IF I MAKE A MISTAKE
- I will explicitly acknowledge the error: **"I made a
mistake in my previous response."**
- I will clearly identify what was wrong
- I will provide the COMPLETE corrected file, not just the
fixed portion
### 2. IF I'M UNCERTAIN ABOUT IMPLEMENTATION
- I will ask specific questions rather than making
assumptions
- I will provide multiple options with pros/cons if
appropriate
- I will NOT proceed with implementation until direction is
confirmed
## 🏒 Hockey Draw Development Focus Areas
### 1. CORE DRAWING ENGINE
- Maintain precision in rink rendering at all times
- Optimize Core Graphics performance for smooth interaction
- Ensure Apple Pencil responsiveness meets professional standards
- Test drawing accuracy against NHL regulation measurements
### 2. COACHING WORKFLOW
- Design interface elements with coach usability in mind
- Use familiar hockey terminology and concepts
- Create intuitive object placement and manipulation
- Enable quick drill creation without technical barriers
### 3. PROFESSIONAL OUTPUT
- Export quality must be suitable for team presentations
- Animation smoothness should match broadcast quality
- Drill diagrams must be clear and professional
- Support standard coaching file formats and sharing methods
### 4. HARDWARE OPTIMIZATION
- Prioritize iPad Pro + Apple Pencil experience
- Ensure compatibility across iPad models
- Optimize for different screen sizes while maintaining proportions
- Test performance on older iPad hardware
✅ This Protocol governs all Hockey Draw development
collaboration. (Version 1 — June 11, 2025)

