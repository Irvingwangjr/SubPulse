# Design: Swipe-to-Delete Card Container (`SwipeToDeleteCard`)

- **ScrollView Conflict Avoidance**: Uses `.simultaneousGesture(DragGesture(minimumDistance: 14))` with a first-delta directional axis lock (`abs(dx) > abs(dy) * 1.25`). Vertical gestures immediately lock out horizontal handling so `ScrollView` stays 120Hz smooth.
- **Zero Corner Bleed**: The destructive red gradient button renders only when `offset < -2 || isDeleting`, matched to the card's `22pt` continuous corner radius.
- **Full-Swipe Elastic Stretch**: As `offset` passes `-168pt`, the red delete pill expands dynamically (`max(86, -offset - 10)`), scales up the trash icon, and fires a crisp `UIImpactFeedbackGenerator(style: .rigid)` pulse.
- **Tap Safety**: When open (`offset < -4`), a transparent tap overlay closes the swiped card instead of firing edit/renew actions beneath.
- **Mutual Exclusion**: `activeSwipeID: UUID?` ensures opening a second row springs the previously opened row smoothly closed.
