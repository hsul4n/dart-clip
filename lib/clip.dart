export 'src/widgets/image_clip_field.dart';

import 'package:flutter/material.dart';

class Clip extends StatefulWidget {
  const Clip({
    Key key,
    @required this.child,
    this.onChanged,

    /// prefix filename sush as MY_APP_1234567
    String prefix,

    /// directory for images in gallery
    String directory,
    bool lazy,
    this.onPause,
    this.onResume,
    // add quality to add image quality for all clips
  })  : assert(child != null),
        super(key: key);

  static ClipState of(BuildContext context) {
    final _ClipScope scope =
        context.dependOnInheritedWidgetOfExactType<_ClipScope>();
    return scope?._clipState;
  }

  final Widget child;

  final VoidCallback onChanged;

  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  ClipState createState() => ClipState();
}

class ClipState extends State<Clip> {
  int _generation = 0;
  final Set<ClipFieldState<dynamic>> _clips = <ClipFieldState<dynamic>>{};

  void _clipDidChange() {
    if (widget.onChanged != null) widget.onChanged();
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
    return _ClipScope(
      clipState: this,
      generation: _generation,
      child: widget.child,
    );
  }

  void save() {
    for (final ClipFieldState<dynamic> clip in _clips) clip.save();
  }

  void reset() {
    for (final ClipFieldState<dynamic> clip in _clips) clip.reset();
    _clipDidChange();
  }
}

class _ClipScope extends InheritedWidget {
  const _ClipScope({
    Key key,
    Widget child,
    ClipState clipState,
    int generation,
  })  : _clipState = clipState,
        _generation = generation,
        super(key: key, child: child);

  final ClipState _clipState;

  final int _generation;

  Clip get clip => _clipState.widget;

  @override
  bool updateShouldNotify(_ClipScope old) => _generation != old._generation;
}

typedef ClipFieldValidator<T> = String Function(T value);

typedef ClipFieldSetter<T> = void Function(T newValue);

typedef ClipFieldBuilder<T> = Widget Function(ClipFieldState<T> clip);

class ClipField<T> extends StatefulWidget {
  const ClipField({
    Key key,
    @required this.builder,
    this.onSaved,
    this.initialValue,
  })  : assert(builder != null),
        super(key: key);

  final ClipFieldSetter<T> onSaved;

  final ClipFieldBuilder<T> builder;

  final Future<T> Function() initialValue;

  @override
  ClipFieldState<T> createState() => ClipFieldState<T>();
}

/// The current state of a [ClipField]. Passed to the [ClipFieldBuilder] method
/// for use in constructing the clip clip's widget.
class ClipFieldState<T> extends State<ClipField<T>> {
  T _value;

  T get value => _value;

  void save() {
    widget?.onSaved(value);
  }

  void reset() {
    widget.initialValue().then((value) {
      _value = value;
    }).whenComplete(() => setState(() {}));
  }

  void didChange(T value) {
    setState(() {
      _value = value;
    });
    Clip.of(context)?._clipDidChange();
  }

  void onPause() {
    Clip.of(context)?.widget?.onPause?.call();
  }

  void onResume() {
    Clip.of(context)?.widget?.onResume?.call();
  }

  @protected
  set value(T value) {
    _value = value;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(reset);
  }

  @override
  void deactivate() {
    Clip.of(context)?._unregister(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Clip.of(context)?._register(this);
    return widget.builder(this);
  }
}
