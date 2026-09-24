# Upgrade request: pixelgrain 4.2.0 → 5.0.0

`pixelgrain` resizes uploaded photos into thumbnails. The 5.0 release notes
claim faster resizing, and our thumbnail queue backs up during evening peaks.
The team asks whether to take the major version.

## Manifest (package.json)

```json
{
  "name": "thumbnailer",
  "engines": { "node": ">=20" },
  "dependencies": {
    "pixelgrain": "^4.2.0"
  }
}
```

Runtime: `FROM node:22-slim` in the Dockerfile; CI uses the same image.

## How the project uses pixelgrain

These are all of the call sites.

`src/thumbs.js`

```js
const grain = require("pixelgrain");

async function makeThumb(inputPath, outputPath) {
  await grain.open(inputPath)
    .resize(320, 320, { fit: "cover" })
    .toFile(outputPath, { quality: 82 });
}

module.exports = { makeThumb };
```

`test/thumbs.test.js` resizes three fixture photos (JPEG, PNG, HEIC) and
compares the output dimensions and a perceptual hash against checked-in
thumbnails.

## Release notes (complete, 4.2.0 → 5.0.0)

### 5.0.0 (major)

- Performance: `resize()` uses a new SIMD path; 30-45% faster for JPEG and PNG
  input on x86-64 and arm64. Output is pixel-identical for the `cover` and
  `contain` fits.
- Breaking: removed `grain.stream()`. Pipe through `grain.open()` with a
  readable stream instead.
- Breaking: `composite(layers)` takes an array of `{ input, top, left }`
  objects; positional arguments are no longer accepted.
- Breaking: dropped support for Node.js 16 and 18. Node.js 20 or later is
  required.
- Breaking: the `grain.cache(false)` global switch is removed; caching is
  configured per pipeline with `open(path, { cache: false })`.

### 4.3.0

- HEIC decoding moved into the main package (previously an optional add-on,
  which 4.2 already bundled for Linux).
