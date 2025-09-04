(
SynthDef(\pad, {
    var sig, env, trig;

    env = Env.asr(
        \atk.kr(0.5),
        \suslev.kr(1),
        \rel.kr(0.1),
        \sine);
    trig = Env.perc(0, \sustime.kr(2)).kr;
    //trig = 1;
    env = env.ar(Done.freeSelf, trig);

    sig = Saw.ar(\freq.kr(440) * ({ LFNoise2.ar(\lfo.kr(8), mul: \pitchwob.kr(0.0025), add: 1) } ! 4));
    sig = LPF.ar(sig, \lpff.kr(500) * (1 + env));
    sig = Mix.ar([
        sig,
        Formant.ar(
            \freq.kr(440) / 2,
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
    sig = env * sig * \amp.kr(0.2);

    Out.ar(\out.kr(0), sig);
}).add;

SynthDef(\playbuf, {
    var sig = PlayBuf.ar(
        numChannels: 2,
        startPos: \start.kr(0),
        bufnum: \buffer.kr,
        rate: \rate.kr(1)) * \amp.kr(1);
    /*sig = Mix.ar([
        sig * \dry.kr(0.5),
        FreqShift.ar(sig, \freq.kr(440)) * (1 - \dry.kr(0.5))]);*/
    Out.ar(\out.kr(0), sig ! 2);
}).add;

SynthDef(\drumfx, {
    var sig, trig, env;

    sig = In.ar(\in.kr(-1), 2);

    sig = Mix.ar([
        sig * \dry.kr(0.5),
        HPF.ar(sig, (SinOsc.kr(0.5) * 0.2 + 1) * \hpf.kr(1500)) * (1 - \dry.kr(0.5))
    ]);
    sig = sig * \amp.kr(1);
    Out.ar(\out.kr(0), sig);
}).add;

SynthDef(\sub, {
    var sig, trig, env, fmod;

    fmod = (SinOsc.kr(0.05) * 0.005) + 1;
    sig = SinOsc.ar(\freq.kr(55) * fmod);

    trig = Env.perc(0, \sustime.kr(1)).kr;
    env = Env.asr(
        \atk.kr(0.15),
        \suslev.kr(0.75),
        \rel.kr(1),
        \sine);
    env = env.ar(Done.freeSelf, trig);

    sig = LPF.ar(sig, \freq.kr(55) / 1.35);

    sig = sig ! 2 * env * \amp.kr(1);

    Out.ar(\out.kr(0), sig);
}).add;

)