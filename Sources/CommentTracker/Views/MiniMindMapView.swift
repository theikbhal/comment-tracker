import SwiftUI
import AppKit

private let mindMapCanvasWidth: CGFloat = 1800
private let mindMapCanvasHeight: CGFloat = 1200

struct MiniMindMapView: View {
    @EnvironmentObject var store: Store
    @State private var selectedMapID: Int?
    @State private var selectedNodeID: Int?
    @State private var editingNodeID: Int?
    @State private var editingText: String = ""
    @State private var renamingMap: MindMap?
    @State private var renamingText: String = ""

    private var selectedMap: MindMap? {
        guard let id = selectedMapID else { return nil }
        return store.mindMaps.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            mapPicker
            Divider()
            if let map = selectedMap {
                canvas(map)
            } else {
                emptyState
            }
        }
        .sheet(item: $renamingMap) { map in
            VStack(alignment: .leading, spacing: 12) {
                Text("Rename map")
                    .font(.headline)
                TextField("Map title", text: $renamingText)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { renamingMap = nil }
                        .keyboardShortcut(.cancelAction)
                    Button("Save") {
                        store.renameMindMap(id: map.id, title: renamingText)
                        renamingMap = nil
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .frame(width: 360, height: 150)
        }
        .onAppear {
            if selectedMapID == nil {
                selectedMapID = store.mindMaps.first?.id
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mini Mind Map")
                    .font(.title.bold())
                Text("\(store.mindMaps.count) maps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Button {
                let id = store.addMindMap()
                selectedMapID = id
            } label: {
                Label("New map", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .help("Create a new mind map")
        }
        .padding(16)
    }

    private var mapPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.mindMaps) { map in
                    chip(map)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .background(.background.secondary)
    }

    private func chip(_ map: MindMap) -> some View {
        let isSelected = map.id == selectedMapID
        return HStack(spacing: 6) {
            Text(map.title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
            if isSelected {
                Menu {
                    Button {
                        renamingText = map.title
                        renamingMap = map
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        store.deleteMindMap(map.id)
                        if selectedMapID == map.id {
                            selectedMapID = store.mindMaps.first?.id
                        }
                    } label: {
                        Label("Delete map", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isSelected ? Color.purple.opacity(0.18) : Color.clear, in: Capsule())
        .overlay(Capsule().stroke(isSelected ? Color.purple.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1))
        .contentShape(Capsule())
        .onTapGesture {
            selectedMapID = map.id
            selectedNodeID = nil
        }
    }

    private func canvas(_ map: MindMap) -> some View {
        let nodes = store.nodesForMap(map.id)
        return ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                connectorLayer(nodes)
                ForEach(nodes) { node in
                    nodeView(node, mapID: map.id)
                }
            }
            .frame(width: mindMapCanvasWidth, height: mindMapCanvasHeight)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private func connectorLayer(_ nodes: [MindMapNode]) -> some View {
        Canvas { context, _ in
            let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
            for node in nodes {
                guard let parentID = node.parentId, let parent = byID[parentID] else { continue }
                let start = CGPoint(x: parent.x, y: parent.y)
                let end = CGPoint(x: node.x, y: node.y)
                let midX = (start.x + end.x) / 2
                var path = Path()
                path.move(to: start)
                path.addQuadCurve(to: end, control: CGPoint(x: midX, y: start.y))
                context.stroke(path, with: .color(mindMapColor(node.color).opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }

    private func nodeView(_ node: MindMapNode, mapID: Int) -> some View {
        let color = mindMapColor(node.color)
        let isSelected = selectedNodeID == node.id
        return NodeCardView(
            node: node,
            isRoot: node.isRoot,
            color: color,
            isSelected: isSelected,
            onSelect: { selectedNodeID = node.id },
            onAddChild: { store.addMindMapNode(mapID: mapID, parentID: node.id) },
            onDelete: { store.deleteMindMapNode(node.id) },
            onColor: { store.updateMindMapNodeColor(node.id, color: $0) },
            onEdit: {
                editingText = node.text
                editingNodeID = node.id
            },
            onMove: { store.moveMindMapNode(node.id, x: $0, y: $1) }
        )
        .position(x: node.x, y: node.y)
        .zIndex(node.isRoot ? 2 : 1)
        .overlay(alignment: .topTrailing) {
            if editingNodeID == node.id {
                editPopover(node)
            }
        }
    }

    private func editPopover(_ node: MindMapNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Node text", text: $editingText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .onSubmit {
                    store.updateMindMapNodeText(node.id, text: editingText)
                    editingNodeID = nil
                }
            HStack(spacing: 6) {
                ForEach(mindMapColorNames, id: \.self) { name in
                    Button {
                        store.updateMindMapNodeColor(node.id, color: name)
                    } label: {
                        Circle()
                            .fill(mindMapColor(name))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.25), lineWidth: 1))
        .offset(x: -12, y: 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No maps yet — hit New map to start")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                let id = store.addMindMap()
                selectedMapID = id
            } label: {
                Label("Create a mind map", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NodeCardView: View {
    let node: MindMapNode
    let isRoot: Bool
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    let onAddChild: () -> Void
    let onDelete: () -> Void
    let onColor: (String) -> Void
    let onEdit: () -> Void
    let onMove: (Double, Double) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(node.text)
                .font(isRoot ? .headline : .subheadline)
                .fontWeight(isRoot ? .bold : .semibold)
                .lineLimit(isRoot ? 3 : 2)
                .multilineTextAlignment(.center)
                .frame(minWidth: isRoot ? 110 : 76, maxWidth: isRoot ? 180 : 150)
                .padding(.vertical, isRoot ? 10 : 6)
                .padding(.horizontal, isRoot ? 16 : 10)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: isRoot ? 14 : 10))
                .overlay(RoundedRectangle(cornerRadius: isRoot ? 14 : 10).stroke(color.opacity(isSelected ? 0.9 : 0.45), lineWidth: isSelected ? 2 : 1))
                .onTapGesture { onSelect() }
                .onTapGesture(count: 2) { onEdit() }
                .gesture(drag)
        }
        .padding(.horizontal, 4)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button { onAddChild() } label: { Label("Add child", systemImage: "plus.circle") }
            Divider()
            Menu {
                ForEach(mindMapColorNames, id: \.self) { name in
                    Button {
                        onColor(name)
                    } label: {
                        HStack {
                            Circle().fill(mindMapColor(name)).frame(width: 10, height: 10)
                            Text(name.capitalized)
                        }
                    }
                }
            } label: {
                Label("Color", systemImage: "paintpalette")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(node.isRoot ? "Clear map" : "Delete", systemImage: "trash")
            }
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let newX = node.x + value.translation.width
                let newY = node.y + value.translation.height
                let clampedX = min(mindMapCanvasWidth, max(0, newX))
                let clampedY = min(mindMapCanvasHeight, max(0, newY))
                onMove(clampedX, clampedY)
            }
    }
}
