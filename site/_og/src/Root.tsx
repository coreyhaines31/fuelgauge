import {Composition} from 'remotion';
import {OgVideo, type OgVideoProps} from './OgVideo';

// 5 s at 30 fps. Frame 112 is the resting frame, rendered as the og:image still.
export const RemotionRoot = () => (
  <Composition
    id="OgVideo"
    component={OgVideo}
    durationInFrames={150}
    fps={30}
    width={1200}
    height={630}
    defaultProps={
      {
        name: 'Fuel Gauge',
        icon: 'icon.svg',
        headline: "Know if you'll make it",
        headlineAccent: 'to reset.',
        sub: 'Free for macOS · fuelgauge.app',
        accent: '#e8670c',
        accentInk: '#b84c06',
        accentFill: '#f2761c',
        field: ['#ffc98a', '#ffe3a3', '#c9e6ff', '#ffd3c4'],
      } satisfies OgVideoProps
    }
  />
);
