(
// Sampling and buffers
SynthDef(\slicer, {
    var bufnum = \buf.kr(0);
    var numSlices = \slices.kr(1);
    var secondsPerBar = \bars.kr(4) / (\tempo.kr);
    var secondsPerFrame = BufFrames.kr(bufnum) / BufSampleRate.kr(bufnum);
    var framesPerSlice = BufFrames.kr(bufnum) / numSlices;
    var secondsPerSlice = secondsPerBar / numSlices;
    var atk = secondsPerSlice * \begin.kr(0);
    var rel = secondsPerSlice * \end.kr(1);
    var env = Env([0, 1, 1, 0], [atk, rel, 0], curve: \curve.kr(1));
    var sig = PlayBuf.ar(
        numChannels: 2, 
        bufnum: bufnum,
        rate: secondsPerFrame / secondsPerBar,
        doneAction: Done.freeSelf,
        startPos: framesPerSlice * \slice.kr(0));

    sig = Select.ar(BufChannels.kr(bufnum) - 1, [sig!2, sig]);
    sig = sig * env.ar(Done.freeSelf);
    sig = sig * \amp.kr(1);

    Out.ar(\i_out.kr(0), sig);
}).add;

SynthDef(\oneshot, {
    var bufnum = \buf.kr;
    var bufdur = BufDur.kr(bufnum);
    var atk = bufdur * \begin.kr(0);
    var rel = bufdur * \end.kr(1);
    var env = Env([0, 1, 1, 0], [atk, rel, 0], curve: \curve.kr(1));
    var channels = BufChannels.kr(bufnum);
    var sig = PlayBuf.ar(
        numChannels: 2,
        bufnum: bufnum,
        rate: \rate.kr(1) * BufRateScale.kr(bufnum), 
        doneAction: Done.freeSelf,
        startPos: 0);

    sig = Select.ar(BufChannels.kr(bufnum) - 1, [sig!2, sig]);
    sig = sig * env.ar(Done.freeSelf);
    sig = sig * \amp.kr(1);

    Out.ar(\i_out.kr(0), sig);
}).add;

// Pulsar synthesis
SynthDef(\pulsar, {
    var fund = \freq.kr(220);
    var formant = \formant.kr(2);
    var bufnum = \buf.kr(0);
    var formantfreq = max(formant, 1) * fund;
    var env = Env(
        [0, 1, 1, 0],
        [\atk.kr(0), \sust.kr(inf), \rel.kr(0)], 
        curve: \curve.kr([0,0,0]));
    var sig = PlayBuf.ar(
        2,
        bufnum,
        BufRateScale.kr(bufnum) * BufDur.kr(bufnum) * formantfreq,
        Impulse.ar(fund)); 

    sig = sig * \window.ar(1.0);
    sig = sig * LFPulse.ar(fund, width: formant.reciprocal);
    sig = sig * env.ar(Done.freeSelf);
    sig = sig * \amp.kr(1);
    sig = Fold.ar(sig, -1, 1);

    Out.ar(\i_out.kr(0), sig);
}).add;
)

