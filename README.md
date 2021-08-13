# SvgTest
Run the react-native-svg examples and execute iOS/tvOS snapshot tests

```
git clone https://github.com/douglowder/SvgTest
cd SvgTest
yarn
cd ios
pod install
cd ..
# Run the app
react-native run-ios
# Run snapshot tests to verify initial screen of SVG components
yarn snapshot-test
```
