s.boot;
s.quit;

(

SynthDef.new(\pad, {
    arg freq=440,
        amp=0.5, atk=5, rel=7.5,
        out;

    var sinOscs, triOscs,
        mix;

    sinOscs = SinOsc.ar(freq);
    triOscs = LFTri.ar(freq, mul:0.5);

    mix = Mix.ar([sinOscs] ++ [triOscs]) * amp;
    mix = HPF.ar(LPF.ar(mix, 1000), 100);
    mix = mix * EnvGen.kr(Env.perc(atk, rel), doneAction:2);

    Out.ar(out, mix);
}).add;

SynthDef.new(\glitch, {
    arg freq=500,
        mRatio=1, cRatio=1, index=1,
        atk=0.1, rel=1, amp=0.2, pan,
        out;
    var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    var car = RLPF.ar(
        Pulse.ar(freq * cRatio + mod, mul:amp),
        XLine.kr(freq * 10, freq * 30, rel)) * env;
    car = Pan2.ar(car, pan);
    Out.ar(out, Clip.ar(car));
}).add;

SynthDef.new(\reverb, {
    arg mix, room, damp,
    in, out;

    var sig;

    sig = FreeVerb.ar(
        In.ar(in),
        mix, room, damp);

    sig = HPF.ar(LPF.ar(sig, 2000), 500);

    Out.ar(out, sig!2);
}).add;

)

(

var tempo = TempoClock.new(120/60);

~rbus = Bus.audio(s);
~dbus = Bus.audio(s);

~et7 = Scale.new((0..6), 7, Tuning.et(7), "7tet");

(~et7.ratios * 440).postln;

~rev = Synth.new(
    \reverb,
    [
        \mix, 0.5,
        \room, 0.999,
        \damp, 1,
        \in, ~rbus,
        \out, 0
], addAction:\addToTail);

~pPad = Pbind(
    \instrument, \pad,
    \dur, 16,
    \root, 10,
    \scale, ~et7,
    \octave, 4,
    \degree, Pseq([
        [-2, 1, 4],
        [-2, 3, 6],
        [-6, 2, 0],
        [-4, 0, 4]
    ], repeats:inf),
    \amp, 0.05,
    \out, ~rbus
);

Ppar([~pPad], repeats:inf).play(tempo);
)


~rev.stop;

