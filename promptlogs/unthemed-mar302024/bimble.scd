Server.default.options.outDevice_("blackhole+phones");

s.boot;
s.quit;

Server.default.record;
Server.default.stopRecording;

(

SynthDef.new(\pad, {
    arg atk, dec, slev, rel, gate=1, amp,
        freq, out;

    var sig, env;

	env = EnvGen.kr(
        Env.adsr(atk, dec, slev, rel),
        gate,
        doneAction:2);

	sig = Mix.ar([
		RLPF.ar(
			Blip.ar(freq, numharm:Line.kr(0, 200, rel)),
			freq * 25),
		LPF.ar(Blip.ar(freq, numharm:Line.kr(300, 0, rel)), freq * 2.5)
	]) * amp;

    sig = Mix.ar([
        sig * 3/4,
        Resonz.ar(
            Gendy1.ar(
                ampdist:2,
                durdist:5,
                minfreq:freq,
                maxfreq:freq),
            [freq/4, freq/2, freq, freq*2],
            Line.kr(0.01, 25, rel)) * 0.025,
        LFPar.ar(freq*2) * 0.01
    ]) * env * 0.75;
	Out.ar(out, sig.tanh!2);
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

SynthDef.new(\drippad, {
    arg atk=0.1, rel=1, amp=0.2,
        freq, out=0;

    var sig, env, mod;

    env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
    mod = SinOsc.kr(freq / 2, mul:0.25);
    sig = Mix.ar([
        RLPF.ar(
            Blip.ar(freq, numharm:50 ),
            freq * 5),
        LPF.ar(Blip.ar(freq), freq * 10)
    ]);
    sig = sig!2 * amp * env;

    Out.ar(out, sig.softclip);
}).add;

SynthDef.new(\reverb, {
    arg in, out,
        mix = 1, room = 0.75, damp = 0.25,
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

Scale.phrygian.degrees;
Scale.chromatic;

(
var rbus, rev;

~patterns = Dictionary.new;

// Data patterns

// -- Harmonic Context
~patterns[\harmctxbase] = Pbind(
    \type, \rest,
    \dur, 16,
    \scale, Scale.chromatic,
    \ctranspose, 1,
    \baseDegreeSpace, [0, 4, 7, 10],
    \transposeMatrix, [
            [0, 0, 0, 0],
            [0, 1, 2, 2],
            [0, 0, 0, 0],
            [2, 2, 2, 4]
]);

~patterns[\harmctx] = ~patterns[\harmctxbase].collect({ arg ev; ~harmctx = ev });

~patterns[\degreegenerator] = Pbindf(
    ~patterns[\harmctxbase],
    \degreeSpace, Prout({
        var currMatrix, nextMatrix,
            thisSpace, nextSpace,
            currentlyPlaying,
            pos;

        thisSpace = 0;
        nextSpace = 1;
        pos = 0;

        loop {
            if (currentlyPlaying == nil, {
                currentlyPlaying = ~harmctx[\transposeMatrix][thisSpace].copy;
            });

            (currentlyPlaying + ~harmctx[\baseDegreeSpace]).yield;

            currMatrix = ~harmctx[\transposeMatrix][thisSpace];
            nextMatrix = ~harmctx[\transposeMatrix][nextSpace];

            currentlyPlaying[pos] = currentlyPlaying[pos] + nextMatrix[pos];

            pos = pos + 1;
            if (pos >= nextMatrix.size, {
                thisSpace = (thisSpace + 1) % ~harmctx[\transposeMatrix].size;
                nextSpace = (nextSpace + 1) % ~harmctx[\transposeMatrix].size;
                pos = 0;
                currentlyPlaying = ~harmctx[\transposeMatrix][thisSpace].copy;
            });
        };
    }).trace;
).collect({ arg ev; ~degctx = ev });

// Musical patterns

// -- Harmonic components
rbus = Bus.audio(s, 2);
rev = Synth.new(
    \reverb,
    [
        \in, rbus,
        \out, 0,
        \amp, 0.75
    ]);

~patterns[\padbrass] = Pbind(
    \instrument, Prand([\wavepad, \drippad], inf),
    \dur, Pseq([2, 8, 4, Prand([2, 4])], inf),
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \octave, 4,
    \degree, Prout({
        var currNote = 0;
        loop {
            ~degctx[\degreeSpace][currNote].yield;
            currNote = (currNote + 1) % ~degctx[\degreeSpace].size;
        };
    }),
    \atk, Pkey(\dur) * 1/4,
    \legato, 0.1,
    \rel, Pkey(\dur) * 5/4,
    \out, rbus,
    \amp, -20.dbamp
);

~patterns[\brass] = Pbind(
    \instrument, \pad,
    \dur, Pseq([1/4, 1/2, 1/8, 3/8], inf),
    #[scale, ctranspose], Pfuncn({ [~harmctx[\scale], ~harmctx[\ctranspose]] }, inf),
    \octave, Prand([3, 4], inf),
    \degree, Prout({
        var currNote = 0;
        loop {
            ~degctx[\degreeSpace][currNote].yield;
            currNote = (currNote + 1) % ~degctx[\degreeSpace].size;
        };
    }),
    \atk, Pkey(\dur) * 1/4,
    \legato, 0.75,
    \rel, 0,
    \out, rbus,
    \amp, -75.dbamp
);

)


(

~tempo = TempoClock.new(140/60);
Pn(Plazy({ ~patterns[\harmctx] }), inf).play(~tempo, quant: Quant(timingOffset:0.1));
Pn(Plazy({ ~patterns[\degreegenerator] }), inf).play(~tempo, quant: Quant(timingOffset:0.05));

//Pn(Plazy({ ~patterns[\bass] }), inf).play(~tempo);
//Pn(Plazy({ ~patterns[\pad] }), inf).play(~tempo);
Pn(Plazy({ ~patterns[\padbrass] }), inf).play(~tempo);

)