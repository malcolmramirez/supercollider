(

SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(\atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(Done.freeSelf);
    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
}).add;


// Synthdefs
SynthDef.new(\pad, {
    var env = Env.perc(\atk.kr(0.1), \rel.kr(1)).kr(Done.freeSelf);

    var ampOsc = (SinOsc.kr(0.01) + 1) * \amp.kr(0.2);
	var car = Mix.ar(
		RLPF.ar(
			Pulse.ar(\freq.kr, SinOsc.ar(5) * 0.15 + 0.5),
			Line.ar(\freq.kr * 5, \freq.kr * 50, \rel.kr(1)))
	) * ampOsc * env;
	car = car.tanh;

	Out.ar(\out.kr(0), Clip.ar(car!2));
}).add;

SynthDef.new(\hip, {
    var sig;
    sig = In.ar(\in.kr, 2);
    sig = HPF.ar(sig, \hpf.kr(2500));
    Out.ar(\out.kr(0), sig);
}).add;


SynthDef.new(\kick, {
    var sig, modsig, env, freqEnv;

    env = Env.perc(\atk.kr(0.001), \rel.kr(0.25), curve: -2).ar(Done.freeSelf);
    modsig = Saw.ar(\mod.kr(50)) / 4 + 1;

    sig = SinOsc.ar(\freq.kr(100) * (env * \punch.kr(1.2)) * modsig);

    sig = sig * env * \amp.kr(4.dbamp);
    sig = sig!2;

    Out.ar(\out.kr(0), sig);
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
    Out.ar(out, acid!2);
}).add;
)