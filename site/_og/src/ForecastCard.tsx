import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {INK, INK_2} from './OgVideo';

// Fuel Gauge's Claude Code 5-hour card: usage climbs to 55%, the forecast line reaches 100% before the reset,
// the verdict lands, then the window drains back to where it starts, so the loop has no seam.
const W = 372;
const H = 150;
const NOW = 0.38;
const OUT = 0.7;
const STEP = NOW / 7;
const y = (pct: number) => H - 4 - (pct / 100) * (H - 14);
const usage = (x: number) => 8 + 47 * Math.pow(x / NOW, 1.15);
const smoothstep = (t: number) => {
  const c = Math.min(1, Math.max(0, t));
  return c * c * (3 - 2 * c);
};
// Mostly staircase with a little smooth curve mixed in: the line still reads as bursts of use, but the value never stalls, so the head glides.
const stairs = (x: number) => {
  const k = Math.floor(x / STEP + 1e-9);
  const lo = usage(k * STEP);
  const stepped = lo + (usage((k + 1) * STEP) - lo) * smoothstep((x / STEP - k - 0.6) / 0.4);
  return stepped * 0.75 + usage(x) * 0.25;
};

const STANDARD = Easing.bezier(0.4, 0, 0.2, 1);
const IN_OUT = Easing.bezier(0.65, 0, 0.35, 1);
const OUT_EASE = Easing.bezier(0, 0, 0.2, 1);

export const ForecastCard = ({accentInk, accentFill}: {accentInk: string; accentFill: string}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const ease = (input: number[], output: number[], easing: (n: number) => number) =>
    interpolate(t, input, output, {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing});

  // 0–2.2s climb · 1.9–2.8s forecast draws · 2.7–3.0s verdict in · hold to 4.5s · 4.5–4.8s verdict out · 4.6–5.8s drain
  const climb = ease([0, 2.2], [0, 1], STANDARD);
  const drain = ease([4.6, 5.8], [0, 1], IN_OUT);
  const grow = climb * (1 - drain);
  const proj = ease([1.9, 2.8], [0, 1], IN_OUT);
  // Text swaps overlap only briefly, so the two lines never sit on top of each other at half opacity.
  const verdictIn = ease([2.8, 3.0], [0, 1], OUT_EASE);
  const shown = verdictIn * ease([4.5, 4.68], [1, 0], STANDARD);
  const watching = 1 - ease([2.7, 2.88], [0, 1], STANDARD) + ease([4.62, 4.8], [0, 1], STANDARD);
  const fadeOut = ease([4.5, 4.8], [1, 0], STANDARD);
  const dot = spring({frame: frame - Math.round(2.6 * fps), fps, config: {damping: 14, stiffness: 160}}) * fadeOut;

  const xNow = interpolate(grow, [0, 1], [STEP * 1.5, NOW]);
  const pct = stairs(xNow);
  let d = `M0 ${y(stairs(0)).toFixed(2)}`;
  for (let px = 1; px < xNow * W; px++) d += ` L${px} ${y(stairs(px / W)).toFixed(2)}`;
  d += ` L${(xNow * W).toFixed(2)} ${y(pct).toFixed(2)}`;
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
          {proj > 0.001 && (
            <path d={`M${NOW * W} ${y(55)} L${projX * W} ${y(projY)}`} fill="none" stroke={accentFill} strokeWidth={4} strokeDasharray="7 8" />
          )}
          <line x1={OUT * W} y1={y(100)} x2={OUT * W} y2={H - 4} stroke={accentInk} strokeWidth={2} strokeDasharray="4 5" opacity={verdictIn * 0.7} />
          {dot > 0.01 && <circle cx={OUT * W} cy={y(100)} r={9 * dot} fill={accentInk} stroke="#fff" strokeWidth={3 * Math.min(1, dot)} />}
        </g>
        <circle cx={xNow * W} cy={y(pct)} r={7} fill={accentFill} stroke="#fff" strokeWidth={3} />
      </svg>
      <div style={{position: 'relative', height: 28, marginTop: 8, fontSize: 20, color: INK_2, whiteSpace: 'nowrap'}}>
        <span style={{position: 'absolute', left: 0}}>8:20a</span>
        <span style={{position: 'absolute', right: 0}}>Reset 1:20p</span>
      </div>
      <div style={{position: 'absolute', marginTop: 18, fontSize: 30, fontWeight: 600, letterSpacing: '-0.02em', color: '#8e8e93', opacity: watching}}>
        Watching your pace…
      </div>
      <div style={{marginTop: 18, opacity: shown, transform: `translateY(${(1 - verdictIn) * 8}px)`}}>
        <div style={{fontSize: 38, fontWeight: 700, letterSpacing: '-0.03em', color: accentInk}}>Runs out ~11:50a</div>
        <div style={{fontSize: 22, color: INK_2, marginTop: 4}}>1h 30m before it resets</div>
      </div>
    </div>
  );
};
