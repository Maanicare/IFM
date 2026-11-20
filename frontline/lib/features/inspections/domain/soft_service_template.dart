/// Screen 23 (Soft Service Inspection) templates.
enum SoftServiceTemplate {
  housekeeping,
  pantry,
  pest,
  horticulture,
  mailroom,
  concierge;

  String get label => switch (this) {
        SoftServiceTemplate.housekeeping => 'Housekeeping',
        SoftServiceTemplate.pantry => 'Pantry',
        SoftServiceTemplate.pest => 'Pest',
        SoftServiceTemplate.horticulture => 'Horticulture',
        SoftServiceTemplate.mailroom => 'Mailroom',
        SoftServiceTemplate.concierge => 'Concierge',
      };
}
