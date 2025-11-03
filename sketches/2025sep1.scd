
(
SynthDef.new(\drone, {
    var sig, mod, modmod, trig;

    modmod = SinOsc.kr(
        LFNoise2.kr(\modmodf.kr(0.01)).abs, mul: \modmoddepth.kr(100));

    mod = SinOsc.kr(
        \modf.kr(0.05) * modmod,
        add: 5) * LFNoise2.kr(10, mul: \moddepth.kr(100)).abs;

    sig = Blip.ar(\freq.kr(110), numharm: mod);

    sig = MoogFF.ar(sig, LFNoise2.kr(10, mul: \freq.kr(110) * TRand.ar(10, 100, Dust.kr(2))).abs);
    Out.ar(\out.kr(0), sig ! 2);
}).play;
)

(
b = ~dirt.buffers[\break][1];

c = ~dirt.buffers[\break][2];
)

(
{
    (PlayBuf.ar(2, b) - PlayBuf.ar(2, c));
}.play
)
