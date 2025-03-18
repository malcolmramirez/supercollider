Server.default.options.outDevice_("blackhole+phones");

s.boot;
s.quit;

(

SynthDef.new(\kick, {
    arg amp, atk, dec,
        freq, out;

    var env, sig;

    env = EnvGen.kr(
        Env.perc(atk, dec, curve:-6),
        doneAction:2);

    sig = SinOsc.ar(freq * env, phase:pi/2);
    sig = sig + Dust.ar(10, mul:0.05);
    sig = sig * env * amp;

    Out.ar(out, Clip.ar(sig!2));
}).add;

SynthDef.new(\metal, {
    arg amp, atk, dec,
        room=0.5, damp=0.5,
        mRatio=1, cRatio=1, index=1,
        freq, out;

    var env, mod, car, reverbed;

    env = EnvGen.kr(Env.perc(atk, dec), doneAction:2);

    mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    car = RLPF.ar(
        Pulse.ar(freq * cRatio + mod, mul:amp),
        XLine.kr(freq * 10, freq * 30, dec));

    reverbed = FreeVerb.ar(car, 0.75, room, damp, amp) * env;

    Out.ar(out, reverbed.tanh!2);
}).add;

SynthDef.new(\hh, {
    arg amp, atk=0.005, dec=0.05,
        tone=40, out;

    var env, pulses, hh;

    env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
        doneAction:2);

    // Make a square wave
    pulses = all {:Pulse.ar(tone * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };

    hh = BPF.ar(pulses.sum, 10000, 1/10);
    hh = HPF.ar(hh, 5000);
    hh = hh * amp * env;

    Out.ar(out, Clip.ar(hh!2));
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

)

(
~patterns = Dictionary.new;

~patterns[\kick] = Pbind(
    \instrument, \kick,
    \dur, 1/8,
    \freq, 75,
    \amp, -5.dbamp * Pseq([Peseq(1, 8), Peseq(1, 8, offset:2)]),
    \atk, 0.01,
    \dec, 0.2);

~patterns[\metal] = Pbind(
    \instrument, \metal,
    \dur, 1/8,
    \freq, 280,
    \index, 1,
    \amp, -7.5.dbamp * Pseq([Peseq(1, 8, offset:4), Peseq(1, 8, offset:6)]),
    \atk, 0.01,
    \dec, 0.1);

~patterns[\snare] = Pbind(
    \instrument, \snare,
    \dur, 1/8,
    \amp, -25.dbamp * Peseq(1, 16, offset:4),
    \atk, 0.001,
    \dec, 0.075);

~patterns[\hh] = Pbind(
    \instrument, \hh,
    \dur, 1/8,
    \amp, -6.dbamp * Peseq(8, 16, off: { [-20.dbamp, 0].wchoose([0.75, 0.25]) }, offset:4));
)


(
~patterns[\kick] = Pchain(
    Pbind(
        \amp, -5.dbamp * Pseq([Peseq(1, 8, offset:6), Peseq(1, 8, offset:0)])
    ),
    ~patterns[\kick]);
)

(
~patterns[\metal] = Pchain(
    Pbind(
        \index, 1,
        \freq, 280,
        \amp, -7.5.dbamp * Pseq([Peseq(1, 8, offset:4), Peseq(1, 8, offset:2)])
    ),
    ~patterns[\metal]);
)

(
~patterns[\hh] = Pchain(
    Pbind(
      \amp, -6.dbamp * Peseq(8, 32, off: { [-20.dbamp, 0].wchoose([0.75, 0.25]) }, offset:4)
    ),
    ~patterns[\hh]);
)

(
~patterns[\snare] = Pchain(
    Pbind(
        \amp, -30.dbamp * Peseq(1, 16, offset:0),
    ),
    ~patterns[\snare]);
)

(

~tempo = TempoClock.new(140/60);

Pn(Plazy({ ~patterns[\kick] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\hh] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\snare] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\metal] }), inf).play(~tempo);

)