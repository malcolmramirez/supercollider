Server.default.options.outDevice_("Multi-Output Device");

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
    var mod = SinOsc.kr(freq / 2, mul:0.25);
    var car = Mix.ar([
        RLPF.ar(
            Blip.ar(freq, Pulse.ar(1 * Line.kr(1, 50, rel/2), mul:50) ),
            freq * 5),
        LPF.ar(Blip.ar(freq), freq * 10)
    ]) * amp * env;
    Out.ar(out, car.softclip!2);
}).add;

)

(

var pKick, pHh, pSnare, pMetal, pMetal2,
pBass, pKarplus, pArp, pPad;

~ts = 2/3;

pKick = {
    |repeats|
    Pbind(
        \instrument, \kick,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \freq, 75,
        \amp, 0.75 * Peseq(1, 32, off: { [1, 0].wchoose([0.1, 0.9]) }, repeats:repeats)
    );
};

pHh = {
    |repeats|
    Pbind(
        \instrument, \hh,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \amp, 0.6 * Peseq(11, 32, off: { [0.6, 0].wchoose([0.25, 0.75]) }, repeats:repeats),
    );
};

pSnare = {
    |repeats|
    Pbind(
        \instrument, \snare,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \atk, 0.001,
        \amp, 0.1 * Peseq(1, 32, off: { [0.5, 0].wchoose([0.25, 0.75]) }, offset:4, repeats:repeats),
    );
};

pMetal = {
    |repeats|
    Pbind(
        \instrument, \metal,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        \freq, 300,
        \atk, 0.001,
        \amp, Pseq([
            Peseq(1, 8, on: 0.5, offset:4, repeats:1),
            Peseq(1, 8, on: 0.5, offset:6, repeats:1),
        ], repeats),
        \rel, 0.1
    );
};

pMetal2 = {
    |repeats|
    Pbind(
        \instrument, \metal,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        // D#4 in midi.
        \freq, Pseq([
            63.midicps * Pseq(Scale.mixolydian.ratios, repeats:1),
            68.midicps * Pseq(Scale.mixolydian.ratios, repeats:1)
        ], repeats:repeats) * (1 + Pwhite(0.001, 0.05)),
        \atk, 0.001,
        \amp, 0.33 * Peseq(
            3, 16,
            off:{ [0.5, 0].wchoose([0.1, 0.9]) },
            offset:4,
            repeats:repeats),
        \rel, 0.1
    );
};

pBass = {
    |repeats|
    Pbind(
        \instrument, \bass,
        \out, 0,
        \stretch, ~ts,
        \dur, 1/8,
        // D#4 in midi.
        \root, 2,
        \scale, Scale.mixolydian,
        \octave, Prand([2, 3], repeats:repeats),
        \degree, Prand([0, 3, 5], repeats:repeats),
        \atk, 0.001,
        \amp, 0.065 * (
            Peseq(
                1, 16,
                off:{ [1, 0].wchoose([0.1, 0.9]) },
                offset:4,
                repeats:repeats) +
            Peseq(
                1, 16,
                offset:7,
                repeats:repeats)
        ),
        \rel, 0.1,
        \fRel, Pwhite(0.001, 0.1),
        \width, Pwhite(0.0, 1.0),
        \rq, Pexprand(1/30, 1/10)
    );
};

// add more sprinkled as a lead?
pPad = {
    |repeats|
    Pbind(
        \instrument, \pad,
        \out, 0,
        \stretch, ~ts,
        \dur, 8,
        // D#4 in midi.
        \root, 3,
        \scale, Scale.mixolydian,
        \degree, Pseq([
            [0, 1, 2, 5],
            [0, 2, 5, 8],
            [3, 4, 5, 9],
            [2, 3, 4, 8],
        ], repeats:repeats),
        \octave, 5,
        \atk, 0.05,
        \amp, 0.01,
        \rel, 2
    );
};

~pT = Ppar([
    pKick.value(inf),
    pHh.value(inf),
    pSnare.value(inf),
    pMetal2.value(inf),
    pMetal.value(inf),
    pBass.value(inf),
    pPad.value(inf),
]).play;

)

Server.default.stopRecording;