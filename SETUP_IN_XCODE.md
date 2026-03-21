# Setup in Xcode (iOS 17+)

Project is already generated:
- `LetterDemo.xcodeproj`
- deployment target: iOS 17.0
- bundle id default: `com.demo.paperletter`

## 1) Open project

Open `LetterDemo.xcodeproj` in Xcode.

## 2) Configure signing

In Xcode:
1. Select target `LetterDemo`
2. Open `Signing & Capabilities`
3. Enable `Automatically manage signing`
4. Select your Apple Team
5. If needed, change Bundle Identifier to a unique value (for example `com.yourname.paperletterdemo`)

## 3) Run on iPhone

1. Connect iPhone (cable or same Wi-Fi)
2. Select your iPhone as Run Destination
3. Press Run
4. If iOS asks for trust confirmation:
   - Settings -> General -> VPN & Device Management
   - Trust your developer certificate
   - Run again

## 4) Smoke check

After launch:
1. Type text on the compose screen
2. Tap save (yellow check button)
3. Verify transition to paper state
4. Tap `Свернуть` and `Развернуть`

This repo intentionally keeps architecture simple for animation prototyping.
