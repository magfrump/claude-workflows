# 3D Viewport Rendering Review

Reference for the `ui-visual-review` skill. Load this file when the diff or scope
includes 3D rendering content.

## Activation Triggers

Run this checklist when the diff or scope includes any of:

- TSX/JSX containing `three`, `@react-three/fiber`, `babylonjs` / `@babylonjs/core`,
  `<model-viewer>`, or a `<canvas>` paired with WebGL/WebGPU context creation
  (`getContext('webgl'|'webgl2'|'webgpu')`)
- Unity WebGL builds (e.g., `Build/UnityLoader.js`, `unityInstance`, a `#unity-canvas` host)
  or Unreal Pixel Streaming pages (`PixelStreaming` client, signaling-server URLs)
- `.glb` or `.gltf` URL references in code, configs, or asset manifests

3D viewports fail in ways that the 2D layout checklist does not catch. The model can be
loaded, the canvas can be sized correctly, and the page can still appear blank or wrong.
The checks below are mechanical pattern checks against the rendering setup; runtime
verification is strongly recommended for 3D content because static analysis cannot
predict whether the camera ends up framing the model.

## Checklist

### Camera controls (orbit/pan/zoom respond, no gimbal lock)

Verify the chosen controls module receives the actual canvas DOM element, not the window
or a wrapper div (`new OrbitControls(camera, canvas)` for three.js;
`scene.activeCamera.attachControl(canvas)` for Babylon). If the render loop uses
`requestAnimationFrame`, `controls.update()` must be called inside it for damped controls
to respond. Watch for orbit code that integrates Euler angles directly — at pitch ±90°
this hits gimbal lock and pan/zoom can stop working at certain orientations. Prefer
quaternion or spherical-coordinate orbit math; built-in `OrbitControls` already does this
correctly.

### Clipping plane behavior (near/far cull doesn't crop expected geometry)

Inspect `camera.near` and `camera.far`. Three.js defaults of `0.1` / `2000` (or Babylon's
`1` / `10000`) clip large architectural models from the back and tiny inspection models
from the front. After loading an asset, compute its bounding box and size the planes to
it (e.g., `near = bbox.diagonal * 0.001`, `far = bbox.diagonal * 100`). Symptom of a
too-tight far plane: the back of the model disappears as the camera dollies out. Symptom
of a too-loose near plane: small parts vanish when the camera gets close, or z-fighting
on coplanar faces from depth buffer precision loss.

### Lighting adequacy (subject not silhouetted on dark background)

A scene that uses only `MeshStandardMaterial` / `MeshPhysicalMaterial` (or Babylon's
`PBRMaterial`) with no lights renders as solid black. A dark subject on
`scene.background = black` renders as invisible. Verify at least one directional or
point light is added to the scene, or the material is explicitly unlit
(`MeshBasicMaterial`, `unlit` extension on glTF). Check contrast between the subject's
expected color range and `scene.background` / `renderer.setClearColor`. For HDR/IBL
setups, confirm the environment map actually loaded (loader errors are silent — the
scene just goes dark).

### Transparency and depth ordering

Translucent meshes need `material.transparent = true` and the renderer's
transparency-sort pass; opaque meshes should not have `transparent: true` (it disables
the depth-write fast path and causes flicker). Common bugs: a transparent UI plane
renders behind opaque scene geometry because of default `renderOrder`; cutout textures
(foliage, decals) show square outlines because `alphaTest` is missing — set
`material.alphaTest = 0.5` (or comparable) for binary cutouts. For order-dependent
effects (glass, particles), check `depthWrite` is `false` on the transparent layer and
`renderOrder` is set explicitly.

### Gizmo presence and orientation when relevant

When the viewport is an editor / debug view (transform gizmos, axis helpers, grid, bone
overlays, bounding-box wireframes), verify the helpers are added to the scene and are
oriented in the expected handedness (three.js: right-handed, X=red right, Y=green up,
Z=blue toward camera; Unity / Unreal: left-handed; glTF assets are right-handed Y-up).
A gizmo that draws but is occluded by the model usually wants `depthTest = false` and a
high `renderOrder` so it stays on top. If the user reports "I can see the model but
can't grab the handles," check whether the raycaster is being intersected with the
helpers layer (some setups exclude helpers from picking by default).

### Asset bounds vs. viewport (model not centered, larger than far-clip)

After load, compute the model's bounding box and verify (a) it is finite (a NaN or
zero-extent box means the loader returned an empty scene), (b) the camera's distance is
sized to it (`distance ≈ bbox.diagonal * 1.5` is a reasonable default), and (c) the
model is re-centered if the artist exported it offset from origin
(`model.position.sub(bbox.center)`). Without an explicit framing pass, models commonly
load off-camera (you see a black canvas but the model is rendering 50 units to the side)
or too small to see (camera at default `(0,0,5)`, model is 0.001 units across). Models
larger than `camera.far` will be culled entirely — relink to the clipping-plane check
above.

### Runtime perf indicators (FPS / draw calls when overlay is present)

When the project surfaces a perf overlay (`stats.js`, r3f's `<Perf />`, Babylon
Inspector, the Unity WebGL stats panel, Pixel Streaming's bitrate HUD), check that frame
time stays under the project's stated target (16.7ms for 60fps desktop; 33.3ms for 30fps
mobile) and that draw-call counts are not unexpectedly high — a model with N parts
emitting N draw calls signals missing instancing or mesh merging. Do not fail a review
purely because no perf overlay exists; flag missing instrumentation only when the
project's stated goals (e.g., real-time rendering, mobile target) make perf material.
When the overlay is visible in screenshots, include the FPS / draw-call values in the
runtime verification results table.

## Common Failure Modes

Common 3D-viewport failures that look like "the page is broken":

- **Black canvas** → no lights, or background and material both dark, or model off-camera
- **Single-color silhouette** → unlit material with default color, or environment map
  failed to load
- **Model "missing" but no console error** → camera near/far culls it, or model is
  smaller/larger than the camera's framing assumes
- **Controls dead** → controls attached to wrong DOM element, or `controls.update()`
  missing from the loop, or Euler-based orbit hit gimbal lock

## Screenshot Capture Note

When capturing screenshots for 3D viewport content during runtime verification, wait for
the scene to stabilize before capturing. Asset load is asynchronous, and the first frame
typically renders before the model is in the scene or before the camera-framing pass has
run — the screenshot will show a blank canvas that does not reflect the steady state.
Wait for a load-complete signal (`gltfLoader.load` callback, `<model-viewer load>` event,
or a configurable `await nextFrame()` after `scene.onReadyObservable`) and capture one or
two frames after that. For perf-overlay screenshots, let the FPS counter settle for ~2
seconds so the displayed value reflects steady-state cost, not first-frame compile/upload
spikes.
