

Platform.userExtensionDir;

s.boot;
s.quit;

(
SynthDef.new(\kick, {
    |out, freq=50, atk=0.005, dec=0.2, amp=1|
    var env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
        doneAction:2);
    var kickFm = SinOsc.ar(freq * env, phase:1) + Dust.ar(10, mul:0.05) * env;
    Out.ar(out, Clip.ar(kickFm!2) * amp);
}).add;

SynthDef.new(\hh, {
    |out, tone=40, atk=0.005, dec=0.05, amp=0.25|
    var env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
        doneAction:2);

    // Make a square wave
    var pulses = all {:Pulse.ar(tone * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };
    var hh2 = BPF.ar(pulses.sum, 10000, 1/10);
    hh2 = HPF.ar(hh2, 5000);

    hh2 = hh2 * env;
    Out.ar(out, Clip.ar(hh2!2) * amp);
}).add;


SynthDef.new(\clap, {
    |out, tone=330, amp=1, ringTime=0.001|
    var env = EnvGen.kr(
        Env.new(
            [1, 0, 1, 0, 1, 0, 1, 0],
            [0.011, 0, 0.012, 0, 0.08, 0, 0.019],
            curve:2),
        doneAction:2);
    var clap = BPF.ar(PinkNoise.ar, 1800, 1/2.5);

    clap = clap * env;
    Out.ar(out, Clip.ar(clap!2) * amp);
}).add;

)



(



p = Ppar(
    [
        Pbind(
            \instrument, \kick,
            \out, 0,
            \dur, 1/8,
            \amp, Pseq([
                Peseq(2, 16, repeats:1, offset:0) +
                Peseq(5, 16, repeats:1, on:{ if(1.0.rand > 0.5, 0.5, 0) }, offset:2)
            ], inf),
            \freq, 150
        ),
        Pbind(
            \instrument, \hh,
            \out, 0,
            \dur, 1/8,
            \amp, Pseq([
                Peseq(13, 16, off:0.1, repeats:1, offset:0)
            ], inf)
        ),
        Pbind(
            \instrument, \clap,
            \out, 0,
            \dur, 1/8,
            \amp, Pseq([
                Peseq(1, 8, repeats:1, offset:4)
            ], inf)
        ),
    ]
).play;

)