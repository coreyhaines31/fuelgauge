import {Composition} from 'remotion';
import {OgVideo, type OgVideoProps} from './OgVideo';

// 6 s at 60 fps. Frame 225 (3.75 s) is the resting frame, rendered as the og:image still.
export const RemotionRoot = () => (
  <Composition
    id="OgVideo"
    component={OgVideo}
    durationInFrames={360}
    fps={60}
    width={1200}
    height={630}
    defaultProps={
      {
        name: 'Fuel Gauge',
        icon: 'icon.svg',
        badge: 'Free for macOS',
        headline: "Know if you'll make it",
        headlineLight: 'to reset.',
        sub: 'fuelgauge.app',
        accent: '#e06a1b',
      } satisfies OgVideoProps
    }
  />
);
