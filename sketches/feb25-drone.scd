s.boot;
s.quit;

(
SynthDef.new(\fm, {
	arg freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0, bus, out;
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var mod = Saw.ar(freq, mul:freq * mRatio * index);
	var car = RLPF.ar(
		SinOsc.ar(freq * cRatio + mod, mul:amp),
		XLine.kr(freq * 10, freq * 15, rel)) * env;
	car = Pan2.ar(car, pan);
	Out.ar(out, Clip.ar(car));
	Out.ar(bus, Clip.ar(car));
}).add;

SynthDef.new(\pad, {
	|chord, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, out, bus|

	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);

	var carMul = amp;
	var ampOsc = SinOsc.kr(0.01, mul:amp) + amp;
	var car = Mix.ar(
		RLPF.ar(
			Pulse.ar(chord),
			Line.kr(chord * 5, chord * 30, rel))
	) * ampOsc * env;
	car = car.tanh;

	Out.ar(bus, Clip.ar(car!2));
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

// FreeVerb2 - demo synthdef
SynthDef(\FreeVerb2x2, { |out, inbus, mix = 1, room = 1, damp = 0.25, amp = 1.0|
    var signal = In.ar(inbus, 2);
	var reverbed = FreeVerb2.ar( // FreeVerb2 - true stereo UGen
            signal[0], // Left channel
            signal[1], // Right Channel
		mix, room, damp, amp);
	Out.ar(out, reverbed.tanh);
}).add;

)


(
~revBus = Bus.audio(s, 2);

p = Ppar(
	[
		Pbind(
			\instrument, \fm,
			\out, 0,
			\bus, ~revBus,
			\dur, 1,
			\freq, Pwalk(
				220 * Scale.phrygian.ratios,
				Pseq([3, -2], inf),
				Pseq([1, -1], inf)).trace,
			\index, Pexprand(1, 10),
			\amp, Peseq(3, 16, on:0.02, repeats:inf),
			\atk, Pexprand(0.01, 0.1),
			\rel, 1,
			\pan, Pwhite(-1.0, 1.0)),
		Pbind(
			\instrument, \pad,
			\out, 0,
			\dur, 1/8,
			\bus, ~revBus,
			\chord, Pseq(
				[
					[
						220 * Scale.phrygian.ratios[0],
						220 * Scale.phrygian.ratios[2],
						220 * Scale.phrygian.ratios[5]
					],
					[
						220 * Scale.phrygian.ratios[0],
						220 * Scale.phrygian.ratios[5],
						440 * Scale.phrygian.ratios[0]
					],
					[
						220 * Scale.phrygian.ratios[2],
						220 * Scale.phrygian.ratios[5],
						440 * Scale.phrygian.ratios[2]
					],
				],
				inf).trace,
			\index, 0,
			\amp, Pexprand(0.0015, 0.002),
			\atk, Pexprand(1, 3),
			\rel, Pkey(\dur, inf) + Pwhite(0.1, 1)),
		Pbind(
			\instrument, \glitch,
			\out, 0,
			\dur, 1/4,
			\freq, 440,
			\index, Pwhite(1, 20),
			\amp, Peseq(5, 32, on: 0.01, off: { if(1.0.rand < 0.35, 0.005, 0) }, repeats:inf),
			\atk, Pexprand(0.01, 0.05),
			\rel, Pexprand(0.001, 0.01),
			\pan, Pwhite(-1.0, 1.0)),
	],
	inf).play;

z = Synth(
	\FreeVerb2x2,
	[
		\out, 0,
		\inbus, ~revBus,
	],
	addAction:\addToTail
);


)

p.stop;
z.stop;