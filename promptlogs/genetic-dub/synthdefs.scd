(
SynthDef(\kd, {
    arg out = 0, amp = 0.75, freq = 80, decay = 0.4, punch = 1.5,
        filterFreq = 100, filterDecay = 0.15;

    var sig, env, filterEnv, pitchEnv, dist;

    pitchEnv = EnvGen.kr(Env([freq * punch, freq], [0.1], \exp));

    env = EnvGen.kr(Env.perc(0.01, decay, amp), doneAction: 2);

    filterEnv = EnvGen.kr(Env.perc(0.01, filterDecay, 1));

    sig = SinOsc.ar(pitchEnv) + (SinOsc.ar(pitchEnv * 1/sqrt(5)) * 0.5);
    sig = sig + SinOsc.ar(pitchEnv * 0.5, 0, 0.3);
    sig = (sig * Rand(1.0, 1.5)).tanh;
    sig = LPF.ar(sig, filterFreq + (filterEnv * filterFreq * 2));
    sig = sig * env;

    Out.ar(out, sig ! 2);
}).add;

SynthDef(\hh, {
    arg out = 0, amp = 0.4, decay = 0.03, filterFreq = 1000, filterRes = 0.1, reverb = 0.1;

    var sig, env, filterEnv;

    env = EnvGen.kr(Env.perc(0.001, \decay.kr, amp), doneAction: 2);
    filterEnv = EnvGen.kr(Env.perc(0.001, decay * 0.3, 1));

    sig = Mix.ar([WhiteNoise.ar, PinkNoise.ar, BrownNoise.ar]) * 1/12;
    sig = sig + FreeVerb.ar(sig, \reverb.kr(0.1), 0.5, 0.1);
    sig = sig * env;

    Out.ar(out, sig ! 2);
}).add;

SynthDef(\pc, {
    var sig, env, clickEnv, filterEnv;

    env = EnvGen.kr(Env.perc(0.001, \decay.kr(0.1), \amp.kr(0.5)), doneAction: 2);
    filterEnv = EnvGen.kr(Env.perc(0.001, 0.05, 1));
    clickEnv = EnvGen.kr(Env.perc(0.001, 0.01, \click.kr(1)));

    sig = BPF.ar(WhiteNoise.ar, \freq.kr(1750), 0.3);
    sig = sig + (Impulse.ar(0) * clickEnv); // Add transient click
    sig = LPF.ar(sig, \filterSweep.kr(5000) + (filterEnv * \filterSweep.kr(5000)));
    sig = (sig * 2).softclip * 0.7;
    sig = sig + FreeVerb.ar(sig, \reverb.kr(0.15), 0.6, 0.2);
    sig = sig * env;

    Out.ar(\out.kr(0), sig ! 2);
}).add;

)

(

SynthDef(\syn, {


}).play;

)
