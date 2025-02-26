s.boot;
s.quit;

(

SynthDef.new(\pad, {
	|chord, atk=0.1, rel=1, amp=0.2, out|

	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var mod = SinOsc.kr(chord / 2, mul:0.25);

	var car = Mix.ar([
		RLPF.ar(
			Blip.ar(chord * mod, Line.kr(0, 100, rel)),
			chord * 5),
		LPF.ar(Blip.ar(chord), chord * 10)
	]) * amp * env;
	Out.ar(out, car.tanh!2);
}).add;

SynthDef.new(\arp, {
	|freq=440, atk=0.1, rel=1, amp=0.2, q, pan, out|

	var env = EnvGen.kr(
		Env.perc(atk, rel, curve:1),
		doneAction:2);

	var car = Mix.ar(
		Resonz.ar(
		   Blip.ar(freq, Line.kr(0, 50, rel), mul:amp),
			[freq/2, freq, freq*2],
			1/q)) * 1/3;

	car = Pan2.ar(car, pan);

	Out.ar(out, car.tanh!2);
}).add;

SynthDef.new(\glitch, {
	|freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0, out|
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
	var car = RLPF.ar(
		Pulse.ar(freq * cRatio + mod, mul:amp),
		XLine.kr(freq * 10, freq * 30, rel)) * env;
	car = Pan2.ar(car, pan);
	Out.ar(out, Clip.ar(car));
}).add;

SynthDef.new(\kick, {
	|out, freq=50, atk=0.005, dec=0.2, amp=1|
	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
		doneAction:2);
	var kickFm = SinOsc.ar(freq * env, phase:pi/2) + Dust.ar(10, mul:0.05) * env;
	Out.ar(out, Clip.ar(kickFm!2) * amp);
}).add;

SynthDef.new(\hh, {
	|out, tone=40, atk=0.005, dec=0.05, amp=0.25|
	var env = EnvGen.kr(
		Env.new([0, 1, 0], [atk, dec], curve:[-6, -6]),
		doneAction:2);

	// Make a square wave
	var pulses = all {:Pulse.ar(tone * m), m <- [1, 2.17, 3.31, 4.16, 5.43, 6.79, 8.12] };
	var hh2 = BPF.ar(pulses.sum, 10000, 1/10);
	hh2 = HPF.ar(hh2, 5000);

	hh2 = hh2 * env;
	Out.ar(out, Clip.ar(hh2!2) * amp);
}).add;


SynthDef.new(\wiggle, {
	|out, atk=0.005, dec=0.05, cFreq=440, wiggleFactor=0, amp=0.25|

	var fmEnv = EnvGen.kr(
		Env.perc(atk, dec, curve:[2, 2]),
		doneAction:2);
	var mod = SinOsc.kr(cFreq * (0.84 + wiggleFactor));

	var fm = SinOsc.ar(cFreq * mod, mul:amp) * fmEnv;
	Out.ar(out, fm.tanh!2);
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

SynthDef.new(\metal, {
	|freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, room=0.5, damp=0.5, out|
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
	var car = RLPF.ar(
		Pulse.ar(freq * cRatio + mod, mul:amp),
		XLine.kr(freq * 10, freq * 30, rel))!2;
	var reverbed = FreeVerb2.ar(
            car[0], // Left channel
            car[1], // Right Channel
		0.75, room, damp, amp) * env;
	Out.ar(out, reverbed.tanh) ;
}).add;

)

(

var pKick, pHh, pSnare,
    pWiggle, pGlitch, pMetal,
    pPad, pArp;

~ts = 2/3;

pKick = {
    |repeats|
	Pbind(
		\instrument, \kick,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/8,
		\freq, 75,
		\amp, Pseq([
			Peseq(5, 32, on: 0.75, off: { if(1.0.rand < 0.1, 0.25, 0) }, repeats:1),
			Peseq(4, 32, on: 0.75, off: { if(1.0.rand < 0.1, 0.25, 0) }, repeats:1)
		], repeats)
	);
};

pHh = {
    |repeats|
	Pbind(
		\instrument, \hh,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/8,
		\amp, Pseq([
			Peseq(12, 64, on: 0.6, off: { if(1.0.rand < 0.45, 0.05, 0) }, repeats:1),
			Peseq(11, 64, on: 0.6, off: { if(1.0.rand < 0.45, 0.05, 0) }, repeats:1)
		], repeats)
	);
};

pSnare = {
    |repeats|
	Pbind(
		\instrument, \snare,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/8,
		\atk, 0.001,
	    \amp, Pseq([
			Peseq(1, 8, on: 0.1, offset:4, repeats:3),
			Peseq(2, 8, on: 0.1, offset:6, repeats:1),
		], repeats),
	);
};

pWiggle = {
    |repeats|
    Pbind(
		\instrument, \wiggle,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/8,
		\wiggleFactor, Pwhite(0, 0.02),
		\cFreq, 880,
		\atk, 0.001,
		\dec, Pexprand(0.03, 0.05),
		\amp, Peseq(
			k:3,
			n:16,
			on: 0.035,
			off: { if(1.0.rand < 0.25, 0.0025, 0) },
			offset:0,
			repeats:repeats)
	);
};

pGlitch = {
	|repeats|
	Pbind(
		\instrument, \glitch,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/32,
		\freq, 440,
		\index, Pwhite(1, 20),
		\amp, Peseq(5, 32, on: 0.01, off: { if(1.0.rand < 0.35, 0.0075, 0) }, repeats:repeats),
		\atk, 0.001,
		\rel, Pexprand(0.001, 0.01),
		\pan, Pwhite(-1.0, 1.0));
};

pMetal = {
    |repeats|
	Pbind(
		\instrument, \metal,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/8,
        \freq, 300,
	    \atk, 0.001,
		\amp, Pseq([
		  Peseq(1, 8, on: 0.5, offset:4, repeats:1),
		  Peseq(1, 8, on: 0.5, offset:6, repeats:1),
	    ], repeats),
	    \rel, 0.1
	);
};

pPad = {
    |repeats|
	Pbind(
		\instrument, \pad,
		\out, 0,
		\stretch, ~ts,
		\dur, 16,
		\chord, Pwalk(
			[
				[
					220 * Scale.lydian.ratios[0],
					220 * Scale.lydian.ratios[2],
					220 * Scale.lydian.ratios[5],
					440 * Scale.lydian.ratios[3]
				],
				[
					110 * Scale.lydian.ratios[4],
					220 * Scale.lydian.ratios[2],
					220 * Scale.lydian.ratios[5],
					220 * Scale.lydian.ratios[6]
				],
				[
					110 * Scale.lydian.ratios[5],
					220 * Scale.lydian.ratios[2],
					440 * Scale.lydian.ratios[3],
					440 * Scale.lydian.ratios[6]
				],
			],
			Prand([1, -1], repeats),
			1
		),
		\amp, 0.015,
		\atk, Pexprand(1, 3),
		\rel, Pkey(\dur, repeats) / 2
	);
};

pArp = {
	|repeats|
	Pbind(
		\instrument, \arp,
		\out, 0,
		\stretch, ~ts,
		\dur, 1/8,
		\freq, Pwalk(
			[
				110 * Scale.lydian.ratios[4],
				110 * Scale.lydian.ratios[5],
				220 * Scale.lydian.ratios[0],
				220 * Scale.lydian.ratios[2],
				220 * Scale.lydian.ratios[3],
				220 * Scale.lydian.ratios[5],
				220 * Scale.lydian.ratios[6],
				440 * Scale.lydian.ratios[3],
				440 * Scale.lydian.ratios[6]
			],
			Prand([2, -1], inf),
			Prand([1, -1], inf)
		),
		\amp, Pseq([
			Peseq(3, 8, on: 0.1, off: { if(1.0.rand < 0.5, 0.05, 0) }, offset:0, repeats:3),
			Peseq(5, 8, on: 0.1, offset:2, repeats:1),
		], repeats),
		\atk, 0.01,
		\rel, 0.05,
		\q, Pexprand(1, 50),
		\pan, Pwhite(-1.0, 1.0)
	);
};

~pT = Ppar([
	pKick.value(inf),
	pHh.value(inf),
	pSnare.value(inf),
	pGlitch.value(inf),
	pMetal.value(inf),
	pWiggle.value(inf),
	pPad.value(inf),
	pArp.value(inf),
]);

p = Pseq([
	Ppar([
		pKick.value(2),
		pHh.value(1),
		pSnare.value(4),
		pGlitch.value(16),
	]),
	pWiggle.value(1),
	Ppar([
		pKick.value(2),
		pHh.value(1),
		pSnare.value(4),
		pGlitch.value(16),
		pWiggle.value(8),
	]),
	Ppar([
		pKick.value(2 * 4),
		pHh.value(1 * 4),
		pSnare.value(4 * 4),
		pGlitch.value(16 * 4),
		pWiggle.value(8 * 4),
		pPad.value(4),
	]),
	pMetal.value(1),
	Ppar([
		pKick.value(2 * 2),
		pHh.value(1 * 2),
		pSnare.value(4 * 2),
		pMetal.value(8 * 2),
		pGlitch.value(16 * 2),
		pWiggle.value(8 * 2 + 1),
		pArp.value(4 * 2)
	]),
	Ppar([
		pKick.value(2 * 4),
		pHh.value(1 * 4),
		pSnare.value(4 * 4),
		pMetal.value(8 * 4),
		pGlitch.value(16 * 4),
		pWiggle.value(8 * 4),
		pArp.value(4 * 4),
		pPad.value(4),
	]),
	Ppar([
		pKick.value(2 * 4),
		pHh.value(1 * 4),
		pSnare.value(4 * 4),
		pGlitch.value(16 * 4),
		pWiggle.value(8 * 4),
		pArp.value(4 * 3),
		pPad.value(4),
	]),
	Ppar([
		pKick.value(2 * 1),
		pHh.value(1 * 1),
		pSnare.value(4 * 1),
		pGlitch.value(16 * 1),
		pWiggle.value(8 * 1 + 1),
	]),
]).play;
)

p.stop;