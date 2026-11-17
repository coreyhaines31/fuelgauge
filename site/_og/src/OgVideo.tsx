import {loadFont as loadBarlow} from '@remotion/google-fonts/Barlow';
import {loadFont as loadCondensed} from '@remotion/google-fonts/BarlowSemiCondensed';
import {AbsoluteFill, Img, staticFile} from 'remotion';
import {ForecastCard} from './ForecastCard';

// The Brushed family type: Barlow Semi Condensed for display and plates, Barlow for body.
loadBarlow('normal', {weights: ['500', '600'], subsets: ['latin']});
loadCondensed('normal', {weights: ['300', '600', '700'], subsets: ['latin']});

export type OgVideoProps = {
  name: string;
  icon: string;
  badge: string;
  headline: string;
  headlineLight: string;
  sub: string;
  accent: string;
};

export const DISPLAY = '"Barlow Semi Condensed", "Helvetica Neue", sans-serif';
export const BODY = 'Barlow, "Helvetica Neue", sans-serif';
export const INK = '#161616';
export const INK_2 = '#3d3f41';
export const MUTED = '#5b5d5e';
// Status lights, reserved for readings
export const CAUTION = '#d9921a';
export const STOP = '#e0452b';

const BRUSH = [
  'repeating-linear-gradient(0deg, rgba(255,255,255,.22) 0 1px, rgba(0,0,0,.035) 1px 2px, transparent 2px 3px)',
  'repeating-linear-gradient(0deg, rgba(0,0,0,.035) 0 1px, transparent 1px 7px)',
  'linear-gradient(100deg, rgba(255,255,255,0) 18%, rgba(255,255,255,.5) 40%, rgba(255,255,255,0) 64%)',
  'linear-gradient(180deg, #e7e8e9, #c3c5c7)',
].join(', ');

const Screw = ({style}: {style: React.CSSProperties}) => (
  <div style={{position: 'absolute', width: 12, height: 12, borderRadius: '50%', background: 'radial-gradient(circle at 40% 35%, #fff, #b9bbbd 45%, #77797b 80%)', ...style}} />
);

// The family shell: a brushed aluminium plate, brand and headline on the left, the instrument mounted on the right.
// The accent appears only as the badge's pilot light.
export const OgVideo = (props: OgVideoProps) => (
  <AbsoluteFill style={{background: BRUSH, color: INK, fontFamily: BODY, WebkitFontSmoothing: 'antialiased'}}>
    <Screw style={{left: 16, top: 16}} />
    <Screw style={{right: 16, top: 16}} />
    <Screw style={{left: 16, bottom: 16}} />
    <Screw style={{right: 16, bottom: 16}} />
    <div style={{position: 'absolute', left: 76, top: 72, width: 560, height: 486, display: 'flex', flexDirection: 'column', justifyContent: 'space-between'}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 18, fontFamily: DISPLAY, fontSize: 36, fontWeight: 700}}>
        <Img src={staticFile(props.icon)} style={{width: 76, height: 76}} />
        {props.name}
      </div>
      <div>
        <div
          style={{display: 'inline-flex', gap: 12, alignItems: 'center', fontFamily: DISPLAY, fontSize: 18, fontWeight: 600, letterSpacing: '0.26em',
            textTransform: 'uppercase', background: '#1b1b1b', color: '#d8d9da', padding: '9px 14px 9px 12px', borderRadius: 3}}
        >
          <span style={{width: 10, height: 10, borderRadius: '50%', background: props.accent, boxShadow: `0 0 8px ${props.accent}`}} />
          {props.badge}
        </div>
        <div style={{fontFamily: DISPLAY, fontSize: 84, lineHeight: 0.98, fontWeight: 600, marginTop: 22}}>
          {props.headline} <span style={{fontWeight: 300, whiteSpace: 'nowrap'}}>{props.headlineLight}</span>
        </div>
      </div>
      <div style={{fontSize: 26, fontWeight: 500, color: INK_2}}>{props.sub}</div>
    </div>
    <div
      style={{position: 'absolute', left: 664, top: 72, width: 460, height: 486, borderRadius: 14, background: '#1b1b1b', padding: 22,
        backgroundImage: 'radial-gradient(rgba(255,255,255,.045) 1px, transparent 1.3px)', backgroundSize: '5px 5px', boxShadow: '0 0 0 1px rgba(0,0,0,.5)'}}
    >
      <ForecastCard />
    </div>
  </AbsoluteFill>
);
