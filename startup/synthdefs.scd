(
// Sampling and buffers
SynthDef(\slicer, {
    var bufnum = \buf.kr;
    var numSlices = \slices.kr(1);

    var secondsPerBar = \barlen.kr(4) / \tempo.kr;

    var secondsPerFrame = BufFrames.kr(bufnum) / BufSampleRate.kr(bufnum);
    var framesPerSlice = BufFrames.kr(bufnum) / numSlices;
    var secondsPerSlice = secondsPerBar / numSlices;

    var atk = secondsPerSlice * \begin.kr(0);
    var rel = secondsPerSlice * \end.kr(1);
    var env = Env.perc(atk, rel, curve: \curve.kr(1000))
        .ar(Done.freeSelf);

    var channels = BufChannels.kr(bufnum);

    var sig = PlayBuf.ar(
        numChannels: 2, 
        bufnum: bufnum,
        rate: secondsPerFrame / secondsPerBar,
        doneAction: Done.freeSelf,
        startPos: framesPerSlice * \slice.kr(0)
    );
    sig = Select.ar(channels - 1, [sig, sig!2]);

    sig = sig * env;
    sig = sig * \amp.kr(1);

    Out.ar(\i_out.kr(0), sig);
}).add;

SynthDef(\oneshot, {
    var bufnum = \buf.kr;
    var bufdur = BufDur.kr(bufnum);

    var atk = bufdur * \begin.kr(0);
    var rel = bufdur * \end.kr(1);
    var env = Env.perc(atk, rel, curve: \curve.kr(1000))
        .ar(Done.freeSelf);

    var channels = BufChannels.kr(bufnum);

    var sig = PlayBuf.ar(
        numChannels: 2,
        bufnum: bufnum,
        rate: \rate.kr(1) * BufRateScale.kr(bufnum), 
        doneAction: Done.freeSelf,
        startPos: 0
    );
    sig = Select.ar(channels - 1, [sig, sig!2]);

    sig = sig * env;
    sig = sig * \amp.kr(1);

    Out.ar(\i_out.kr(0), sig);
}).add;
)

(
// Pulsar synthesis
SynthDef(\pulsar, {
    var pulsaret, pulsaretEnv, 
        sig, env, 
        pf, df, bufnum, 
        trig;

    pf = \freq.kr(220);
    trig = Impulse.ar(pf);
    df = pf * \dratio.kr(1/2).reciprocal;

    pulsaretEnv = Env(
        [0, 1, 1, 0], 
        [\patk.kr(0), \psust.kr(1), \prel.kr(0)].normalizeSum * 1/df,
        curve: \pcurve.kr(0)).ar(gate: trig);

    bufnum = \buf.kr;

    pulsaret = PlayBuf.ar(
        1,
        bufnum,
        BufRateScale.kr(bufnum) * BufDur.kr(bufnum) * df * \rate.kr(1),
        trig);

    sig = pulsaret * pulsaretEnv;
    sig = sig * LFPulse.ar(pf);

    env = Env(
        [0, 1, 1, 0], 
        [\atk.kr(0), \sust.kr(10), \rel.kr(0)],
        curve: \pcurve.kr(0)).ar(Done.freeSelf);

    sig = sig * env;
    sig = sig * \amp.kr(1);
    sig = Limiter.ar(sig);
    sig = sig ! 2;

    Out.ar(\i_out.kr(0), sig);
}).add;
)

