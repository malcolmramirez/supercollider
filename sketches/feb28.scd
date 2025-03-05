Server.default.options.outDevice_("Multi-Output Device");

s.boot;
s.quit;

Server.default.record;

(

SynthDef.new(\glitch, {
    |out, freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    var car = RLPF.ar(
        Pulse.ar(freq * cRatio + mod, mul:amp),
        XLine.kr(freq * 10, freq * 30, rel)) * env;
    car = Pan2.ar(car, pan);
    Out.ar(out, Clip.ar(car));
}).add;

SynthDef.new(\karplus, {
    |out, freq=500, atk=0.1, rel=1, amp=0.2, decayTime=0.5, coef=0.5|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var kp = Pluck.ar(
        PinkNoise.ar,
        Dust.ar(1, mul:2, add:-1),
        maxdelaytime:0.5,
        delaytime:(freq.reciprocal),
        decaytime:decayTime,
        coef:coef
    ) * amp * env;
    Out.ar(out, kp.softclip!2);
}).add;


SynthDef.new(\pad, {
    |out, freq=500, atk=0.1, rel=1, amp=0.2, rq=0.1s|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var pad = Mix.ar(
        Resonz.ar(
            Pulse.ar(freq),
            freq,
            rq)
    ) * env * amp;
    Out.ar(out, pad.softclip!2);
}).add;

SynthDef.new(\noise, {
    |out, freq=500, atk=0.1, rel=0.1, amp=0.2, decayTime=0.5, coef=0.5|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var noise = PinkNoise.ar * amp;
    Out.ar(out, noise.softclip!2);
}).add;

)

(

var pKarplus, pGlitch, pGlitchClick, pGlitchKick, pNoise, pPad;

~ts = 1;

~chords = 63.midicps * [
    [
        1,
        Scale.lydian.ratios[5]
    ],
    [
        Scale.lydian.ratios[3],
        Scale.lydian.ratios[6]
    ],
    [
        1,
        Scale.lydian.ratios[4]
    ],
    [
        Scale.lydian.ratios[1],
        Scale.lydian.ratios[6]
    ],
];

pKarplus = {
    |repeats, dur|
    Pbind(
        \instrument, \karplus,
        \out, 0,
        \stretch, ~ts,
        \dur, 2,
        // D#4 in midi.
        \freq, Pwalk(~chords, 1, 1).trace,
        \atk, 0.01,
        \amp, 0.065,
        \rel, 4 * Pkey(\dur, repeats:inf) * Pkey(\stretch, repeats:inf),
        \decayTime, 1,
        \coef, Pwhite(0.4, 0.45).trace
    );
};

pGlitchClick = {
    |repeats|
    Pbind(
        \instrument, \glitch,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \freq, 440,
        \index, Pwhite(1, 5),
        \amp, 0.1 * Peseq(
            7, 8,
            off:{ [0.25, 0].wchoose([0.1, 0.9]) },
            repeats:repeats),
        \atk, 0.001,
        \rel, 0.01 * Peseq(
            1, 8,
            off:{ [0.1, 0].wchoose([0.1, 0.9]) },
            repeats:repeats))
};

pGlitchKick = {
    |repeats|
    Pbind(
        \instrument, \glitch,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \freq, 55,
        \index, Pwhite(15, 20),
        \amp, 0.2 * Peseq(
            1, 8,
            off:{ [0.25, 0].wchoose([0.1, 0.9]) },
            repeats:repeats),
        \atk, 0.001,
        \rel, 0.05)
};

pNoise = {
    |repeats|
    Pbind(
        \instrument, \noise,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \amp, 0.035 * Peseq(
            1, 16,
            off:{ [0.5, 0].wchoose([0.1, 0.9]) },
            offset:6,
            repeats:repeats),
        \atk, 0.001,
        \rel, Pexprand(0.01, 0.05));
};

pPad = {
    |repeats|
    Pbind(
        \instrument, \pad,
        \out, 0,
        \stretch, ~ts,
        \dur, 4,
        \freq, Pwalk(~chords, 1, 1).trace,
        \atk, 0.01,
        \amp, 0.01,
        \rel, 3 * Pkey(\dur, repeats:inf) * Pkey(\stretch, repeats:inf));
};

~pT = Ppar([
    pKarplus.value(inf),
    pGlitchClick.value(inf),
    pGlitchKick.value(inf),
    pNoise.value(inf),
    pPad.value(inf)
]).play;

)

Server.default.stopRecording;