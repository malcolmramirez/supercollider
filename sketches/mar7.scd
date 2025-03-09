Server.default.options.outDevice_("blackhole+phones");

s.boot;
s.quit;

Server.default.record;

(

SynthDef.new(\kick, {
    |out, freq=50, atk=0.005, dec=0.2, amp=1|
    var env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
        doneAction:2);
    var kickFm = SinOsc.ar(freq * env, phase:pi/2) + Dust.ar(10, mul:0.05) * env;
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

SynthDef.new(\snare, {
    |out, atk=0.005, dec=0.05, tone=880, amp=0.25|
    var noiseEnv = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec * 1.5], curve:[-10, -6]),
        doneAction:2);

    var env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:[-10, -6]),
        doneAction:2);

    var hitFm = SinOsc.ar(tone * env, mul:amp) * env;
    var noise = WhiteNoise.ar(mul:amp/2) * noiseEnv;
    var mixed = Mix.ar([hitFm, noise]);

    Out.ar(out, mixed.tanh!2);
}).add;

SynthDef.new(\metal, {
    |out, freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, room=0.5, damp=0.5|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    var car = RLPF.ar(
        Pulse.ar(freq * cRatio + mod, mul:amp),
        XLine.kr(freq * 10, freq * 30, rel))!2;
    var reverbed = FreeVerb2.ar(
        car[0], // Left channel
        car[1], // Right Channel
        0.75, room, damp, amp) * env;
    Out.ar(out, reverbed.tanh) ;
}).add;

SynthDef.new(\bass, {
    |out, freq=500, atk=0.1, rel=1, amp=0.2, fAtk=0.001, fRel=0.1, width=0.5, rq|
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1)) * (freq * 30) + (freq * 10);
    var acid = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq
    ) * amp * env;
    Out.ar(out, acid.softclip!2);
}).add;

SynthDef.new(\pad, {
    |freq, atk=0.1, rel=1, amp=0.2, out|

    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var mod = (SinOsc.kr(freq / 4) + 1) * freq;
    var car = Mix.ar([
        RLPF.ar(
            Resonz.ar(
                Pulse.ar(freq),
                [freq / 2, mod, freq * 2],
                0.5),
            freq * 15),
        LPF.ar(Pulse.ar(freq), freq * 10);
    ]) * amp * env;
    Out.ar(out, car.softclip!2);
}).add;

SynthDef.new(\reverb, {
    arg in, out,
        mix = 1, room = 0.99, damp = 0.25,
        amp = 1.0;

    var sig, reverbed;

    sig = In.ar(in, 2);
    sig = FreeVerb2.ar(
        sig[0],
        sig[1],
        mix,
        room,
        damp
    );

    sig = sig * amp;
    sig = sig.softclip;

    Out.ar(out, sig);
}).add;

SynthDef.new(\noise, {
    |out, freq=500, atk=0.1, rel=0.1, amp=0.2|
    var env = EnvGen.kr(
        Env.perc(atk, rel),
        doneAction:2);
    var noise = PinkNoise.ar * env * amp;
    Out.ar(out, noise.softclip!2);
}).add;

)

(

var pKick, pHh, pSnare, pMetal, pNoise,
    pBass, pPad, pArp,
    rbus, rev,
    tempo;

tempo = TempoClock.new(80/60);

pKick = {
    |repeats|
    Pbind(
        \instrument, \kick,
        \out, 0,
        \dur, 1/8,
        \freq, 75,
        \amp, 0.5 * Peseq(10, 32, off: { [1, 0].wchoose([0.1, 0.9]) }, repeats:repeats)
    );
};

pHh = {
    |repeats|
    Pbind(
        \instrument, \hh,
        \out, 0,
        \dur, 1/8,
        \amp, 0.6 * Peseq(11, 32, off: { [1, 0].wchoose([0.25, 0.75]) }, repeats:repeats),
    );
};

pNoise = {
    |repeats|
    Pbind(
        \instrument, \noise,
        \out, 0,
        \dur, 1/8,
        \amp, 0.05 * Peseq(9, 32, offset:6, repeats:repeats),
        \atk, Pexprand(0.01, 0.05),
        \rel, Pexprand(0.01, 0.05)
    );
};

pSnare = {
    |repeats|
    Pbind(
        \instrument, \snare,
        \out, 0,
        \dur, 1/8,
        \tone, 440,
        \amp, 0.05 * Pseq([
            Peseq(1, 16, offset:10, repeats:1),
            Peseq(3, 8, offset:0, repeats:1),
            Peseq(2, 8, offset:4, repeats:1),
        ], repeats),
    );
};

pMetal = {
    |repeats|
    Pbind(
        \instrument, \metal,
        \out, 0,
        \dur, 1/8,
        \freq, 300,
        \atk, 0.001,
        \amp, 0.5 * Pseq([
            Peseq(1, 16, offset:10, repeats:1),
            Peseq(3, 8, offset:0, repeats:1),
            Peseq(2, 8, offset:4, repeats:1),
        ], repeats),
        \rel, 0.1
    );
};

pBass = {
    |repeats|
    Pbind(
        \instrument, \bass,
        \out, 0,
        \dur, 1/8,
        // D#4 in midi.
        \root, 2,
        \scale, Scale.lydian,
        \octave, Prand([3, 4], repeats:repeats),
        \degree, Pseq([0, 3, 5], repeats:repeats),
        \atk, 0.001,
        \amp, 0.1 * Pseq([
            Peseq(
                1, 32,
                offset:6,
                repeats:1),
            ],
            repeats:repeats
        ),
        \rel, Pkey(\dur, repeats:repeats) * 3/4,
        \fRel, Ptime().collect({ arg t; (sin(t / 4) + 1) * 0.05 }),
        \rq, 1
    );
};

rbus = Bus.audio(s, 2);
rev = Synth.new(
    \reverb,
    [
        \in, rbus,
        \out, 0,
        \mix, 1,
        \room, 0.99,
        \amp, 0.05
    ]
);

pPad = {
    |repeats|
    Pbind(
        \instrument, \pad,
        \out, rbus,
        \dur, Pseq([4, 4, 8], repeats:repeats),
        // D#4 in midi.
        \root, 2,
        \scale, Scale.lydian,
        \octave, Pseq([5, 5, 4, 4, 5, 5, 3, 3], repeats:repeats),
        \degree, Pseq([
            Pfuncn({ [0, 1, 3, [4, 6, 7].choose ] }),
            Pfuncn({ [3, 5, 7, [9, 1, 0].choose ] })
        ], repeats:repeats),
        \atk, 0.001,
        \amp, 0.025,
        \rel, Pkey(\dur, repeats:repeats) * 3/4,
    );
};

pArp = {
    |repeats|
    Pbind(
        \instrument, \pad,
        \out, 0,
        \dur, 1/8,
        // D#4 in midi.
        \root, 2,
        \scale, Scale.lydian,
        \octave, Pseq([6, 6, 5, 5, 6, 6, 4, 4], repeats:repeats),
        \degree, Pseq([
            0, 1, 3, Pfuncn({ [4, 6, 7].choose }),
            3, 5, 6, Pfuncn({ [9, 1, 0].choose }),
        ], repeats:repeats),
        \atk, 0.001,
        \amp, 0.005,
        \rel, Pkey(\dur, repeats:repeats) * 3/4,
    );
};

~pT = Ppar([
    pKick.value(inf),
    pHh.value(inf),
    pSnare.value(inf),
    pPad.value(inf),
    pBass.value(inf),
    pNoise.value(inf),
    pArp.value(inf),
]).play(tempo);

)