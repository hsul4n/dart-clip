part of 'widgets/image_clip_field.dart';

class _ClipLocalizations {
  _ClipLocalizations(this._locale);

  final Locale _locale;

  static _ClipLocalizations of(BuildContext context) {
    return Localizations.of<_ClipLocalizations>(context, _ClipLocalizations);
  }

  static Map<String, dynamic> _localizedValues = {
    'en': {
      'gallery': 'Gallery',
      'camera': 'Camera',
      'zoom': 'Zoom',
      'remove': 'Remove',
    },
    'ar': {
      'gallery': 'المعرض',
      'camera': 'الكاميرا',
      'zoom': 'تكبير',
      'remove': 'ازالة',
    },
  };

  String operator [](String key) => _localizedValues[_locale.languageCode][key];
}

class ClipLocalizationsDelegate
    extends LocalizationsDelegate<_ClipLocalizations> {
  const ClipLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode) ?? 'en';

  @override
  Future<_ClipLocalizations> load(Locale locale) {
    return SynchronousFuture<_ClipLocalizations>(_ClipLocalizations(locale));
  }

  @override
  bool shouldReload(ClipLocalizationsDelegate old) => false;
}
