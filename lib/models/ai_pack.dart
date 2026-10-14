import 'package:flutter/material.dart';

/// One AI-forged artwork inside a pack.
@immutable
class AiArtwork {
  /// Stable id, e.g. 'abyssal-leviathan'.
  final String id;

  /// Display title, e.g. 'Abyssal Leviathan'.
  final String title;

  /// One-line description of the piece.
  final String blurb;

  /// Flutter asset path of the PNG.
  final String assetPath;

  const AiArtwork({
    required this.id,
    required this.title,
    required this.blurb,
    required this.assetPath,
  });
}

/// A themed drop of AI-generated pixel art.
@immutable
class AiPack {
  /// Stable id, e.g. 'abyssal-bosses'.
  final String id;

  /// Display title, e.g. 'Abyssal Bosses'.
  final String title;

  /// Short tagline shown on cards.
  final String tagline;

  /// Longer description shown on the pack page.
  final String description;

  final List<AiArtwork> artworks;

  const AiPack({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.artworks,
  });
}
