s.boot;
s.quit;

s.scope;

// SynthDefs
(

SynthDef.new(\osc, {
	arg buf,
	    freq,
	    modRatio = 2, index = 1,
	    amp = 0.25, atk = 0.1, sus = 0.1, rel,
	    dry, wet,
	    out;

	var sig, env, mod;

	mod = Pulse.ar(freq, mul:freq * modRatio * index);

	env = EnvGen.ar(
		Env.new(
			[0, 1, 1, 0],
			[atk, sus, rel]),
		doneAction:2);
	sig = Osc.ar(buf, freq + mod) * dry;
	sig = sig + PinkNoise.ar * wet;

	// Safety processing - remove DC offset and clip.
	sig = LeakDC.ar(sig);
	sig = sig * env * amp;
	sig = sig.softclip;

	Out.ar(out, sig!2);
}).add;

SynthDef(\reverb, {
	arg input, out,
	    roomsize = 10, revtime = 0.7, damping = 0.5, inputbw = 0.5,
	    spread = 15, drylevel = 1, earlyreflevel = 0.7, taillevel = 0.5,
	    maxroomsize = 300,
	    amp = 1.0;

	var sig, reverbed;

    sig = In.ar(input, 2);
	sig = GVerb.ar(
		Mix.ar(sig),
		roomsize,
		revtime,
		damping,
		inputbw,
		spread,
		drylevel,
		earlyreflevel,
		taillevel
	);

	sig = sig * amp;
	sig = sig.softclip;

	Out.ar(out, sig);
}).add;

SynthDef.new(\kick, {
	|out, freq=50, atk=0.005, dec=0.2, amp=1|
	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
		doneAction:2);
	var kickFm = SinOsc.ar(freq * env, phase:pi/2) + Dust.ar(10, mul:0.05) * env;
	Out.ar(out, Clip.ar(kickFm!2) * amp);
}).add;

)

Scale.directory;

(

var b1, rbus, rev, wtGen, wave;

rbus = Bus.audio(s, 2);

wtGen = {
	arg buf,
	    numPoints=20, timeRange=10, curveRange=20;

	var env = Env.new(
		Array.rand(numPoints, -1.0, 1.0),
		Array.rand(numPoints, 1, timeRange),
		Array.rand(numPoints, -1 * curveRange, curveRange)
	);

	buf.loadCollection(env.asSignal(1024).asWavetable);
};

rev = Synth(
	\reverb,
	[
		\input, rbus,
		\out, 0,
		\amp, 0.75,
		\drylevel, 0,
		\damping, 0.75,
		\roomsize, 250,
		\spread, 100,
    ]);

wave = {
	arg dur, repeats, octave, interval, amp;

	var wBuf = Buffer.alloc(s, 2048);
	Pbind(
		\instrument, \osc,
		\dur, dur,
		\buf, Pfuncn( { wtGen.value(wBuf) }, repeats:repeats),
		\scale, Scale.phrygian,
		\degree, Pfuncn( { Scale.phrygian.degrees.choose }, repeats:repeats),
		\octave, octave,
		\amp, amp,
		\atk, 0.1,
		\sus, 0.1,
		\rel, Pkey(\dur, repeats:repeats) * 4/5,
		\dry, Ptime().collect({ arg t; (sin(t / interval) + 1) / 4}).trace,
		\wet, Ptime().collect({ arg t; (cos(t / interval) + 1) / 2}).trace,
		\out, rbus);
};

// Add more "waves"
~pT = Ppar(
	[
		wave.value(1/6, inf, 6, 5, 0.2),
		wave.value(1/8, inf, 5, 1, 0.25),
		wave.value(1/2, inf, 3, 3, 0.35),
    ]).play;

)
