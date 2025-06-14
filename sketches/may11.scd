s.boot;
s.quit;

Server.default.options.outDevice_("blackhole+phones");

(

~fm7SynthNames = 32.collect{|algoNum| "fm7algo%".format(algoNum).asSymbol};

~fm7SynthNames.do{|synthName, algo|
	SynthDef(synthName, {|out=0, dur=0.01, sustain=0, freqScale=0.5, spread=0.25, pan=0, feedback=1.0, amp=0.5|
		var env = Env.perc.kr(gate:1, timeScale: dur * (1+sustain), doneAction: Done.freeSelf);
		var ctls =
		[
			// freq, phase, amp
			[freqScale * 300, pi.rand, 1],
			[freqScale * 2500, pi.rand, 1],
			[freqScale * SinOsc.ar(Rand(0.001, 0.01)).exprange(1000, 10000), 0, 1],
			[freqScale * LFNoise2.ar(10).exprange(2000, 0.1), 0, 1],
			[freqScale * ExpRand(30, 1500), pi.rand, 1],
			[freqScale * ExpRand(30, 2500), pi.rand, 1]
		];

		var sig = FM7.arAlgo(algo, ctls , feedback * 2.0);
		sig = Splay.ar(sig, spread: spread, center: pan);
		sig = sig * env * amp;

		Out.ar(out, sig);
	}).add;
};

SynthDef.new(\tube, {
    var sig, env, freq;
    freq = \freq.kr(440.0);
    sig = TwoTube.ar(
        DiodeRingMod.ar(
            SinOsc.ar(freq * LFNoise0.ar(\modnoise.kr(100))),
        Saw.ar(LFNoise0.kr(\modnoise.kr(100)))),
        \k.kr(0.01),
        \loss.kr(1.0),
        \d1Length.kr(100),
        \d2Length.kr(100));
    env = EnvGen.kr(
        Env.perc(\atk.kr(0.1), \rel.kr(1)),
        doneAction:2);

    sig = HPF.ar(sig, freq * 8);
    sig = LPF.ar(sig, freq * 4);
    //sig = Streson.ar(sig, \delayTime.kr(0.003), \res.kr(0.9));
    //sig = MembraneHexagon.ar(sig, \tension.kr(0.5), \loss2.kr(0.99999));

    sig = sig * env * \amp.kr(0.1);
    sig = sig.softclip;

    Out.ar(\out.kr(0), sig!2);
}).add;

SynthDef.new(\spring, {
    var sig, env, freq;
    freq = \freq.kr(440.0);
    sig = SinOsc.ar(freq);
    sig = Spring.ar(sig, \spring.kr(1), \damp.kr(0));
    env = EnvGen.kr(
        Env.perc(\atk.kr(0.1), \rel.kr(1)),
        doneAction:2);

    sig = MembraneHexagon.ar(sig, \tension.kr(0.5), \loss.kr(0.99999));

    sig = sig * env * \amp.kr(0.1);
    sig = sig.softclip;

    Out.ar(\out.kr(0), sig!2);
}).add;

SynthDef.new(\reverb, {
    arg in, out,
    mix = 1, room = 0.99, damp = 0.25,
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

(

~rbus = Bus.audio(s, 2);
~patTube = Pbind(
    \instrument, \tube,
    \dur, 4,
    \amp, 0.1,
    \atk, Pkey(\dur) * 1/16,
    \d1Length, Pexprand(1, 5),
    \d2Length, Pexprand(1, 5),
    \rel, Pkey(\dur) * 2,
    \modnoise, 10000,
    \delayTime, Pwhite(0.00001, 0.001),
    \res, 0.1,
    \out, ~rbus
);

~pat = Pbind(
    \instrument, \spring,
    \dur, Pn(Plazy({Pseq([1/4, 1/8, 1/16, 1/7, 3/7, 1/7].sputter(0.5, 16))})),
    \amp, 2,
    \atk, Pkey(\dur) * 1/16,
    \rel, Pkey(\dur) * Pexprand(1/8, 2),
    \modnoise, 1,
    \delayTime, Pwhite(0.00001, 0.001),
    \res, Pwhite(0.0, 0.9),
    \scale, Scale.phrygian,
    \degrees, Pfuncn({Scale.phrygian.degrees.choose}, inf),
    \out, ~rbus
);

~patfm = Pbind(
	\instrument, Pshuf(~fm7SynthNames, inf).trace,
    \dur, 1/8,
	\sustain, Pwhite(0.0, 1.0),
	\feedback, Pshuf(Array.rand(8, 0.25, 1.0), inf),
	\freqScale, Pxrand(Array.rand(8, 0.25,4.0), inf),
    \amp, Peseq(5, 16, on:0.01, repeats:inf),
	\spread, Pwhite(0.0, 1.0),
	\pan, Pwhite(-1.0, 1.0)
);

~pat = Pfindur(16, Ppar([~pat, ~patTube, ~patfm]));
//~patTube = Pfindur(16, ~patTube);
)

(
var tempo = TempoClock.new(90/60);

~p = Pn(Plazy({ ~pat }), inf);
~p = Pfx(
    ~p,
    \reverb,
    \in, ~rbus,
    \out, 0,
    \mix, 0.25,
    \amp, 1,
    \damp, 0.99);

~p.play(tempo);

)
