import {Easing, interpolate, useCurrentFrame} from 'remotion';
import {INK, INK_2} from './OgVideo';

// Fuel Gauge's Claude Code 5-hour card: usage climbs to 55%, the forecast line reaches 100% before the reset,
// the verdict lands, then the window resets back to where frame 0 starts, so the loop has no seam.
const W = 372;
const H = 150;
const NOW = 0.38;
const OUT = 0.7;
const STEP = NOW / 7;
const y = (pct: number) => H - 4 - (pct / 100) * (H - 14);
const usage = (x: number) => 8 + 47 * Math.pow(x / NOW, 1.15);
const stepped = (x: number) => usage(Math.floor(x / STEP + 1e-6) * STEP);

export const ForecastCard = ({accentInk, accentFill}: {accentInk: string; accentFill: string}) => {
  const frame = useCurrentFrame();
  const ease = Easing.inOut(Easing.cubic);
  const grow = interpolate(frame, [6, 66, 130, 150], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease});
  const proj = interpolate(frame, [62, 86], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic)});
  const verdictIn = interpolate(frame, [80, 98], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic)});
  const fadeOut = interpolate(frame, [118, 130], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const shown = verdictIn * fadeOut;

  const xNow = interpolate(grow, [0, 1], [STEP * 1.5, NOW]);
  const pct = stepped(xNow);
  let d = `M0 ${y(stepped(0))}`;
  for (let x = STEP; x <= xNow + 1e-6; x += STEP) d += ` H${x * W} V${y(stepped(x))}`;
  d += ` H${xNow * W}`;
  const area = `${d} V${H - 4} H0 Z`;
  const projX = NOW + (OUT - NOW) * proj;
  const projY = 55 + 45 * proj;

  return (
    <div
      style={{width: '100%', height: '100%', boxSizing: 'border-box', padding: '30px 32px', borderRadius: 30, background: 'rgba(251,251,253,0.9)',
        boxShadow: '0 0 0 1px rgba(0,0,0,0.06), 0 2px 6px rgba(0,0,0,0.05), 0 16px 36px rgba(55,30,15,0.12)', fontVariantNumeric: 'tabular-nums'}}
    >
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
        <div>
          <div style={{fontSize: 28, fontWeight: 600, letterSpacing: '-0.02em', color: INK}}>Claude Code</div>
          <div style={{fontSize: 22, color: INK_2, marginTop: 2}}>5-hour limit</div>
        </div>
        <div style={{fontSize: 54, fontWeight: 700, letterSpacing: '-0.04em', color: accentInk, lineHeight: 1}}>{Math.round(pct)}%</div>
      </div>
      <div style={{position: 'relative', height: 10, borderRadius: 5, background: 'rgba(0,0,0,0.08)', margin: '18px 0 20px', overflow: 'hidden'}}>
        <div style={{position: 'absolute', inset: 0, width: `${pct}%`, borderRadius: 5, background: accentFill}} />
      </div>
      <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} style={{display: 'block', overflow: 'visible'}}>
        <line x1={0} y1={y(100)} x2={W} y2={y(100)} stroke="#8e8e93" strokeWidth={2} strokeDasharray="3 5" opacity={0.6} />
        <line x1={0} y1={H - 4} x2={W} y2={H - 4} stroke="rgba(0,0,0,0.12)" strokeWidth={2} />
        <line x1={W} y1={y(100) - 6} x2={W} y2={H - 4} stroke="#6e6e73" strokeWidth={2} strokeDasharray="4 5" />
        <path d={area} fill={accentFill} opacity={0.14} />
        <path d={d} fill="none" stroke={accentFill} strokeWidth={4} strokeLinejoin="round" />
        <g opacity={fadeOut}>
          {proj > 0 && <path d={`M${NOW * W} ${y(55)} L${projX * W} ${y(projY)}`} fill="none" stroke={accentFill} strokeWidth={4} strokeDasharray="7 8" strokeLinecap="round" />}
          <line x1={OUT * W} y1={y(100)} x2={OUT * W} y2={H - 4} stroke={accentInk} strokeWidth={2} strokeDasharray="4 5" opacity={verdictIn * 0.7} />
          {verdictIn > 0 && <circle cx={OUT * W} cy={y(100)} r={9 * verdictIn} fill={accentInk} stroke="#fff" strokeWidth={3} />}
        </g>
        <circle cx={xNow * W} cy={y(pct)} r={7} fill={accentFill} stroke="#fff" strokeWidth={3} />
      </svg>
      <div style={{position: 'relative', height: 28, marginTop: 8, fontSize: 20, color: INK_2, whiteSpace: 'nowrap'}}>
        <span style={{position: 'absolute', left: 0}}>8:20a</span>
        <span style={{position: 'absolute', right: 0}}>Reset 1:20p</span>
      </div>
      <div style={{position: 'absolute', marginTop: 18, fontSize: 30, fontWeight: 600, letterSpacing: '-0.02em', color: '#8e8e93', opacity: 1 - shown}}>
        Watching your pace…
      </div>
      <div style={{marginTop: 18, opacity: shown, transform: `translateY(${(1 - verdictIn) * 14}px)`}}>
        <div style={{fontSize: 38, fontWeight: 700, letterSpacing: '-0.03em', color: accentInk}}>Runs out ~11:50a</div>
        <div style={{fontSize: 22, color: INK_2, marginTop: 4}}>1h 30m before it resets</div>
      </div>
    </div>
  );
};
