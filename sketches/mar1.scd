Server.default.options.outDevice_("External Headphones");


s.boot;
s.quit;

(

SynthDef.new(\glitch, {
	|out, freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0|
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
	var car = RLPF.ar(
		Pulse.ar(freq * cRatio + mod, mul:amp),
		XLine.kr(freq * 10, freq * 30, rel)) * env;
	car = Pan2.ar(car, pan);
	Out.ar(out, Clip.ar(car));
}).add;

SynthDef.new(\karplus, {
	|out, freq=500, atk=0.1, rel=1, amp=0.2, decayTime=0.5, coef=0.5|
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var kp = Pluck.ar(
		PinkNoise.ar,
		Dust.ar(1, mul:2, add:-1),
		maxdelaytime:0.5,
		delaytime:(freq.reciprocal),
		decaytime:decayTime,
		coef:coef
	) * amp * env;
	Out.ar(out, kp.softclip!2);
}).add;


SynthDef.new(\pad, {
	|out, freq=500, atk=0.1, rel=1, amp=0.2, rq=0.1s|
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var pad = Mix.ar(
		Resonz.ar(
			Pulse.ar(freq),
			freq,
			rq)
	) * env * amp;
	Out.ar(out, pad.softclip!2);
}).add;

SynthDef.new(\noise, {
	|out, freq=500, atk=0.1, rel=0.1, amp=0.2, decayTime=0.5, coef=0.5|
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var noise = PinkNoise.ar * amp;
	Out.ar(out, noise.softclip!2);
}).add;

SynthDef.new(\kick, {
	|out, freq=50, atk=0.005, rel=0.2, amp=1|
	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, rel], curve:[-6, -6]),
		doneAction:2);
	var kickFm = SinOsc.ar(freq * env, phase:pi/2) * env;
	Out.ar(out, Clip.ar(kickFm!2) * amp);
}).add;

SynthDef.new(\snare, {
	|out, atk=0.005, rel=0.05, tone=880, amp=0.25|
	var noiseEnv = EnvGen.kr(
		Env.new([0, 1, 0], [atk, rel * 1.5], curve:[-10, -6]),
		doneAction:2);

	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, rel], curve:[-10, -6]),
		doneAction:2);

	var hitFm = SinOsc.ar(tone * env, mul:amp) * env;
	var noise = WhiteNoise.ar(mul:amp/2) * noiseEnv;
	var mixed = Mix.ar([hitFm, noise]);

	Out.ar(out, mixed.tanh!2);
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

)

(

var pGlitchClick, pGlitchKick, pNoise, pSnare, pKick,
    pBass,
    tempo;

tempo = TempoClock.new(150/60);

pGlitchClick = {
	|repeats|
	Pbind(
		\instrument, \glitch,
		\out, 0,
		\dur, 1/8,
		\freq, 440,
		\index, Pwhite(1, 5),
		\amp, 0.25 * Peseq(
			4, 16,
			off:{ [0.25, 0].wchoose([0.75, 0.25]) },
			repeats:repeats),
		\atk, 0.001,
		\rel, 0.01 * Peseq(
			1, 8,
			off:{ [0.5, 0].wchoose([0.1, 0.9]) },
			repeats:repeats))
};

pGlitchKick = {
	|repeats|
	Pbind(
		\instrument, \glitch,
		\out, 0,
		\dur, 1/8,
		\freq, 55,
		\index, Pwhite(15, 20),
		\amp, 0.5 * Peseq(
			3, 16,
			off:{ [0.25, 0].wchoose([0.1, 0.9]) },
			repeats:repeats,
			offset:4
		),
		\atk, 0.001,
		\rel, 0.05)
};

pNoise = {
	|repeats|
	Pbind(
		\instrument, \noise,
		\out, 0,
		\dur, 1/8,
		\amp, 0.1 * Peseq(
			1, 16,
			off:{ [0.5, 0].wchoose([0.1, 0.9]) },
			offset:6,
			repeats:repeats),
		\atk, 0.001,
		\rel, Pexprand(0.01, 0.05));
};

pSnare = {
	|repeats|
	Pbind(
		\instrument, \snare,
		\out, 0,
		\dur, 1/8,
		\amp, 0.09 * Peseq(
			2, 16,
			offset:4,
			repeats:repeats)
	);
};

pKick = {
	|repeats|
	Pbind(
		\instrument, \kick,
		\out, 0,
		\dur, 1/8,
		\freq, 75,
		\amp, 0.5 * (
			Peseq(
				1, 16,
				repeats:repeats,
			) + Peseq(
				1, 16,
				repeats:repeats,
				offset:5
		    )
		)
	);
};

pBass = {
	|repeats|
	Pbind(
		\instrument, \bass,
		\out, 0,
		\dur, 1/4,
		// D#4 in midi.
		\freq, Prand([48.midicps, 51.midicps, 46.midicps], repeats:repeats),
	    \atk, 0.001,
		\amp, 0.05,
	    \rel, 0.1,
		\fRel, Ptime().collect({ |x| ((x * 0.1).sin + 1) / 2 }).trace,
		\width, Ptime().collect({ |x| ((x * 0.1).sin + 1) / 1.9 }).trace,
		\rq, 1/5
	);
};

~pT = Ppar([
	pGlitchClick.value(inf),
	pGlitchKick.value(inf),
	pNoise.value(inf),
	pSnare.value(inf),
	pKick.value(inf)
]).play(tempo);

)