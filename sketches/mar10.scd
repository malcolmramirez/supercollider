Server.default.options.outDevice_("blackhole+phones");

s.boot;
s.quit;

Server.default.record;

(

SynthDef.new(\pad, {
    |freq, atk=0.1, rel=1, amp=0.2, out|

    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var mod = (SinOsc.kr(freq) + 4);
    var car = LPF.ar(Blip.ar(freq, numharm:mod), freq * 10) * amp * env;
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

)

(

var pPad, pBeep,
    rev, rbus,
    tempo;

tempo = TempoClock.new(80/60);

rbus = Bus.audio(s, 2);
rev = Synth.new(
    \reverb,
    [
        \in, rbus,
        \out, 0,
        \amp, 0.75
    ]);

Scale.phrygian.degrees;

pPad = {
    |repeats|
    Pbind(
        \instrument, \pad,
        \out, rbus,
        \dur, 8,
        \root, 3,
        \scale, Pseq([
            Pseq({Scale.phrygian}!4),
            Pseq({Scale.lydian}!4),
        ], repeats:repeats),
        \octave, 4,
        \degree, Pseq([
            [0, 2, 4, 6], [-2, 1, 3, 4], [-5, -2, 2, 5], [-5, -3, 2, 4]
        ], repeats:repeats).trace,
        \atk, Pkey(\dur, repeats:repeats) * 1/4,
        \amp, 0.025,
        \rel, Pkey(\dur, repeats:repeats) * 3/4,
    );
};

pBeep = {
    |repeats|
    Pbind(
        \instrument, \pad,
        \out, rbus,
        \dur, 1/8,
        \root, 3,
        \scale, Prand([Scale.phrygian, Scale.lydian], repeats:repeats),
        \octave, 6,
        \degree, Prand([
            0, 1, 2, 3, 4, 5, 6
        ], repeats:repeats).trace,
        \atk, 0.01,
        \amp, 0.025 * Peseq(1, 16, off:{ [0.5, 0].wchoose([0.25, 0.75]) }, repeats:repeats),
        \rel, 0.05,
    );
};

~pT = Ppar([
    pPad.value(inf),
    pBeep.value(inf)
]).play(tempo);

)