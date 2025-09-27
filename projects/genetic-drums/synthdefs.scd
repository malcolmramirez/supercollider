(
SynthDef(\kd, {
    var sig, env, filterEnv, pitchEnv, dist;

    pitchEnv = Env([\freq.kr(80) * \punch.kr(1.5), \freq.kr(80)], [0.1], \exp).kr;
    env = Env.perc(0.01, \decay.kr(0.4), \amp.kr(0.75)).kr(Done.freeSelf);
    filterEnv = Env.perc(0.01, \filterDecay.kr(0.15)).kr;

    sig = SinOsc.ar(pitchEnv) + (SinOsc.ar(pitchEnv * 1/sqrt(5)) * 0.5);
    sig = sig + SinOsc.ar(pitchEnv * 0.5, 0, 0.3);
    sig = (sig * Rand(1.0, 1.5)).tanh;
    sig = LPF.ar(sig, \filterSweep.kr(100) + (filterEnv * \filterSweep.kr(100) * 2));
    sig = sig * env;

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\hh, {
    var sig, env;

    env = Env.perc(0.001, \decay.kr(0.03), \amp.kr(0.4)).kr(Done.freeSelf);

    sig = Mix.ar([WhiteNoise.ar, PinkNoise.ar, BrownNoise.ar]) * 1/12;
    sig = sig + FreeVerb.ar(sig, \reverb.kr(0.1), 0.5, 0.1);
    sig = sig * env;

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\pc, {
    var sig, env, clickEnv, filterEnv;

    env = Env.perc(0.001, \decay.kr(0.1), \amp.kr(0.5)).kr(Done.freeSelf);
    filterEnv = Env.perc(0.001, 0.05).kr;

    sig = BPF.ar(WhiteNoise.ar, \freq.kr(1750), 0.3);
    sig = LPF.ar(sig, \filterSweep.kr(5000) + (filterEnv * \filterSweep.kr(5000)));
    sig = (sig * 2).softclip * 0.7;
    sig = sig + FreeVerb.ar(sig, \reverb.kr(0.15), 0.6, 0.2);
    sig = sig * env;

    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\pad, {
    var sig, env, trig;

    env = Env.asr(
        \atk.kr(0.5),
        \suslev.kr(1),
        \rel.kr(10),
        \sine);
    trig = Env.perc(0, \sustime.kr(2)).kr;
    env = env.ar(Done.freeSelf, trig);

    sig = Saw.ar(\freq.kr(440) * ({ LFNoise2.ar(\lfo.kr(8), mul: 0.0025, add: 1) } ! 4));
    sig = LPF.ar(sig, \lpff.kr(500) * (1 + env));
    sig = Mix.ar([
        sig,
        Formant.ar(
            \freq.kr(440),
            ((BrownNoise.kr(add: 1) / 4) + SinOsc.kr(1, add: 1)) * \freq.kr(440),
            LFNoise2.kr(0.1, mul: 1200).abs,
            mul: \formantAmt.kr(0.05))
    ]);
    sig = LeakDC.ar(sig);
    sig = PitchShift.ar(
        sig,
        0.02,
        (1 + (LFNoise2.kr(1, mul: 0.2).abs / 6)),
        0.001,
        0);
    sig = env * sig * \amp.kr(0.3);

    Out.ar(\out.kr(0), sig);
}).add;

)

