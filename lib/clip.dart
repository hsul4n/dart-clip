export 'src/widgets/image_clip_field.dart';
export 'src/widgets/clip_grid_view.dart';
export 'src/widgets/gallery_page.dart';

import 'package:flutter/material.dart';

class Clip extends StatefulWidget {
  Clip({
    Key? key,
    required this.child,
    this.onChanged,
    this.onPause,
    this.onResume,
    this.onWillPop,
    AutovalidateMode? autovalidateMode,
    // add quality to add image quality for all clips
  })  : autovalidateMode = autovalidateMode ?? AutovalidateMode.disabled,
        super(key: key);

  static ClipState of(BuildContext context) {
    final _ClipScope scope =
        context.dependOnInheritedWidgetOfExactType<_ClipScope>()!;
    return scope._clipState;
  }

  final Widget child;

  final WillPopCallback? onWillPop;
  final VoidCallback? onChanged;
  final AutovalidateMode autovalidateMode;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  @override
  ClipState createState() => ClipState();
}

class ClipState extends State<Clip> {
  int _generation = 0;
  bool _hasInteractedByUser = false;
  final Set<ClipFieldState<dynamic>> _clips = <ClipFieldState<dynamic>>{};

  void _clipDidChange() {
    if (widget.onChanged != null) widget.onChanged!();
    _hasInteractedByUser =
        _clips.any((ClipFieldState<dynamic> clip) => clip._hasInteractedByUser);
    _forceRebuild();
  }

  void _forceRebuild() {
    setState(() {
      ++_generation;
    });
  }

  void _register(ClipFieldState<dynamic> clip) {
    _clips.add(clip);
  }

  void _unregister(ClipFieldState<dynamic> clip) {
    _clips.remove(clip);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.autovalidateMode) {
      case AutovalidateMode.always:
        _validate();
        break;
      case AutovalidateMode.onUserInteraction:
        if (_hasInteractedByUser) {
          _validate();
        }
        break;
      case AutovalidateMode.disabled:
        break;
    }

    return WillPopScope(
      onWillPop: widget.onWillPop,
      child: _ClipScope(
        clipState: this,
        generation: _generation,
        child: widget.child,
      ),
    );
  }

  void save() {
    for (final ClipFieldState<dynamic> clip in _clips) clip.save();
  }

  void reset() {
    for (final ClipFieldState<dynamic> clip in _clips) clip.reset();
    _hasInteractedByUser = false;
    _clipDidChange();
  }

  bool validate() {
    _hasInteractedByUser = true;
    _forceRebuild();
    return _validate();
  }

  bool _validate() {
    bool hasError = false;
    for (final ClipFieldState<dynamic> clip in _clips)
      hasError = !clip.validate() || hasError;
    return !hasError;
  }
}

class _ClipScope extends InheritedWidget {
  const _ClipScope({
    Key? key,
    required Widget child,
    required ClipState clipState,
    required int generation,
  })  : _clipState = clipState,
        _generation = generation,
        super(key: key, child: child);

  final ClipState _clipState;

  final int _generation;

  Clip get clip => _clipState.widget;

  @override
  bool updateShouldNotify(_ClipScope old) => _generation != old._generation;
}

typedef ClipFieldValidator<T> = String? Function(T? value);

typedef ClipFieldSetter<T> = void Function(T? newValue);

typedef ClipFieldBuilder<T> = Widget Function(ClipFieldState<T> clip);

class ClipField<T> extends StatefulWidget {
  const ClipField({
    Key? key,
    required this.builder,
    this.onSaved,
    this.validator,
    this.initialValue,
    AutovalidateMode? autovalidateMode,
    this.enabled = true,
  })  : autovalidateMode = autovalidateMode ?? AutovalidateMode.disabled,
        super(key: key);

  final bool enabled;

  final AutovalidateMode autovalidateMode;

  final ClipFieldValidator<T?>? validator;

  final ClipFieldSetter<T?>? onSaved;

  final ClipFieldBuilder<T> builder;

  final Future<T?> Function()? initialValue;

  @override
  ClipFieldState<T> createState() => ClipFieldState<T>();
}

/// The current state of a [ClipField]. Passed to the [ClipFieldBuilder] method
/// for use in constructing the clip clip's widget.
class ClipFieldState<T> extends State<ClipField<T>> {
  T? _value;
  String? _errorText;
  bool _hasInteractedByUser = false;

  /// The current value of the form field.
  T? get value => _value;

  String get errorText => _errorText!;

  bool get hasError => _errorText != null;

  bool get isValid => widget.validator?.call(_value) == null;

  void save() {
    if (widget.onSaved != null) widget.onSaved!(value);
  }

  void reset() {
    if (widget.initialValue != null) {
      widget.initialValue!().then((initialValue) {
        _value = initialValue;
        _hasInteractedByUser = false;
        _errorText = null;
      }).whenComplete(() {
        Clip.of(context)._clipDidChange();
      });
    } else {
      _hasInteractedByUser = false;
      _errorText = null;

      Clip.of(context)._clipDidChange();
    }
  }

  bool validate() {
    setState(() {
      _validate();
    });
    return !hasError;
  }

  void _validate() {
    if (widget.validator != null) _errorText = widget.validator!(_value);
  }

  void didChange(T? value) {
    setState(() {
      _value = value;
    });
    Clip.of(context)._clipDidChange();
  }

  void onPause() {
    if (Clip.of(context).widget.onPause != null) {
      Clip.of(context).widget.onPause!.call();
    }
  }

  void onResume() {
    if (Clip.of(context).widget.onResume != null) {
      Clip.of(context).widget.onResume!.call();
    }
  }

  @protected
  set value(T? value) {
    _value = value;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(reset);
  }

  @override
  void deactivate() {
    Clip.of(context)._unregister(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      switch (widget.autovalidateMode) {
        case AutovalidateMode.always:
          _validate();
          break;
        case AutovalidateMode.onUserInteraction:
          if (_hasInteractedByUser) {
            _validate();
          }
          break;
        case AutovalidateMode.disabled:
          break;
      }
    }

    Clip.of(context)._register(this);
    return widget.builder(this);
  }
}
