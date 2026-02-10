# SwiftUI Components — Quick Reference

## View Structure

```swift
import SwiftUI

struct ContentView: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            HeaderView()
            ContentSection(isExpanded: $isExpanded)
            Spacer()
        }
        .padding()
    }
}
```

## Layout

```swift
// VStack with alignment
VStack(alignment: .leading, spacing: 12) {
    Text("Title").font(.headline)
    Text("Subtitle").font(.subheadline)
}

// HStack with spacer
HStack {
    Image(systemName: "star")
    Text("Label")
    Spacer()
    Text("Value")
}

// ZStack for overlays
ZStack(alignment: .bottomTrailing) {
    Image("background")
    Badge()
        .padding()
}

// Grid
LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
```

## Modifiers

```swift
Text("Hello")
    .font(.title)
    .foregroundStyle(.primary)
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(radius: 4)
```

## Animations

```swift
// Implicit animation
withAnimation(.spring(duration: 0.3)) {
    isExpanded.toggle()
}

// Explicit animation
Circle()
    .scaleEffect(isAnimating ? 1.5 : 1.0)
    .animation(.easeInOut(duration: 0.5), value: isAnimating)

// Phase animator (iOS 17+)
Circle()
    .phaseAnimator([false, true]) { content, phase in
        content
            .scaleEffect(phase ? 1.2 : 1.0)
            .opacity(phase ? 0.5 : 1.0)
    }
```

## Gestures

```swift
// Tap
Button {
    // action
} label: {
    Text("Tap me")
}

// Long press
Text("Hold")
    .onLongPressGesture {
        // action
    }

// Drag
@GestureState private var dragOffset = CGSize.zero

Circle()
    .offset(dragOffset)
    .gesture(
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
    )
```

## Lists

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
    .onDelete(perform: delete)
    .onMove(perform: move)
}
.listStyle(.insetGrouped)

// Lazy loading
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(items) { item in
            ItemRow(item: item)
                .equatable()
        }
    }
}
```

## Navigation

```swift
// NavigationStack (iOS 16+)
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
    .navigationTitle("Items")
}

// Sheet
.sheet(isPresented: $showSheet) {
    SheetContent()
}

// Full screen cover
.fullScreenCover(isPresented: $showFullScreen) {
    FullScreenContent()
}
```

## Colors & Styling

```swift
// Semantic colors
Color.primary
Color.secondary
Color.accentColor

// Custom colors
extension Color {
    static let brand = Color("BrandColor")
    static let breatheBlue = Color(red: 0.4, green: 0.7, blue: 1.0)
}

// Gradients
LinearGradient(
    colors: [.blue, .purple],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

RadialGradient(
    colors: [.white.opacity(0.8), .clear],
    center: .center,
    startRadius: 0,
    endRadius: 100
)
```

## Safe Area

```swift
VStack {
    Content()
}
.ignoresSafeArea(.keyboard)
.safeAreaInset(edge: .bottom) {
    BottomBar()
}
```

## Accessibility

```swift
Image(systemName: "star")
    .accessibilityLabel("Favorite")
    .accessibilityHint("Double tap to add to favorites")
    .accessibilityAddTraits(.isButton)

// Hide from accessibility
Spacer()
    .accessibilityHidden(true)
```

## Performance

```swift
// Equatable for selective updates
struct ItemRow: View, Equatable {
    let item: Item

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item.id == rhs.item.id
    }

    var body: some View {
        // ...
    }
}

// Drawing group for complex views
ComplexShape()
    .drawingGroup()
```
