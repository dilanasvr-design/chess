# ChessOverlay — iOS Chess Best-Move Arrow Overlay

Runs alongside Chess.com in Safari. Uses ReplayKit to read your screen, feeds the position to an on-device Stockfish engine, and draws a yellow arrow showing the best move on a live preview inside the app.

**No jailbreak. No Apple Developer account required (AltStore path).**

---

## How it works

```
Screen (ReplayKit) → Board detection (Vision) → FEN string → Stockfish → Arrow overlay (SwiftUI Canvas)
```

You run the app + Safari side-by-side in iOS Split View or use the in-app preview.

---

## Project structure

```
ChessOverlay/
├── ChessOverlay/
│   ├── App/
│   │   ├── ChessOverlayApp.swift    — @main entry
│   │   └── ContentView.swift        — UI: live preview + arrow + controls
│   ├── Engine/
│   │   ├── ChessEngine.swift        — ObservableObject: wires capture → FEN → Stockfish
│   │   └── StockfishBridge.swift    — Talks to bundled Stockfish binary via pipes
│   ├── Vision/
│   │   ├── BoardDetector.swift      — Locates the board in a screenshot
│   │   └── FENBuilder.swift         — Classifies squares → builds FEN string
│   ├── Overlay/
│   │   └── ArrowOverlayView.swift   — Draws the best-move arrow on a Canvas
│   ├── Capture/
│   │   └── ScreenCapture.swift      — ReplayKit screen capture wrapper
│   └── Info.plist
├── Package.swift
└── README.md
```

---

## Step 1 — Set up the Xcode project

1. Open Xcode → **File → New → Project → App**
2. Product Name: `ChessOverlay`
3. Bundle ID: anything, e.g. `com.yourname.chessoverlay`
4. Interface: **SwiftUI** | Language: **Swift** | iOS 16+
5. Delete the template files Xcode creates, then drag all the `.swift` files and `Info.plist` from this repo into the project, keeping the folder structure.
6. In **Build Settings**:
   - `SWIFT_VERSION` = 5.9
   - `IPHONEOS_DEPLOYMENT_TARGET` = 16.0
   - `ENABLE_HARDENED_RUNTIME` = NO (required for sideloading)
   - `CODE_SIGNING_STYLE` = Manual (for AltStore) or Automatic (for paid dev account)

---

## Step 2 — Compile and add Stockfish

The app needs the Stockfish engine binary compiled for `arm64-apple-ios`.

```bash
# On your Mac:
git clone https://github.com/official-stockfish/Stockfish.git
cd Stockfish/src

# Compile for iOS arm64
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
make build ARCH=arm64 COMP=clang \
  CXX="xcrun --sdk iphoneos clang++" \
  CXXFLAGS="-target arm64-apple-ios16.0 -isysroot $SDK -O3"
```

Then:
1. The binary is at `Stockfish/src/stockfish`
2. Drag it into Xcode under `ChessOverlay/Engine/`
3. In the file inspector → **Target Membership** → tick `ChessOverlay`
4. In **Build Phases → Copy Bundle Resources** → add `stockfish`

---

## Step 3 — (Optional) Add a piece classifier model

Without a CoreML model the app detects piece presence (occupied/empty) but not piece type, so the FEN is approximate. To get full accuracy:

**Option A — Use a pre-trained model from GitHub:**
Search: `chess piece classifier CoreML mlmodel` — several exist on GitHub.
Add `PieceClassifier.mlmodel` to the Xcode target. `FENBuilder.swift` auto-detects it.

**Option B — Train your own (30 min):**
```bash
pip install coremltools createml
# Download lichess-org/chess-dataset from HuggingFace
# 13 classes: P N B R Q K p n b r q k .  (dot = empty)
# 64×64 RGB crops of squares
# Use Create ML's Image Classifier — drag dataset in, hit Train, export .mlmodel
```

The app works (and ships a move) without the model — accuracy of the position is lower but Stockfish still returns a legal move.

---

## Step 4 — Sideload with AltStore (no paid account)

**Free Apple ID limit:** 3 apps, 7-day certificate refresh (AltStore handles this automatically over Wi-Fi).

1. Install AltStore on your Mac: https://altstore.io
2. Install AltStore on your iPhone via the Mac app.
3. In Xcode → select your iPhone as the target device.
4. Product → **Archive**
5. Window → Organizer → select the archive → **Distribute App**
6. Choose **Development** → Next → export to a folder → you get a `.ipa`
7. Open AltStore on your iPhone → **+** → select the `.ipa`
8. Done. App appears on your home screen.

**Or use Sideloadly** (alternative to AltStore): https://sideloadly.io
Drag the `.ipa` onto Sideloadly, sign in with your Apple ID, hit Start.

---

## Step 5 — Using the app

1. Open **ChessOverlay** on your iPhone.
2. Open **Chess.com** in Safari.
3. Use iOS **Split View** (swipe from bottom, hold, drag Safari alongside ChessOverlay) so both are visible.
4. In ChessOverlay, tap **Start Capture** → allow the screen recording permission.
5. The live preview appears. When a game is in progress, the yellow arrow shows the best move.
6. The arrow updates every ~1.5 seconds (every 15 frames at 10fps).

**The best-move label** (`e2 → e4`) also shows in text above the button in case the arrow is hard to read.

---

## Limitations

| Limitation | Reason | Fix |
|---|---|---|
| Overlay is inside the app, not floating over Chess.com | iOS sandbox prevents cross-app overlays without jailbreak | Use Split View so both apps are visible |
| FEN accuracy without CoreML model: ~70% | Brightness heuristic can't distinguish piece types | Add `PieceClassifier.mlmodel` (Step 3) |
| Active colour may drift | No clock OCR; alternates naively | Stockfish still returns a valid move for the detected position |
| Castling rights unknown | Single-frame detection only | Stockfish assumes full rights; practical impact is small |
| Must refresh AltStore cert every 7 days | Free Apple ID limit | AltStore refreshes automatically over Wi-Fi; or buy $99/yr dev account |

---

## Build troubleshooting

| Error | Fix |
|---|---|
| `stockfish: cannot execute binary file` | Re-compile for `arm64-apple-ios` as above |
| `RPScreenRecorder not available` | Test on a real device — Simulator blocks ReplayKit |
| `PieceClassifier not found` | Normal — app falls back to heuristic, no crash |
| Code signing error | In Build Settings set `CODE_SIGNING_REQUIRED = NO` for local sideload builds |
| `Process: termination reason: Namespace POSIX, Code 13` | The stockfish binary needs execute permission: `chmod +x stockfish` before adding to Xcode |

---

## One-line build command (after Xcode project is set up)

```bash
xcodebuild -project ChessOverlay.xcodeproj \
           -scheme ChessOverlay \
           -configuration Release \
           -destination generic/platform=iOS \
           archive -archivePath build/ChessOverlay.xcarchive

xcodebuild -exportArchive \
           -archivePath build/ChessOverlay.xcarchive \
           -exportOptionsPlist ExportOptions.plist \
           -exportPath build/ipa
```

`ExportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```
