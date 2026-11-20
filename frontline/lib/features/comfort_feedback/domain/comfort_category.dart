/// Screen 46 (Comfort Feedback) one-touch categories.
enum ComfortCategory {
  tooHot,
  tooCold,
  noise,
  airQuality,
  lighting,
  cleanliness,
  other;

  String get label => switch (this) {
        ComfortCategory.tooHot => 'Too hot',
        ComfortCategory.tooCold => 'Too cold',
        ComfortCategory.noise => 'Noise',
        ComfortCategory.airQuality => 'Air quality',
        ComfortCategory.lighting => 'Lighting',
        ComfortCategory.cleanliness => 'Cleanliness',
        ComfortCategory.other => 'Other',
      };
}
