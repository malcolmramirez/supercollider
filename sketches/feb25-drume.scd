s.boot;
s.quit;

(

SynthDef.new(\pad, {
	|chord, atk=0.1, rel=1, amp=0.2, out|

	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);

	var carMul = amp;
	var ampOsc = SinOsc.kr(0.01, mul:amp) + amp;
	var harmOsc = Dust.kr(10, mul:10);
	var car = Mix.ar(
		RLPF.ar(
			Blip.ar(chord, harmOsc),
			Line.kr(chord * 5, chord * 50, rel))
	) * ampOsc * env;
	car = car.tanh;

	Out.ar(out, Clip.ar(car!2));
}).add;


SynthDef.new(\glitch, {
	arg freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0, out, bus;
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
	var kickFm = SinOsc.ar(freq * env, phase:1) + Dust.ar(10, mul:0.05) * env;
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

)


(
TempoClock.default = TempoClock(80/60);
p = Ppar([
		/*Pbind(
			\instrument, \pad,
			\out, 0,
		    \dur, 8,
			\bus, ~revBus,
			\chord, Pseq(
				[
					[
						220 * Scale.lydian.ratios[0],
						220 * Scale.lydian.ratios[2],
						220 * Scale.lydian.ratios[5]
				    ],
					[
						110 * Scale.lydian.ratios[6],
						220 * Scale.lydian.ratios[1],
						220 * Scale.lydian.ratios[3]
				    ],
					[
						110 * Scale.lydian.ratios[5],
						220 * Scale.lydian.ratios[1],
						220 * Scale.lydian.ratios[2]
				    ],
					[
						110 * Scale.lydian.ratios[3],
						110 * Scale.lydian.ratios[5],
						220 * Scale.lydian.ratios[2]
				    ]
				],
				inf).trace,
			\index, 0,
			\amp, Pexprand(0.02, 0.02),
			\atk, Pexprand(1, 3),
			\rel, Pkey(\dur, inf) - Pwhite(0.1, 4)),*/
		Pbind(
			\instrument, \glitch,
			\out, 0,
			\dur, 1/16,
			\freq, 440,
			\index, Pwhite(1, 20),
			\amp, Peseq(5, 32, on: 0.01, off: { if(1.0.rand < 0.35, 0.005, 0) }, repeats:inf),
			\atk, Pexprand(0.01, 0.05),
			\rel, Pexprand(0.001, 0.01),
			\pan, Pwhite(-1.0, 1.0)),
		Pbind(
			\instrument, \kick,
			\out, 0,
			\dur, 1/8,
			\freq, 75,
			\amp, Peseq(3, 8, on: 0.5, off: { if(1.0.rand < 0.1, 0.025, 0) }, repeats:inf)),
		Pbind(
			\instrument, \hh,
			\out, 0,
			\dur, 1/8,
			\amp, Peseq(7, 8, on: 0.45, off: { if(1.0.rand < 0.1, 0.025, 0) }, repeats:inf)),
	],
	inf).play;
)

p.stop;
z.stop;