import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {BODY, CAUTION, DISPLAY, INK, INK_2, MUTED} from './OgVideo';

const GRAPHITE = '#2c2c2d';

// Fuel Gauge's Claude Code 5-hour card: usage climbs to 55%, the forecast line reaches 100% before the reset,
// the verdict lands, then the window drains back to where it starts, so the loop has no seam.
const W = 368;
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

export const ForecastCard = () => {
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
      style={{width: '100%', height: '100%', boxSizing: 'border-box', padding: '24px 24px', borderRadius: 6, fontFamily: BODY,
        background: 'radial-gradient(100% 100% at 50% 110%, #e2ddcf, #f4f2eb 70%)',
        boxShadow: '0 0 0 3px #b7b9bb, 0 0 0 4px rgba(0,0,0,.4), inset 0 2px 6px rgba(0,0,0,.18)', fontVariantNumeric: 'tabular-nums'}}
    >
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
        <div>
          <div style={{fontFamily: DISPLAY, fontSize: 30, fontWeight: 600, color: INK}}>Claude Code</div>
          <div style={{fontFamily: DISPLAY, fontSize: 16, fontWeight: 600, letterSpacing: '0.22em', textTransform: 'uppercase', color: MUTED, marginTop: 6}}>5-hour limit</div>
        </div>
        <div style={{fontFamily: DISPLAY, fontSize: 56, fontWeight: 600, color: INK, lineHeight: 1}}>{Math.round(pct)}%</div>
      </div>
      <div style={{position: 'relative', height: 8, borderRadius: 1, background: '#d6d7d7', margin: '18px 0 20px', overflow: 'hidden'}}>
        <div style={{position: 'absolute', inset: 0, width: `${pct}%`, background: GRAPHITE}} />
      </div>
      <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} style={{display: 'block', overflow: 'visible'}}>
        <line x1={0} y1={y(100)} x2={W} y2={y(100)} stroke="#1d1d1d" strokeWidth={1.5} strokeDasharray="3 5" opacity={0.45} />
        <line x1={0} y1={H - 4} x2={W} y2={H - 4} stroke="#1d1d1d" strokeWidth={1.5} opacity={0.5} />
        <line x1={W} y1={y(100) - 6} x2={W} y2={H - 4} stroke="#1d1d1d" strokeWidth={1.5} strokeDasharray="4 5" opacity={0.6} />
        <path d={area} fill={GRAPHITE} opacity={0.08} />
        <path d={d} fill="none" stroke={GRAPHITE} strokeWidth={3.5} strokeLinejoin="round" />
        <g opacity={fadeOut}>
          {proj > 0.001 && (
            <path d={`M${NOW * W} ${y(55)} L${projX * W} ${y(projY)}`} fill="none" stroke={CAUTION} strokeWidth={3.5} strokeDasharray="7 8" />
          )}
          <line x1={OUT * W} y1={y(100)} x2={OUT * W} y2={H - 4} stroke={CAUTION} strokeWidth={2} strokeDasharray="4 5" opacity={verdictIn * 0.8} />
          {dot > 0.01 && <circle cx={OUT * W} cy={y(100)} r={9 * dot} fill={CAUTION} stroke="#f4f2eb" strokeWidth={3 * Math.min(1, dot)} />}
        </g>
        <circle cx={xNow * W} cy={y(pct)} r={7} fill={GRAPHITE} stroke="#f4f2eb" strokeWidth={3} />
      </svg>
      <div style={{position: 'relative', height: 28, marginTop: 8, fontSize: 19, color: MUTED, whiteSpace: 'nowrap'}}>
        <span style={{position: 'absolute', left: 0}}>8:20a</span>
        <span style={{position: 'absolute', right: 0}}>Reset 1:20p</span>
      </div>
      <div style={{position: 'absolute', marginTop: 18, fontFamily: DISPLAY, fontSize: 32, fontWeight: 300, color: MUTED, opacity: watching}}>
        Watching your pace…
      </div>
      <div style={{marginTop: 18, opacity: shown, transform: `translateY(${(1 - verdictIn) * 8}px)`}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 12, fontFamily: DISPLAY, fontSize: 38, fontWeight: 600, color: INK}}>
          <span style={{width: 12, height: 12, borderRadius: '50%', background: CAUTION, boxShadow: `0 0 8px ${CAUTION}`}} />
          Runs out ~11:50a
        </div>
        <div style={{fontSize: 21, color: INK_2, marginTop: 4}}>1h 30m before it resets</div>
      </div>
    </div>
  );
};
