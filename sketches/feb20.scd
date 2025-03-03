s.boot;
s.quit;

(
SynthDef.new(\fm, {
	arg freq=500, mRatio=1, cRatio=1, index=1, atk=0.1, rel=1, amp=0.2, pan=0, bus;
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var mod = SinOsc.ar(freq, mul:freq * mRatio * index);
	var car = RLPF.ar(SinOsc.ar(freq * cRatio + mod, mul:amp), XLine.kr(freq * 10, freq * 5, rel)) * env;
	car = Pan2.ar(car, pan);
	Out.ar(bus, Clip.ar(car));
}).add;

SynthDef.new(\kick, {
	|out, atk = 0.01, dec = 0.03, sus = 0.05, rel = 0.1, freq=30|
	var env = EnvGen.kr(Env.adsr(atk, rel, curve:3), doneAction:2);
	var env2 = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var kickFm = SinOsc.ar(freq * env, phase:1) * env2;
	Out.ar(out, Clip.ar(kickFm * 0.5!2));
}).add;

// FreeVerb2 - demo synthdef
SynthDef(\FreeVerb2x2, { |out, inbus, mix = 1, room = 1, damp = 0.25, amp = 1.0, dustDensity|
    var signal = In.ar(inbus, 2);
	var reverbed = FreeVerb2.ar( // FreeVerb2 - true stereo UGen
            signal[0], // Left channel
            signal[1], // Right Channel
		mix, room, damp, amp);
	Out.ar(out, reverbed); // same params as FreeVerb 1 chn version
}).add;
)

// TODO: add reverb with dust


(
~fmBus = Bus.audio(s, 2);

p = Ppar(
	[
		Pbind(
			\instrument, \fm,
			\bus, ~fmBus,
			\dur, Prand([1, 2, 4, 8, 16].reciprocal, inf),
			\freq, Prand(220 * Scale.phrygian.ratios, inf).trace,
			\index, Pexprand(1, 10),
			\amp, Pexprand(0.01, 0.05),
			\atk, Pexprand(0.01, 0.05),
			\rel, Pkey(\dur, inf).reciprocal,
			\pan, Pwhite(-1.0, 1.0))
	],
	inf).play;

z = Synth(
	\FreeVerb2x2,
	[
		\out, 0,
		\inbus, ~fmBus,
	],
	addAction:\addToTail
);


)

p.stop;
z.stop;