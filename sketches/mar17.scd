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
        freq, out=0;

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

SynthDef.new(\pad, {
    arg amp, atk, dec, slev, rel,
        hplev=1/2, lplev=2,
        hmRatio=1,
        gate=1, freq, out;

    var env, sig;

    env = EnvGen.kr(
        Env.adsr(atk, dec, slev, rel),
        gate,
        doneAction:2);

    sig = Blip.ar(freq + SinOsc.ar(freq * hmRatio));
    sig = Splay.ar([
        sig,
        Resonz.ar(sig, [freq/2, freq*2]) * 1/4
    ]);
    sig = HPF.ar(sig, freq * hplev);
    sig = LPF.ar(sig, freq * lplev);
    sig = sig * env * amp;

    Out.ar(out, sig.softclip);
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

SynthDef.new(\snare, {

    arg amp, atk, dec,
        tone=880, out;

    var sig, env;

    env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:-5),
        doneAction:2);

    sig = Pulse.ar(tone * env, width:(SinOsc.ar(tone / 4)+1)/2, mul:amp) * env;

    sig = Splay.ar(
        Resonz.ar(sig, tone * [1/2, 1, 2, 3, 4]));
    sig = RLPF.ar(sig, tone / 1.5 * env, XLine.kr(0.5, 2, atk + dec) * 5);
    sig = Splay.ar([sig]);

    Out.ar(out, sig.tanh!2);
}).add;

SynthDef.new(\noise, {

    arg atk, rel, amp,
        freq, out;

    var env, sig;

    env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    sig = BrownNoise.ar * amp;
    Out.ar(out, sig.softclip!2);
}).add;

)

(
~rbus = Bus.audio(s, 2);
~rev = Synth.new(
    \reverb,
    [
        \in, ~rbus,
        \out, 0,
        \amp, 0.75,
        \damp, 0.95
    ]);

~patterns = Dictionary.new;

// Data patterns

// -- Harmonic Context
~patterns[\harmctx] = Pbind(
    \type, \rest,
    \dur, 16,
    \scale, Pseq([
        Pseq([Scale.lydian], 8),
        Pseq([Scale.phrygian], 8),
        Pseq([Scale.mixolydian], 8),
    ]),
    \ctranspose, 2,
    \degreeSpace, Pseq([
        Pseq([
            [0, 2, 4, 6],
            [-3, 4, 6, 9],
            [0, 4, 7, 11],
            [-5, 2, 3, 7],
        ], 2),
        Pseq([
            [0, 4, 7, 11],
            [0, 2, 4, 7],
            [-3, 4, 6, 9],
            [-5, 2, 3, 7],
        ], 2),
    ])
).collect({ arg ev; ~harmctx = ev });

// Musical patterns

// -- Drums
~patterns[\kick1] = Pbind(
    \instrument, \kick,
    \dur, Prand([1/8, 1/4, 1/2], 32),
    \freq, 75,
    \amp, -15.dbamp * Pbseq([0, 5, 10, 16, 20, 24], 32),
    \atk, 0.01,
    \dec, 0.2,
    \out, 0
);

~patterns[\kick] = Pseq([
    ~patterns[\kick1],
    Pchain(
        Pbind(\dur, 1/8),
        ~patterns[\kick1])
]);

~patterns[\snare1] = Pbind(
    \instrument, \snare,
    \dur, Prand([1/8, 1/4, 1/2], 32),
    \tone, 1600,
    \amp, -12.5.dbamp * Pbseq([4, 16], 32),
    \atk, 0.001,
    \dec, 0.075);

~patterns[\snare] = Pseq([
    ~patterns[\snare1],
    Pchain(
        Pbind(\dur, 1/8),
        ~patterns[\snare1])
]);

~patterns[\hh1] = Pbind(
    \instrument, \hh,
    \dur, Prand([1/16, 1/8, 1/4, 1/2], 32),
    \amp, -10.dbamp * Pbseq((0..15)*2, 32),
    \atk, 0.001,
    \dec, 0.005);

~patterns[\hh] = Pseq([
    ~patterns[\hh1],
    Pchain(
        Pbind(\dur, 1/8),
        ~patterns[\hh1])
]);

~patterns[\metal1] = Pbind(
    \instrument, \metal,
    \dur, Prand([1/8, 1/4, 1/2], 32),
    \freq, Pwhite(60, 480, 32),
    \amp, -3.5.dbamp * Pbseq([8, 9, 24, 25], 32),
    \atk, 0.001,
    \dec, 0.05);

~patterns[\metal] = Pseq([
    ~patterns[\metal1],
    Pchain(
        Pbind(\dur, 1/8),
        ~patterns[\metal])
]);

~patterns[\noise1] = Pbind(
    \instrument, \noise,
    \dur, Prand([1/8, 1/4, 1/2], 32),
    \amp, -35.dbamp * Pbseq(Pfuncn({(0..3) * 5 + 15.rand}), 32),
    \atk, 0.01,
    \dec, Pwhite(0.02, 0.1, 32));

~patterns[\noise] = Pseq([
    ~patterns[\noise1],
    Pchain(
        Pbind(\dur, 1/8),
        ~patterns[\noise])
]);

// -- Harmonic components
~patterns[\drone1] = Pbind(
    \instrument, \pad,
    \dur, 16,
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }),
    \octave, 3,
    \degree, Pfuncn({ ~harmctx[\degreeSpace].rand }),
    \atk, Pkey(\dur) * 2/4,
    \legato, 0.05,
    \rel, Pkey(\dur) * 3/4,
    \hmRatio, 1,
    \hplev, 2,
    \lplev, 1,
    \out, ~rbus,
    \amp, 3.dbamp);

~patterns[\drone] = Pseq([
    ~patterns[\drone1];
]);

~patterns[\melody1] = Pbind(
    \instrument, \pad,
    \dur, Pseq([1/8, 1/8, 1/2, 15.25], 4),
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, 4),
    \octave, 4,
    \degree, Pfuncn({ ~harmctx[\degreeSpace] }, 4),
    \atk, Pkey(\dur) * 1/4,
    \legato, 0.25,
    \rel, Pkey(\dur) * 3/4,
    \hmRatio, 1,
    \hplev, 0.5,
    \lplev, 4,
    \out, 0,
    \amp, -10.dbamp);

~patterns[\melody] = Pseq([
    ~patterns[\melody1];
]);

)


(

~tempo = TempoClock.new(120/60);
Pn(Plazy({ ~patterns[\harmctx] }), inf).play(~tempo, quant: Quant(timingOffset:0.05));

Pn(Plazy({ ~patterns[\kick] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\snare] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\metal] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\noise] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\drone] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\melody] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\hh] }), inf).play(~tempo);

)
