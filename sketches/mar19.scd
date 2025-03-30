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

    var sig, env,
        tail, tailEnv;

    env = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec], curve:-5),
        doneAction:2);
    tailEnv = EnvGen.kr(
        Env.new([0, 1, 0], [atk, dec*1.25], curve:-10),
        doneAction:2);

    sig = Pulse.ar(tone * env, width:(SinOsc.ar(tone / 4)+1)/2, mul:amp) * env;

    sig = Splay.ar(
        Resonz.ar(sig, tone * [1/2, 1, 2, 3, 4]));
    sig = RLPF.ar(sig, tone * 2 * env, XLine.kr(0.5, 2, atk + dec) * 5);

    tail = BrownNoise.ar * amp/8 * tailEnv;
    sig = Splay.ar([sig, tail]) * 1/2;

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

SynthDef.new(\pad, {
    arg atk, dec, slev, rel, gate=1, amp,
        freq, out;

    var sig, mod, env;

	env = EnvGen.kr(
        Env.adsr(atk, dec, slev, rel),
        gate,
        doneAction:2);
	mod = SinOsc.kr(0.1, mul:freq/2);

	sig = Mix.ar([
		RLPF.ar(
			Pulse.ar(freq, width:Line.kr(0, 1, rel)),
			freq * 5),
		LPF.ar(Pulse.ar(freq, width:Line.kr(0.5, 0, rel)), freq * 10)
	]) * amp;

    sig = Splay.ar([
        sig * 3/4,
        Resonz.ar(
            sig * BrownNoise.ar + PinkNoise.ar,
            [freq/2, freq, freq*2],
            Line.kr(0.01, 25, rel)) * 0.01
    ]) * env;
	Out.ar(out, sig.tanh!2);
}).add;


SynthDef.new(\bass, {

    arg atk, rel, amp,
        fAtk=0.001, fRel=0.1, width=0.5, rq=1,
        freq, out;

    var sig, env, filterEnv;

    env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1)) * (freq * 15) + (freq * 5);
    sig = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq
    ) * amp * env;
    Out.ar(out, sig.softclip!2);
}).add;

)

Scale.lydian.degrees;

(
~patterns = Dictionary.new;

// Data patterns

// -- Harmonic Context
~patterns[\harmctx] = Pbind(
    \type, \rest,
    \dur, 16,
    \scale, Pseq(
        4.collect({Scale.locrian}) ++ 4.collect({Scale.lydian})
    ),
    \ctranspose, 3,
    \degreeSpace, Pif(
        Pkey(\scale) |==| Scale.locrian,
        Pseq([
            [0, 2, 6],
            [4, 6, 9],
            [0, 4, 7],
            [-5, 2, 6]
        ]),
        Pseq([
            [4, 6, 9],
            [0, 3, 6],
            [-2, 3, 9],
            [-1, 3, 6],
        ])
    )
).collect({ arg ev; ~harmctx = ev });

// Musical patterns

// -- Drums
~patterns[\kick1] = Pbind(
    \instrument, \kick,
    \freq, 75,
    \amp, -9.dbamp * Pbseq([0, 2, 10, 14, 16, 20, 22, 24, 30], 32),
    \atk, 0.01,
    \dec, 0.2,
    \out, 0
);

~patterns[\kick] = Pseq([
    ~patterns[\kick1],
    Pchain(
        Pbind(
            \amp, -9.dbamp * Pbseq([0, 18, 26], 32)),
        ~patterns[\kick1])
]);

~patterns[\snare1] = Pbind(
    \instrument, \snare,
    \tone, 1400,
    \amp, -3.5.dbamp * Pbseq([4, 16], 32),
    \atk, 0.001,
    \dec, 0.15);

~patterns[\snare] = Pseq([
    ~patterns[\snare1],
    Pchain(
        Pbind(
            \amp, -4.dbamp * Pbseq([4, 16, 18], 32)),
        ~patterns[\snare1])
]);

~patterns[\hh1] = Pbind(
    \instrument, \hh,
    \amp, -8.dbamp * Pbseq([0, 6, 12, 18, 21, 23, 26, 27], 32),
    \atk, 0.001,
    \dec, Pwhite(0.005, 0.1));

~patterns[\hh] = Pseq([
    ~patterns[\hh1],
    Pchain(
        Pbind(
            \amp, -9.dbamp * Pbseq([0, 2, 10, 14, 16, 20, 22, 24, 30], 32)),
        ~patterns[\hh1])
]);

~patterns[\metal1] = Pbind(
    \instrument, \metal,
    \freq, Pwhite(60, 380, 32),
    \amp, -2.dbamp * Pbseq([8], 32),
    \atk, 0.001,
    \dec, 0.05);

~patterns[\metal] = Pseq([
    ~patterns[\metal1],
    Pchain(
        Pbind(
            \freq, 220,
            \amp, -2.dbamp * Pbseq([8, 14], 32)),
        ~patterns[\metal1])
]);

~patterns[\drum1] = Pchain(
    Ppar([
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\hh],
        ~patterns[\metal]
    ]),
    Pbind(\dur, Prand([1/8], 64))
);

~patterns[\drum2] = Pchain(
    Ppar([
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\hh],
        ~patterns[\metal]
    ]),
    Pbind(\dur, Prand([1/8], 64))
);

~patterns[\drum3] = Pchain(
    Ppar([
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\hh],
        ~patterns[\metal]
    ]),
    Pbind(\dur, Prand([1/8], 64))
);

~patterns[\drum] = Pseq([
    ~patterns[\drum1],
    ~patterns[\drum2],
    ~patterns[\drum3],
]);


// -- Harmonic components
~patterns[\pad1] = Pbind(
    \instrument, \pad,
    \dur, 32,
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \octave, 4,
    \degree, Pfuncn({ ~harmctx[\degreeSpace] }, inf).trace,
    \atk, Pkey(\dur) * 1/4,
    \legato, 0.1,
    \rel, Pkey(\dur) * 3/4,
    \out, 0,
    \amp, -50.dbamp
);

~patterns[\pad] = Pseq([
    Pfindur(32, ~patterns[\pad1])
]);

~patterns[\bass1] = Pbind(
    \instrument, \bass,
    \dur, 1/8,
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \octave, Pseq([4, 5], inf),
    \degree, Pfuncn({ ~harmctx[\degreeSpace].choose }, inf).trace,
    \atk, Pkey(\dur) * 1/4,
    \rel, Pkey(\dur) * 1/4,
    \out, 0,
    \amp, -45.dbamp * Pbseq([0, 1, 2, 3, 4], 8, repeats:inf)
);

~patterns[\bass] = Pseq([
    Pfindur(32, ~patterns[\bass1])
]);

)


(

~tempo = TempoClock.new(140/60);
Pn(Plazy({ ~patterns[\harmctx] }), inf).play(~tempo, quant: Quant(timingOffset:0.05));

Pn(Plazy({ ~patterns[\drum] }), inf).play(~tempo);
//Pn(Plazy({ ~patterns[\bass] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\pad] }), inf).play(~tempo);

)