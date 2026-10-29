# Link preview video

Remotion source for `images/og.mp4` (the `og:video` iMessage and Discord autoplay) and `images/og-video.png` (the `og:image` still, frame 112 of the loop). Needs Node and ffmpeg.

```sh
cd site/_og && npm install && npm run render
```

`npm run studio` opens a live preview. `OgVideo.tsx` is the shared shell (color field, glass card, brand, headline) and takes its text and colors as props in `Root.tsx`; `ForecastCard.tsx` is the Fuel Gauge animation on the right. The loop ends on its first frame, so keep frame 0 and frame 149 identical when changing the timing.

This folder is in `.vercelignore`, so none of it is deployed.
