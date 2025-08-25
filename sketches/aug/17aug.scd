(
SynthDef(\strangeFMDrone, {
	arg out=0, freq=60, amp=0.3, gate=1;

	var sig, env, freqs, amps, phases;
    var ctlMatrix, modMatrix;
	var wobble1, wobble2, wobble3;
	var chorus, delay, filter;
    var phi;

    phi = (1 + sqrt(5)) / 2;

	// Create some unstable frequency relationships
	freqs = [
		freq,
		freq * phi,
        freq * (2*phi),
        freq * (4*phi),
		freq * (phi * 3/2),
		freq * (phi/4)
	];

	// Slowly evolving amplitude envelopes for each operator
	amps = [
		LFNoise1.kr(0.1, 0.3, 0.7),     // slow drift
		LFNoise1.kr(0.07, 0.2, 0.4),    // slower drift
		LFNoise1.kr(0.13, 0.15, 0.3),   // medium drift
		LFNoise1.kr(0.05, 0.1, 0.2),    // very slow
		LFNoise1.kr(0.17, 0.08, 0.15),  // faster drift
		LFNoise1.kr(0.03, 0.05, 0.1)    // glacial
	];

	// Micro-detuning and phase modulation
	wobble1 = LFNoise2.kr(0.23, 0.02, 1); // subtle pitch wobble
	wobble2 = LFNoise2.kr(0.31, 0.01, 1); // even subtler
	wobble3 = SinOsc.kr(0.11, 0, 0.005, 1); // very slow sine wave detune

	// Apply wobbles to frequencies
	freqs = freqs * wobble1 * wobble2 * wobble3;

	// Strange phase relationships
	phases = [0, 1, 2, 3, 4, 5].collect({
        arg i;
        i * sqrt(5);
    });

	// Control matrix: [freq, phase, amp] for each of 6 operators
	ctlMatrix = [
		[freqs[0] * wobble1, phases[0], amps[0]],
		[freqs[1] * wobble2, phases[1], amps[1]],
		[freqs[2] * wobble3, phases[2], amps[2]],
		[freqs[3] * wobble1, phases[3], amps[3]],
		[freqs[4] * wobble2, phases[4], amps[4]],
		[freqs[5] * wobble3, phases[5], amps[5]]
	];

	// Modulation matrix: how much each oscillator modulates others' phases
	modMatrix = [
		[0, 0, 0, 0, 0, 0],  // osc 0 phase modulated by: nothing
		[LFNoise1.kr(0.08, 2, 3), 0, 0, 0, 0, 0],  // osc 1 modulated by osc 0
		[0, LFNoise1.kr(0.12, 1.5, 2), 0, 0, 0, 0],  // osc 2 modulated by osc 1
		[LFNoise1.kr(0.06, 1, 2), 0, LFNoise1.kr(0.15, 0.5, 1), 0, 0, 0],  // osc 3 mod by 0,2
		[0, 0, 0, LFNoise1.kr(0.09, 1.5, 2.5), 0, 0],  // osc 4 modulated by osc 3
		[LFNoise1.kr(0.04, 0.5, 1), LFNoise1.kr(0.11, 0.3, 0.7), 0, 0, LFNoise1.kr(0.13, 0.8, 1.5), 0]  // osc 5 mod by 0,1,4
	];

	// Generate FM7 and mix some channels
	sig = FM7.ar(ctlMatrix, modMatrix);

	// Add some chorus-like effect
    chorus = sig + DelayC.ar(sig, 0.02, LFNoise2.kr(0.5, 0.008, 0.012)) * 0.3;

	// Resonant filter sweep
	filter = RLPF.ar(
		chorus,
		LFNoise1.kr(0.07, 800, 1200),  // slowly wandering cutoff
		LFNoise0.kr(0.05, 0.3, 0.6)    // slowly changing resonance
	);

	// Another layer of filtering for strangeness
	filter = BPF.ar(filter, freq * 4, LFNoise1.kr(0.03, 0.5, 1.5)) * 0.4 + filter;

	// Add some delayed feedback
	delay = DelayC.ar(filter, 0.3, LFNoise2.kr(0.02, 0.1, 0.2));
	filter = filter + (delay * 0.15);

	// Envelope and final processing
	env = EnvGen.kr(Env.asr(4, 1, 8), gate, doneAction: 2);
	sig = filter * env * amp;

	// Stereo spread with different delays
	sig = [
		DelayC.ar(sig, 0.01, LFNoise2.kr(0.7, 0.003, 0.005)),
		DelayC.ar(sig, 0.01, LFNoise2.kr(0.9, 0.003, 0.005))
	];

	Out.ar(out, sig);
}).add;


x.release;
x = Synth(\strangeFMDrone, [\freq, 50, \amp, 1/3]);
)
