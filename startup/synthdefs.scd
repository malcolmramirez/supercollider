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
        rate: \rate.kr(1), 
        doneAction: Done.freeSelf,
        startPos: 0
    );
    sig = Select.ar(channels - 1, [sig, sig!2]);

    sig = sig * env;
    sig = sig * \amp.kr(1);

    Out.ar(\i_out.kr(0), sig);
}).add;
)
