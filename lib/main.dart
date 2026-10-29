name: Build Heedar TV (OwnTV Engine)

on:
  push:
    branches: [ "main", "master" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v4
        with:
          packages: 'platform-tools'

      - name: Clone OwnTV & Rebrand to Heedar TV
        run: |
          git clone --depth 1 https://github.com/ahXN00/OwnTV.git app_src
          cd app_src

          # تغيير اسم التطبيق في جميع ملفات النصوص إلى Heedar TV
          find app/src/main/res/ -name "strings.xml" -exec sed -i 's/>OwnTV</>Heedar TV</g' {} +
          sed -i 's/OwnTV/Heedar TV/g' app/src/main/AndroidManifest.xml

          chmod +x ./gradlew
          ./gradlew assembleStandardDebug --no-daemon

      - name: Upload Heedar TV APK
        uses: actions/upload-artifact@v4
        with:
          name: HeedarTV-OwnTV-Edition
          path: app_src/app/build/outputs/apk/standard/debug/*.apk
