Server.default.options.outDevice_("External Headphones");

s.boot;
s.quit;

Server.default.record;

(

SynthDef.new(\kick, {
    arg atk=0.005, rel=0.2, amp=1,
        freq=50, out=0;

    var sig, env;

    env = EnvGen.kr(
        Env.perc(atk, rel, curve:-6),
        doneAction:2);

    sig = SinOsc.ar(freq * env, phase:pi/2) + Dust.ar(10, mul:0.05);
    sig = sig!2 * amp * env;
    sig = Clip.ar(sig);

    Out.ar(out, Clip.ar(sig));
}).add;

SynthDef.new(\hh, {
    arg atk=0.005, rel=0.05, amp=0.25,
        tone=40, out=0;

    var sig, env;

    env = EnvGen.kr(
        Env.perc(atk, rel, curve:-6),
        doneAction:2);

    sig = all {:Pulse.ar(tone * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };
    sig = BPF.ar(sig.sum, 10000, 1/10);
    sig = HPF.ar(sig, 5000);

    sig = sig!2 * amp * env;
    sig = Clip.ar(sig);

    Out.ar(out, sig);
}).add;

SynthDef.new(\snare, {
    arg atk=0.005, rel=0.05, amp=0.25,
        tone=880, out=0;

    var sig, env,
        noise, noiseEnv;

    noiseEnv = EnvGen.kr(
        Env.perc(atk, rel * 1.5, curve:-6),
        doneAction:2);

    env = EnvGen.kr(
        Env.perc(atk, rel, curve:-6),
        doneAction:2);

    sig = SinOsc.ar(tone * env, mul:amp) * env;
    noise = WhiteNoise.ar(mul:amp/2) * noiseEnv;
    sig = Mix.ar([sig, noise]);

    Out.ar(out, sig.tanh!2);
}).add;

SynthDef.new(\metal, {
    arg atk=0.1, rel=1, amp=0.2,
        mRatio=1, cRatio=1, index=1,
        room=0.5, damp=0.5,
        freq=500, out=0;

    var sig, env,
        mod;

    env = EnvGen.kr(
        Env.perc(atk, rel),
        doneAction:2);

    mod = SinOsc.ar(freq, mul:freq * mRatio * index);
    sig = RLPF.ar(
        Pulse.ar(freq * cRatio + mod, mul:amp),
        XLine.kr(freq * 10, freq * 30, rel));
    sig = FreeVerb.ar(sig, 0.75, room, damp);
    sig = sig!2 * amp * env;

    Out.ar(out, sig.tanh);
}).add;

SynthDef.new(\bass, {
    arg atk=0.1, rel=1, amp=0.2,
        fAtk=0.001, fRel=0.1, rq,
        width=0.5,
        freq=500, out=0;

    var sig, env,
        filterEnv;

    env = EnvGen.kr(
        Env.perc(atk, rel),
        doneAction:2);

    filterEnv = EnvGen.kr(Env.perc(fAtk, fRel, curve:1)) * (freq * 30) + (freq * 10);
    sig = RLPF.ar(
        Pulse.ar(freq, width:width),
        filterEnv,
        rq);

    sig = sig!2 * amp * env;

    Out.ar(out, sig.softclip);
}).add;

SynthDef.new(\pad, {
    arg atk=0.1, rel=1, amp=0.2,
        freq, out=0;

    var sig, env, mod;

    env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    mod = SinOsc.kr(freq / 2, mul:0.25);
    sig = Mix.ar([
        RLPF.ar(
            Blip.ar(freq, Pulse.ar(1 * Line.kr(1, 50, rel/2), mul:50) ),
            freq * 5),
        LPF.ar(Blip.ar(freq), freq * 10)
    ]);
    sig = sig!2 * amp * env;

    Out.ar(out, sig.softclip);
}).add;


SynthDef.new(\pad2, {
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
    sig = Mix.ar([
        sig,
        Resonz.ar(sig, [freq/2, freq*2]) * 1/4
    ]);
    sig = HPF.ar(sig, freq * hplev);
    sig = LPF.ar(sig, freq * lplev);
    sig = sig!2 * env * amp;

    Out.ar(out, sig.softclip);
}).add;

SynthDef.new(\wavepad, {
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

)

Scale.mixolydian.degrees;

(

~patterns = Dictionary.new;

// -- Harmonic contour patterns
~patterns[\harmctx] = Pbind(
    \type, \rest,
    \dur, 8,
    \scale, Scale.mixolydian,
    \ctranspose, 3,
    \degreeSpace, Pseq([
        [0, 1, 2, 3, 5],
        [0, 2, 3, 5, 10],
        [0, 3, 4, 5, 9],
        [0, 2, 3, 4, 8],
    ])
).collect({ arg ev; ~harmctx = ev });

// -- Drum patterns
~patterns[\kick] = Pbind(
    \instrument, \kick,
    \dur, 1/8,
    \freq, 75,
    \amp, 0.75 * Peseq(1, 32, off: { [1, 0].wchoose([0.1, 0.9]) }, repeats:inf));
~patterns[\kick] = Pfindur(32, ~patterns[\kick]);

~patterns[\hh] = Pbind(
    \instrument, \hh,
    \dur, 1/8,
    \amp, 0.6 * Peseq(11, 32, off: { [0.6, 0].wchoose([0.25, 0.75]) }, repeats:inf));
~patterns[\hh] = Pfindur(32, ~patterns[\hh]);

~patterns[\snare] = Pbind(
    \instrument, \snare,
    \dur, 1/8,
    \atk, 0.001,
    \amp, 0.1 * Peseq(1, 32, off: { [0.5, 0].wchoose([0.25, 0.75]) }, offset:4, repeats:inf));
~patterns[\snare] = Pfindur(32, ~patterns[\snare]);

~patterns[\metal] = Pbind(
    \instrument, \metal,
    \out, 0,
    \dur, 1/8,
    \freq, 300,
    \atk, 0.001,
    \amp, Pseq([
        Peseq(1, 8, on: 0.5, offset:4, repeats:1),
        Peseq(1, 8, on: 0.5, offset:6, repeats:1),
    ], inf),
    \rel, 0.1);
~patterns[\metal] = Pfindur(32, ~patterns[\metal]);


// -- Harmonic patterns
~patterns[\metalhi] = Pbind(
    \instrument, \metal,
    \out, 0,
    \dur, 1/8,
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \degree, Pfuncn({ ~harmctx[\degreeSpace].choose.min(8) }, inf).trace,
    \atk, 0.001,
    \amp, 0.33 * Peseq(
        3, 16,
        off:{ [0.5, 0].wchoose([0.1, 0.9]) },
        offset:4,
        repeats:inf),
    \rel, 0.1);
~patterns[\metalhi] = Pfindur(32, ~patterns[\metalhi]);

~patterns[\bass] = Pbind(
    \instrument, \bass,
    \out, 0,
    \dur, 1/8,
    // D#4 in midi.
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \degree, Pfuncn({ ~harmctx[\degreeSpace].choose }, inf).trace,
    \octave, Prand([2, 3], repeats:inf),
    \atk, 0.001,
    \amp, 0.065 * (
        Peseq(
            1, 16,
            off:{ [1, 0].wchoose([0.1, 0.9]) },
            offset:4,
            repeats:inf) +
        Peseq(
            1, 16,
            offset:7,
            repeats:inf)
    ),
    \rel, 0.1,
    \fRel, Pwhite(0.001, 0.1),
    \width, Pwhite(0.0, 1.0),
    \rq, Pexprand(1/30, 1/10));
~patterns[\bass] = Pfindur(32, ~patterns[\bass]);

~patterns[\pad] = Pbind(
    \instrument, \pad,
    \out, 0,
    \dur, 1/8,
    // D#4 in midi.
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \degree, Pfuncn({
        ~harmctx[\degreeSpace].choose;
    }, inf).trace,
    \octave, 5,
    \atk, Pkey(\dur) * 1/4,
    \amp, 0.01,
    \rel, Pkey(\dur) * 3/4);
~patterns[\pad] = Pfindur(32, ~patterns[\pad]);


~patterns[\pad2] = Pbind(
    \instrument, \pad2,
    \out, 0,
    \dur, 8,
    // D#4 in midi.
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \degree, Pfuncn({
        var curdled, mi;
        curdled = ~harmctx[\degreeSpace].curdle(0.4);
        mi = curdled.maxIndex({ arg c; c.size });
        curdled[mi];
    }, inf).trace,
    \octave, 5,
    \atk, Pkey(\dur) * 2/4,
    \legato, 0.5,
    \rel, Pkey(\dur) * 3/4,
    // \hmRatio, 1,
    \hplev, 2,
    \lplev, 1,
    \amp, 0.3);
~patterns[\pad2] = Pfindur(32, ~patterns[\pad2]);


~patterns[\pad3] = Pbind(
    \instrument, \pad2,
    \out, 0,
    \dur, Pseq([1/8, 1/8, 1/2, 15.25], inf),
    // D#4 in midi.
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \degree, Pfuncn({
        var curdled, mi;
        curdled = ~harmctx[\degreeSpace].curdle(0.4);
        mi = curdled.maxIndex({ arg c; c.size });
        curdled[mi];
    }, inf).trace,
    \octave, 5,
    \atk, Pkey(\dur) * 1/4,
    \legato, 0.5,
    \rel, Pkey(\dur) * 7/8,
    // \hmRatio, 1,
    \hplev, 2,
    \lplev, 1,
    \amp, 0.75);
~patterns[\pad3] = Pfindur(32, ~patterns[\pad3]);


~patterns[\wavepad] = Pbind(
    \instrument, \wavepad,
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
~patterns[\wavepad] = Pfindur(32, ~patterns[\wavepad]);

)

(

var tempo;

tempo = TempoClock.new(90/60);
Pn(Plazy({ ~patterns[\harmctx] }), inf).play(tempo, quant: Quant(timingOffset:0.05));

// Infinitely repeat patterns after duration is up
Ppar(
    [
        ~patterns[\kick],
        ~patterns[\hh],
        ~patterns[\metal],
        ~patterns[\snare],
        ~patterns[\bass],
        ~patterns[\metalhi],
        //~patterns[\pad],
        //~patterns[\pad2],
        //~patterns[\pad3],
        ~patterns[\wavepad],
    ].collect(
        {
            arg pat;
            Pn( Plazy({ pat }) )
        }
    )
).play(tempo);

(

var tempo;

tempo = TempoClock.new(90/60);
Pn(Plazy({ ~patterns[\harmctx] }), inf).play(tempo, quant: Quant(timingOffset:0.05));

Pseq([
    Pfindur(32, ~patterns[\wavepad]),
    Pfindur(32, ~patterns[\wavepad]),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\snare],
        ~patterns[\wavepad],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\wavepad],
    ])),
    Pfindur(16, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\metal],
        ~patterns[\bass],
    ])),
    Pfindur(16, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
    ])),
    Pfindur(16, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
        ~patterns[\wavepad],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\hh],
        ~patterns[\metal],
        ~patterns[\metalhi],
        ~patterns[\pad],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
        ~patterns[\pad],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\pad3],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\metal],
    ])),
    Pfindur(8, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\pad3],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\metal],
    ])),
    Pfindur(8, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
        ~patterns[\pad2],
    ])),
    Pfindur(8, Ppar([
        ~patterns[\hh],
        ~patterns[\snare],
        ~patterns[\pad],
        ~patterns[\pad2],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
        ~patterns[\pad],
        ~patterns[\pad2],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\pad3],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\metal],
    ])),
    Pfindur(8, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\kick],
        ~patterns[\snare],
        ~patterns[\metal],
        ~patterns[\bass],
        ~patterns[\metalhi],
        ~patterns[\wavepad],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\pad3],
    ])),
    Pfindur(4, Ppar([
        ~patterns[\hh],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\hh],
        ~patterns[\wavepad],
    ])),
    Pfindur(32, Ppar([
        ~patterns[\wavepad],
    ])),
]).play(tempo);

)

Server.default.stopRecording;