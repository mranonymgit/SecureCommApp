{{flutter_js}}
{{flutter_build_config}}

// Use CanvasKit with WebGL for responsive maps and dashboard interactions.
// Limiting overlay surfaces avoids unnecessary GPU compositing work.
_flutter.loader.load({
  config: {
    canvasKitMaximumSurfaces: 1,
  },
});
