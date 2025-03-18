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

SynthDef.new(\snare, {
    arg amp, atk, dec,
        tone=880, out;

    var noiseEnv, env,
        hitFm, noise, mixed;

    noiseEnv = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec * 1.5], curve:[-10, -6]),
        doneAction:2);

    env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:[-10, -6]),
        doneAction:2);

    hitFm = SinOsc.ar(tone * env, mul:amp) * env;
    noise = WhiteNoise.ar(mul:amp/2) * noiseEnv;
    mixed = Mix.ar([hitFm, noise]);

    Out.ar(out, mixed.tanh!2);
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

)

(
~patterns = Dictionary.new;

// Data patterns
~patterns[\harmctx] = Pbind(
    \type, \rest,
    \dur, 16,
    \scale, Scale.lydian,
    \ctranspose, 2,
    \degreeSpace, Pseq(
        [
            [0, 2, 4, 6],
            [-3, 4, 6, 9]
        ], inf).trace
).collect({ arg ev; ~harmctx = ev });

// Musical patterns

// -- Drums
~patterns[\kick1] = Pbind(
    \instrument, \kick,
    \dur, 1/8,
    \freq, 75,
    \amp, -15.dbamp * Pbseq([0, 24], 32),
    \atk, 0.01,
    \dec, 0.2);

~patterns[\snare1] = Pbind(
    \instrument, \snare,
    \dur, 1/8,
    \amp, -25.dbamp * Pbseq([4, 16], 32),
    \atk, 0.001,
    \dec, 0.075);

~patterns[\metal1] = Pbind(
    \instrument, \metal,
    \dur, 1/8,
    \freq, 250,
    \amp, -7.dbamp * Pbseq([24], 32),
    \atk, 0.01,
    \dec, 0.075);

~patterns[\hh1] = Pbind(
    \instrument, \hh,
    \dur, 1/8,
    \amp, -10.dbamp * Plazy({ Pbseq(Array.rand(8, 0, 15) * 2, 32) }));

~patterns[\kick] =
    Pseq([
        ~patterns[\kick1],
        Pchain(
            Pbind(
                \amp, -5.dbamp * Pbseq([4, 24], 32),
            ),
            ~patterns[\kick1])
    ]);

~patterns[\snare] = Pseq([
    ~patterns[\snare1],
    Pchain(
        Pbind(
            \amp, -25.dbamp * Pbseq([4], 32),
        ),
        ~patterns[\snare1])
    ]);

~patterns[\metal] = Pseq([
    ~patterns[\metal1],
    Pchain(
        Pbind(
            \freq, 200,
            \amp, -7.dbamp * Pbseq([30], 32),
        ),
        ~patterns[\metal1])
    ]);

~patterns[\hh] = ~patterns[\hh1];

// -- Pad and melody
~patterns[\pad1] = Pbind(
    \instrument, \pad,
    \dur, 8,
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }),
    \degree, Pfuncn({ ~harmctx[\degreeSpace] }),
    \atk, 1,
    \dec, 0.5,
    \sustain, 0.1,
    \slev, 0.75,
    \rel, 2,
    \out, 0,
    \amp, -22.dbamp);

~rbus = Bus.audio(s, 2);
~rev = Synth.new(
    \reverb,
    [
        \in, ~rbus,
        \out, 0,
        \amp, 0.75,
        \damp, 0.95
    ]);

~patterns[\melody1] = Pbind(
    \instrument, \pad,
    \dur, Prand([1/2, 1/4, 1/8, 1/16]),
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }),
    \octave, 4,
    \degree, Pfuncn({ ~harmctx[\degreeSpace].rand }),
    \atk, Pkey(\dur) * 1/4,
    \legato, Pwhite(0.05, 0.5, 1),
    \rel, Pkey(\dur) * 3/4,
    \hmRatio, 1,
    \hplev, 2,
    \lplev, 5.5,
    \out, ~rbus,
    \amp, -25.dbamp);

~patterns[\pad] = Pseq([
    ~patterns[\pad1];
]);


~patterns[\melody] = Pseq([
    ~patterns[\melody1];
]);

)


(

~tempo = TempoClock.new(120/60);
~patterns[\harmctx].play(~tempo);

/*
Pn(Plazy({ ~patterns[\kick] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\snare] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\metal] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\hh] }), inf).play(~tempo);*/

Pn(Plazy({ ~patterns[\kick] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\melody] }), inf).play(~tempo);

)