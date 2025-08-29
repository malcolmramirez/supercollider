(
SynthDef(\kd, {
    var sig, env, filterEnv, pitchEnv, dist;

    pitchEnv = EnvGen.kr(Env([\freq.kr(80) * \punch.kr(1.5), \freq.kr(80)], [0.1], \exp));

    env = EnvGen.kr(Env.perc(0.01, \decay.kr(0.4), \amp.kr(0.75)), doneAction: 2);

    filterEnv = EnvGen.kr(Env.perc(0.01, \filterDecay.kr(0.15), 1));

    sig = SinOsc.ar(pitchEnv) + (SinOsc.ar(pitchEnv * 1/sqrt(5)) * 0.5);
    sig = sig + SinOsc.ar(pitchEnv * 0.5, 0, 0.3);
    sig = (sig * Rand(1.0, 1.5)).tanh;
    sig = LPF.ar(sig, \filterSweep.kr(100) + (filterEnv * \filterSweep.kr(100) * 2));
    sig = sig * env;

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\hh, {
    var sig, env, filterEnv;

    env = EnvGen.kr(Env.perc(0.001, \decay.kr(0.03), \amp.kr(0.4)), doneAction: 2);
    filterEnv = EnvGen.kr(Env.perc(0.001, \decay.kr(0.03) * 0.3, 1));

    sig = Mix.ar([WhiteNoise.ar, PinkNoise.ar, BrownNoise.ar]) * 1/12;
    sig = sig + FreeVerb.ar(sig, \reverb.kr(0.1), 0.5, 0.1);
    sig = sig * env;

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\pc, {
    var sig, env, clickEnv, filterEnv;

    env = EnvGen.kr(Env.perc(0.001, \decay.kr(0.1), \amp.kr(0.5)), doneAction: 2);
    filterEnv = EnvGen.kr(Env.perc(0.001, 0.05, 1));
    clickEnv = EnvGen.kr(Env.perc(0.001, 0.01, \click.kr(1)));

    sig = BPF.ar(WhiteNoise.ar, \freq.kr(1750), 0.3);
    sig = sig + (Impulse.ar(0) * clickEnv); // add transient click
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
