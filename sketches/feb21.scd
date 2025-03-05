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

SynthDef.new(\plink, {
    |out, amp=0.1, ringTime=0.001, freq=440, rel|
    var in = PinkNoise.ar;
    var env = EnvGen.kr(
        Env.perc(0.01, rel),
        doneAction:2);
    var resonate = {
        |input|
        var reson = Mix.ar(
            Resonz.ar(input, freq, 1/60) * env,
            Resonz.ar(input, freq * 2, 1/60) * env,
            Resonz.ar(input, freq / 2, 1/60) * env) * 1/3;

        DynKlank.ar(
            `[[freq/2, freq, freq*2], nil, 3.do{ ringTime }],
            reson);
    };

    var resonated = resonate.value(resonate.value(in));

    resonated = CombC.ar(resonated, 0.01, freq.reciprocal, 0.2) * env;

    Out.ar(out, Clip.ar(resonated!2) * amp);
}).add;

SynthDef.new(\fm, {
    arg freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0, bus;
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    var car = RLPF.ar(SinOsc.ar(freq * cRatio + mod, mul:amp), XLine.kr(freq * 10, freq * 5, rel)) * env;
    car = Pan2.ar(car, pan);
    Out.ar(bus, Clip.ar(car));
}).add;

)

(
~eseq = { | k = 1, n = 4, o = 0, on=1, off=0 |
    var events = (
        (k / n * (0..n - 1))
        .floor
        .differentiate
        .asInteger
        .min(1)[0] = if (k <= 0) { 0 } { 1 }
    ).rotate(o);
    var parsed = all {:if(e == 1, on.value, off.value;), e <- events };
    var l = parsed.postln;
    parsed;
};

p = Ppar(
    [
        Pbind(
            \instrument, \kick,
            \out, 0,
            \stretch, 2/3,
            \dur, 1/8,
            \amp, Pseq(~eseq.value(1, 8), inf),
            \freq, 75
        ),
        Pbind(
            \instrument, \clap,
            \out, 0,
            \stretch, 2/3,
            \dur, 1/8,
            \amp, Pseq(~eseq.value(1, 8, on:0.75), inf)
        ),
        Pbind(
            \instrument, \hh,
            \out, 0,
            \stretch, 2/3,
            \dur, 1/8,
            \amp, Pseq(~eseq.value(11, 16, off:0.25), inf)
        ),
        Pbind(
            \instrument, \fm,
            \out, 0,
            \stretch, 2/3,
            \dur, 1/4,
            \freq, Pseq(Scale.new((0..7), 7).ratios * 440, inf).trace,
            \rel, 0.025,
            \ringTime, 0.005,
            \amp, Pseq(~eseq.value(11, 16, 2, on:0.01), inf)
        ),
    ]
).play;

)

Scale.directory;

r.stop;