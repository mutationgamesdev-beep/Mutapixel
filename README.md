# Sprite Builder

A mobile app for creating pixel-art character sprites and items. Built with
Flutter for iOS from day one (Android-ready too).

By **Mutation Games Development**.

## Features

- Pixel canvas with pencil, eraser and fill tools
- Mirror (symmetry) drawing mode
- Retro palettes (PICO-8, Game Boy, NES) plus custom colors
- Canvas sizes from 16x16 to 128x128
- Animation frames with live preview
- Starter templates (characters and items)
- Lossless PNG export at 1x, 2x, 4x and 8x
- Sprite-sheet export with anti-bleed gutter
- Save to gallery / files, share via the system share sheet

## Web demo

Every push to `main` builds and deploys the web version to GitHub Pages
via `.github/workflows/deploy.yml`.

## Development

```sh
flutter pub get
flutter run            # mobile / desktop
flutter build web      # web release in build/web
flutter test           # unit + widget tests
```

Bundle ID: `com.mutationgames.spritebuilder`
